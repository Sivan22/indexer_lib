#!/bin/bash
echo "Building IndexerLib C# Wrapper..."

# First, build the original IndexerLib if not already built
if [ ! -f "../Indexer/IndexerLib/bin/Release/IndexerLib.dll" ]; then
    echo "Building original IndexerLib..."
    cd ../Indexer
    dotnet build IndexerLib.sln -c Release
    cd ../indexer_lib
fi

# Build the wrapper library
cd csharp_lib

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    dotnet publish -c Release -r linux-x64 --self-contained
    echo ""
    echo "Build complete!"
    echo "Library location: csharp_lib/bin/Release/net8.0/linux-x64/publish/IndexerLibWrapper.so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    dotnet publish -c Release -r osx-x64 --self-contained
    echo ""
    echo "Build complete!"
    echo "Library location: csharp_lib/bin/Release/net8.0/osx-x64/publish/IndexerLibWrapper.dylib"
else
    echo "Unsupported platform"
    exit 1
fi
