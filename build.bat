@echo off
echo Building IndexerLib C# Wrapper...

REM First, build the original IndexerLib if not already built
if not exist "..\Indexer\IndexerLib\bin\Release\IndexerLib.dll" (
    echo Building original IndexerLib...
    cd ..\Indexer
    dotnet build IndexerLib.sln -c Release
    cd ..\indexer_lib
)

REM Build the wrapper library
cd csharp_lib
dotnet publish -c Release -r win-x64 --self-contained

echo.
echo Build complete!
echo DLL location: csharp_lib\bin\Release\net8.0\win-x64\publish\IndexerLibWrapper.dll
