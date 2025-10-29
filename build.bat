@echo off
echo Building IndexerLib C# Wrapper...

REM Build the wrapper library (includes IndexerLib sources)
cd csharp_lib
dotnet publish -c Release -r win-x64 --self-contained

echo.
echo Build complete!
echo DLL location: csharp_lib\bin\Release\net8.0\win-x64\publish\IndexerLibWrapper.dll
