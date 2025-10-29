﻿using IndexerLib.Helpers;
using IndexerLib.Tokens;
using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

namespace IndexerLib.Index
{
    public class WAL : IDisposable
    {
        private readonly ConcurrentDictionary<string, MemoryStream> _streams;
        private readonly long _memoryCapInBytes;
        private long currentMemoryUsage = 0;
        private short mergeCountdown = 25;
        public readonly System.Timers.Timer ProgressTimer;

        // memory usage 500 mb default
        public WAL(int memoryCapMB = 500)
        {
            var totalMemory = GetAvailableMemoryMB();
            // Limit cap to at most 60% of available memory
            var safeCap = (int)Math.Min(memoryCapMB, totalMemory * 0.6);
            safeCap = Math.Max(5, safeCap / 15); // your scaling rule
            _memoryCapInBytes = safeCap * 1024L * 1024L;

            _streams = new ConcurrentDictionary<string, MemoryStream>();
            ProgressTimer = new System.Timers.Timer(2000);
            ProgressTimer.Start();
        }

        static double GetAvailableMemoryMB()
        {
            using (var pc = new PerformanceCounter("Memory", "Available MBytes"))
                return pc.NextValue();
        }

        public void Log(string key, Token token)
        {
            if (Interlocked.Read(ref currentMemoryUsage) >= _memoryCapInBytes)
                Flush();

            byte[] serialized = Serializer.SerializeToken(token);

            if (!_streams.ContainsKey(key))
                Interlocked.Add(ref currentMemoryUsage, Encoding.UTF8.GetByteCount(key));

            var stream = _streams.GetOrAdd(key, _ => new MemoryStream());
            lock (stream) // ensure thread-safety for the same key
            {
                stream.Write(serialized, 0, serialized.Length);
                Interlocked.Add(ref currentMemoryUsage, serialized.Length);
            }
        }

        public void Flush()
        {
            if (_streams.IsEmpty)
                return;

            Console.WriteLine("Flushing...");
            if (ProgressTimer != null)
                ProgressTimer.Stop();

            using (var spinner = new ConsoleSpinner())
            using (var writer = new IndexWriter())
            {
                foreach (var kvp in _streams)
                {
                    writer.Put(kvp.Key, kvp.Value);
                    kvp.Value.Dispose();
                }
            }

            _streams.Clear();

            GC.Collect();
            GC.WaitForPendingFinalizers();
            currentMemoryUsage = 0;
            Console.WriteLine("Flush complete");
            if (ProgressTimer != null)
                ProgressTimer.Start();

            mergeCountdown--;
            if (mergeCountdown == 0)
            {
                IndexMerger.Merge();
                mergeCountdown = 25;
            }
        }

        public void Dispose()
        {
            Flush();

            ProgressTimer?.Stop();
            ProgressTimer?.Dispose();

            IndexMerger.Merge();
            WordsStore.SortWordsByIndex();
        }
    }
}
