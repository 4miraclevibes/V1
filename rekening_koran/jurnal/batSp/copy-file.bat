:: net use \\10.54.20.8\sap D8w_abera- /USER:greenfields\sapdocs
:: %SystemRoot%\explorer.exe "\\10.54.20.8\sap\shd\specialprice"
:: --------------

@echo off

net use \\10.54.20.8\sap D8w_abera- /USER:greenfields\sapdocs

xcopy /Y C:\SPECIALPRICE\*.csv \\10.54.20.8\sap\shd\specialprice

if errorlevel 0 goto success
if errorlevel 2 goto failed
if errorlevel 4 goto failed 

:success
move /Y C:\SPECIALPRICE\*.csv C:\SPECIALPRICE\uploadsuccess\
goto exit 

:failed
move /Y C:\SPECIALPRICE\*.csv C:\SPECIALPRICE\uploadfailed\

:exit 
net use