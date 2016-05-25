powershell -file ./GetClrDbg.ps1 -Version latest -RuntimeID ubuntu.14.04-x64 -InstallPath .\clrdbg 
docker build -t sequentia/dotnet-watch-core-rc2 .
