@echo off
REM =====================================================
REM copy-jurnal-terbaru-ke-hris.bat
REM Copy HANYA file CSV terbaru dari C:\REKENINGKORAN
REM ke \\10.54.20.8\sap\prd\hris\sap_in\zaffie001\input
REM =====================================================

REM Map network drive
net use \\10.54.20.8\sap D8w_abera- /USER:greenfields\sapdocs

REM Ambil file CSV terbaru (cari di REKENINGKORAN + subfolder uploadsuccess/uploadfailed)
REM Karena copy-rekeningkoran sudah move file, cari pakai /S
set "NEWEST="
for /f "delims=" %%f in ('dir /B /O-D /S C:\REKENINGKORAN\*.csv 2^>nul') do (
    set "NEWEST=%%f"
    goto :copy_newest
)

:copy_newest
if not defined NEWEST (
    echo Tidak ada file CSV di C:\REKENINGKORAN
    goto exit
)

echo Copy file terbaru: %NEWEST%
copy /Y "%NEWEST%" "\\10.54.20.8\sap\prd\hris\sap_in\zaffie001\input\"

if errorlevel 0 (
    echo Berhasil copy ke \\10.54.20.8\sap\prd\hris\sap_in\zaffie001\input
) else (
    echo Gagal copy file
)

:exit
net use
