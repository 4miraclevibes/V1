@echo off
REM =====================================================
REM copy-rekeningkoran.bat
REM Copy CSV dari C:\REKENINGKORAN ke network share
REM Dipanggil oleh SP_EXPORT_JURNAL_CSV_FILE
REM =====================================================

REM Map network drive (sesuaikan path & credential jika perlu)
net use \\10.54.20.8\sap D8w_abera- /USER:greenfields\sapdocs

REM Copy semua CSV ke folder rekeningkoran di share
xcopy /Y C:\REKENINGKORAN\*.csv \\10.54.20.8\sap\shd\rekeningkoran

if errorlevel 0 goto success
if errorlevel 2 goto failed
if errorlevel 4 goto failed

:success
move /Y C:\REKENINGKORAN\*.csv C:\REKENINGKORAN\uploadsuccess\
goto exit

:failed
move /Y C:\REKENINGKORAN\*.csv C:\REKENINGKORAN\uploadfailed\

:exit
net use
