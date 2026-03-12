@echo off
REM =====================================================
REM copy-rekeningkoran.bat
REM Copy CSV dari C:\REKENINGKORAN ke network share
REM Dipanggil oleh SP_EXPORT_JURNAL_CSV_FILE
REM =====================================================

REM Map network drive (sesuaikan path & credential jika perlu)
net use \\10.54.20.8\sap D8w_abera- /USER:greenfields\sapdocs

REM Copy semua CSV ke folder rekeningkoran di share (tanpa move ke uploadsuccess/uploadfailed)
xcopy /Y C:\REKENINGKORAN\*.csv \\10.54.20.8\sap\prd\rekeningkoran

:exit
net use
