@echo off

net use \\sapfs01.greenfieldsdairy.com\sap\prd\hris\sap_in\zaffie001\input D8w_abera- /USER:greenfields\sapdocs

xcopy /Y C:\HRJOURNAL\*.csv \\sapfs01.greenfieldsdairy.com\sap\prd\hris\sap_in\zaffie001\input

if errorlevel 0 goto success
if errorlevel 2 goto failed
if errorlevel 4 goto failed 

:success
move /Y C:\HRJOURNAL\*.csv C:\HRJOURNAL\uploadsuccess\
goto exit 

:failed
move /Y C:\HRJOURNAL\*.csv C:\HRJOURNAL\uploadfailed\

:exit 
net use