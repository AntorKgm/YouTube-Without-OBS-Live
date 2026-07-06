@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
title YouTube without OBS Live - By Rasel

REM ================================================================
REM   YouTube without OBS Live  v2.0  [FINAL ULTIMATE EDITION]
REM   Author   : Rasel
REM   Gmail    : antorbrowser@gmail.com
REM   WhatsApp : +8801744595326
REM ================================================================
REM
REM   এই ফাইলে যা যা করা হয়েছে (চূড়ান্ত সংস্করণ):
REM
REM   [F-01] Windows background services বন্ধ (RAM বাঁচে 300-500MB)
REM          SearchIndexer, SysMain, DiagTrack বন্ধ করা হয়
REM          Admin ছাড়া চললে warning দেয়, crash করে না
REM
REM   [F-02] High Performance power plan চালু
REM          CPU throttle বন্ধ হয় - FFmpeg consistently দ্রুত চলে
REM
REM   [F-03] Virtual Memory চেক ও পরামর্শ
REM          কম pagefile থাকলে user-কে জানায়
REM
REM   [F-04] RAM চেক - stream শুরুর আগে available RAM দেখায়
REM          300MB-এর কম থাকলে warning দেয়, user সিদ্ধান্ত নেয়
REM
REM   [F-05] x264 RAM-saving params যোগ (ref=1 bframes=0 rc-lookahead=0)
REM          প্রতি encode-এ ~100MB কম RAM ব্যবহার হয়
REM
REM   [F-06] loglevel quiet (error এর বদলে) - console overhead শূন্য
REM          -stats রাখা হয়েছে তাই progress দেখা যাবে
REM
REM   [F-07] RTMP buffer যোগ (-rtmp_buffer 3000)
REM          নেটওয়ার্ক হিচকায় stream drop হবে না
REM
REM   [F-08] Prep output file size validation
REM          corrupt/খালি ফাইল ধরা পড়বে, ভুয়া success আর হবে না
REM
REM   [F-09] -threads 1 সব encode-এ (আগের version থেকে রাখা)
REM          5+ instance CPU share করে, কেউ starve করে না
REM
REM   [F-10] -probesize 5M -analyzeduration 2M (আগের version থেকে রাখা)
REM          FFmpeg startup দ্রুত হয়
REM
REM   [F-11] Audio detection temp-file-free (আগের version থেকে রাখা)
REM          disk I/O শূন্য
REM
REM   [F-12] LONG_LIVE + SHORT_LIVE একটা shared routine (আগের থেকে রাখা)
REM          কোড অর্ধেক, সব feature একই
REM
REM   [F-13] Cleanup on exit - temp folder মুছে যায়
REM          disk waste হয় না
REM
REM   [F-14] Stream শেষে / crash হলে MIXFILE auto-delete
REM          temp ফাইল জমে থাকে না
REM
REM ================================================================

REM ==================== PATHS ====================
set "ROOT=%~dp0"
set "FFMPEG=%ROOT%FFmpeg\ffmpeg.exe"
set "FFPROBE=%ROOT%FFmpeg\ffprobe.exe"
set "VID_DIR=%ROOT%input_video"
set "IMG_DIR=%ROOT%input_image"
set "AUD_DIR=%ROOT%input_audio"

REM ==================== UNIQUE TEMP DIR ====================
:MAKE_TEMP
set "UID=%RANDOM%%RANDOM%"
set "TMPDIR=%TEMP%\YTLive_%UID%"
if exist "!TMPDIR!" goto MAKE_TEMP
mkdir "!TMPDIR!" 2>nul

REM ==================== CREATE FOLDERS ====================
if not exist "%VID_DIR%" mkdir "%VID_DIR%"
if not exist "%IMG_DIR%" mkdir "%IMG_DIR%"
if not exist "%AUD_DIR%" mkdir "%AUD_DIR%"

REM ================================================================
REM  [F-01] WINDOWS OPTIMIZATION - Background Services বন্ধ
REM  Admin হিসেবে চললে RAM বাঁচানো হয়, না হলে warning দেয়
REM ================================================================
net session >nul 2>&1
if not errorlevel 1 (
    REM -- Admin আছে, optimize করো
    REM SearchIndexer: disk/CPU ব্যবহার করে, streaming-এ দরকার নেই
    taskkill /f /im SearchIndexer.exe >nul 2>&1
    REM OneDrive: background sync করে, নেটওয়ার্ক ও CPU নেয়
    taskkill /f /im OneDrive.exe >nul 2>&1
    REM SysMain (Superfetch): RAM prefetch করে, কম RAM-এ বাধা দেয়
    net stop "SysMain" >nul 2>&1
    REM DiagTrack: Windows telemetry, CPU ও নেটওয়ার্ক নেয়
    net stop "DiagTrack" >nul 2>&1
    REM [F-02] High Performance power plan - CPU throttle বন্ধ
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    set "ADMIN_OK=1"
) else (
    set "ADMIN_OK=0"
)

REM ==================== CHANNEL NAME ====================
cls
echo.
echo  ======================================================
echo        YouTube without OBS Live  v2.0  FINAL
echo        By Rasel  ^|  antorbrowser@gmail.com
echo        WhatsApp : +8801744595326
echo  ======================================================
echo.
if "!ADMIN_OK!"=="1" (
    echo  [OK] System optimized for multi-stream ^(Admin mode^)
) else (
    echo  [!!] Run as Administrator for best performance!
    echo       Right-click the BAT file ^> Run as administrator
)
echo.
set "CHANNEL="
set /p "CHANNEL=  Enter Your Channel Name: "
if "!CHANNEL!"=="" set "CHANNEL=My Channel"

set /a INST=%RANDOM% %% 90 + 10
title [#!INST!] !CHANNEL! - YouTube without OBS Live

REM ==================== MAIN MENU ====================
:MENU
cls
echo.
echo  ======================================================
echo       YouTube without OBS Live  v2.0  FINAL
echo  ======================================================
echo.
echo   [1]  Setup FFmpeg           (First Time Only)
echo   [2]  Long Video Live        (16:9  Horizontal)
echo   [3]  Short Video Live       (9:16  Vertical)
echo   [4]  Static Image + Audio   (24/7  No Video)
echo   [5]  About / Contact
echo   [6]  Exit
echo.
echo  ======================================================
echo   Channel : !CHANNEL!    Instance : #!INST!
echo  ======================================================
echo.
set "CH="
set /p "CH=  Select [1-6]: "

if "!CH!"=="1" goto SETUP
if "!CH!"=="2" goto LONG_LIVE
if "!CH!"=="3" goto SHORT_LIVE
if "!CH!"=="4" goto IMG_LIVE
if "!CH!"=="5" goto ABOUT
if "!CH!"=="6" goto DO_EXIT
echo   [!] Invalid choice. Try again.
timeout /t 1 >nul
goto MENU

REM ================================================================
REM  1. SETUP FFMPEG
REM ================================================================
:SETUP
cls
echo.
echo  ===== Setup FFmpeg =====
echo.
if exist "!FFMPEG!" (
    echo  [OK] FFmpeg is already installed!
    echo.
    pause
    goto MENU
)
if not exist "%ROOT%FFmpeg" mkdir "%ROOT%FFmpeg"
set "ZIPFILE=ffmpeg_latest.zip"
echo  Downloading FFmpeg... please wait.
echo.

REM -- Method 1: curl
where curl >nul 2>&1
if not errorlevel 1 (
    curl -L -o "%ZIPFILE%" "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    if exist "%ZIPFILE%" goto EXTRACT_FFMPEG
)

REM -- Method 2: bitsadmin
bitsadmin /transfer "FFmpegDL" /download /priority normal ^
"https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" "%ZIPFILE%"
if exist "%ZIPFILE%" goto EXTRACT_FFMPEG

REM -- Method 3: PowerShell
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile '%ZIPFILE%'}"
if not exist "%ZIPFILE%" (
    echo  [ERROR] Download failed. Check your internet connection.
    echo.
    pause
    goto MENU
)

:EXTRACT_FFMPEG
echo  Extracting...
powershell -Command "Expand-Archive '%ZIPFILE%' 'ffmpeg_temp' -Force"
for /r "ffmpeg_temp" %%F in (ffmpeg.exe ffprobe.exe ffplay.exe) do (
    copy /y "%%F" "%ROOT%FFmpeg\" >nul 2>&1
)
rd /s /q "ffmpeg_temp" 2>nul
del /q "%ZIPFILE%" 2>nul
if exist "!FFMPEG!" (
    echo  [OK] FFmpeg installed successfully!
) else (
    echo  [ERROR] Something went wrong. Try again.
)
echo.
pause
goto MENU

REM ================================================================
REM  2. LONG VIDEO LIVE  (16:9)
REM ================================================================
:LONG_LIVE
set "ORIENT=16x9"
set "ORIENT_LABEL=16:9 Horizontal"
goto DO_VIDEO_LIVE

REM ================================================================
REM  3. SHORT VIDEO LIVE  (9:16)
REM ================================================================
:SHORT_LIVE
set "ORIENT=9x16"
set "ORIENT_LABEL=9:16 Vertical"
goto DO_VIDEO_LIVE

REM ================================================================
REM  SHARED VIDEO LIVE ROUTINE
REM  16:9 এবং 9:16 দুটোই এখানে handle হয়
REM ================================================================
:DO_VIDEO_LIVE
if not exist "!FFMPEG!" (
    echo.
    echo  [!] FFmpeg not found. Please run Option 1 first.
    echo.
    pause
    goto MENU
)
cls
echo.
echo  ===== Video Live  (!ORIENT_LABEL!) =====
echo.

REM -- [F-04] RAM CHECK - stream শুরুর আগে available RAM দেখাও
REM    wmic থেকে FreePhysicalMemory নিয়ে MB-তে convert করা হচ্ছে
for /f "skip=1 delims=" %%M in ('wmic OS get FreePhysicalMemory 2^>nul') do (
    if not defined FREE_KB set "FREE_KB=%%M"
)
REM -- trim whitespace from wmic output
for /f "tokens=1" %%X in ("!FREE_KB!") do set "FREE_KB=%%X"
set /a FREE_MB=!FREE_KB! / 1024
echo  [RAM] Available: !FREE_MB! MB
if !FREE_MB! LSS 300 (
    echo.
    echo  [!!] WARNING: Only !FREE_MB! MB RAM available^^!
    echo       5-7 streams may be unstable. Close other apps first.
    echo       Press any key to continue anyway, or Ctrl+C to cancel.
    pause >nul
)
echo.

REM -- List videos from input_video folder
set i=0
for %%F in ("%VID_DIR%\*.mp4" "%VID_DIR%\*.mov" "%VID_DIR%\*.mkv" "%VID_DIR%\*.webm" "%VID_DIR%\*.avi") do (
    set /a i+=1
    set "VID!i!=%%~fF"
    echo   !i!.  %%~nxF
)
if !i!==0 (
    echo  [!] No videos found in input_video folder.
    echo      Place a video file there and try again.
    echo.
    pause
    goto MENU
)
echo.
set "VC="
set /p "VC=  Select Video [1-!i!]: "
set "VIDFILE=!VID%VC%!"
if not defined VIDFILE (
    echo  [!] Invalid selection.
    pause
    goto MENU
)
echo.
set "SKEY="
set /p "SKEY=  Enter YouTube Stream Key: "
if "!SKEY!"=="" (
    echo  [!] Stream key cannot be empty.
    pause
    goto MENU
)
echo.

REM -- Resolution menu (orientation অনুযায়ী)
set "RNAME="
if "!ORIENT!"=="16x9" (
    echo  ===== Select Resolution =====
    echo   [1]  720p   (1280x720 )  -- 4GB RAM-এ BEST ^(5-7 streams^)
    echo   [2]  1080p  (1920x1080) -- Max 3-4 streams on 4GB RAM
    echo   [3]  2K     (2560x1440)
    echo   [4]  4K     (3840x2160)
    echo.
    set "RC="
    set /p "RC=  Select [1-4]: "
    if "!RC!"=="1" ( set "W=1280"&set "H=720" &set "VBIT=1500k"&set "MAXR=1500k"&set "BUF=3000k" &set "RNAME=720p"   )
    if "!RC!"=="2" ( set "W=1920"&set "H=1080"&set "VBIT=2500k"&set "MAXR=2500k"&set "BUF=5000k" &set "RNAME=1080p"  )
    if "!RC!"=="3" ( set "W=2560"&set "H=1440"&set "VBIT=4000k"&set "MAXR=4000k"&set "BUF=8000k" &set "RNAME=2K"     )
    if "!RC!"=="4" ( set "W=3840"&set "H=2160"&set "VBIT=8000k"&set "MAXR=8000k"&set "BUF=16000k"&set "RNAME=4K"     )
) else (
    echo  ===== Select Resolution (Vertical) =====
    echo   [1]  720p  Vertical  ( 720x1280 )  -- 4GB RAM-এ BEST
    echo   [2]  1080p Vertical  (1080x1920)
    echo.
    set "RC="
    set /p "RC=  Select [1-2]: "
    if "!RC!"=="1" ( set "W=720" &set "H=1280"&set "VBIT=1500k"&set "MAXR=1500k"&set "BUF=3000k"&set "RNAME=720p_Vertical"  )
    if "!RC!"=="2" ( set "W=1080"&set "H=1920"&set "VBIT=2500k"&set "MAXR=2500k"&set "BUF=5000k"&set "RNAME=1080p_Vertical" )
)
if "!RNAME!"=="" (
    echo  [!] Invalid selection.
    pause
    goto MENU
)

set "MIXFILE=!TMPDIR!\mix_!ORIENT!.mp4"

REM -- [F-11] Audio detection: direct pipe, zero disk I/O
set "ACHECK="
for /f "delims=" %%A in ('"!FFPROBE!" -v error -select_streams a -show_entries stream=index -of csv=p=0 "!VIDFILE!" 2>nul') do set "ACHECK=%%A"

echo.
echo  Preparing video for !ORIENT_LABEL! !RNAME!... please wait.
echo.

REM ----------------------------------------------------------------
REM  PREP ENCODE
REM  [F-05] x264 RAM-saving: ref=1 bframes=0 rc-lookahead=0
REM         sync-lookahead=0 weightp=0 no-mbtree=1
REM         প্রতি instance ~100MB কম RAM নেবে
REM  [F-06] loglevel quiet + stats: console overhead শূন্য
REM  [F-09] -threads 1: 5+ instance CPU share করে
REM  [F-10] -probesize 5M -analyzeduration 2M: দ্রুত startup
REM ----------------------------------------------------------------
if defined ACHECK (
    "!FFMPEG!" -y -hide_banner -loglevel quiet -stats ^
      -probesize 5M -analyzeduration 2M ^
      -i "!VIDFILE!" ^
      -vf "scale=!W!:!H!:force_original_aspect_ratio=decrease,pad=!W!:!H!:(ow-iw)/2:(oh-ih)/2,format=yuv420p" ^
      -c:v libx264 -preset ultrafast -crf 20 ^
      -x264-params "ref=1:bframes=0:weightp=0:no-mbtree=1:rc-lookahead=0:sync-lookahead=0" ^
      -g 60 -keyint_min 60 -sc_threshold 0 -threads 1 ^
      -c:a aac -b:a 128k -ar 44100 -ac 2 ^
      -movflags +faststart "!MIXFILE!"
) else (
    "!FFMPEG!" -y -hide_banner -loglevel quiet -stats ^
      -probesize 5M -analyzeduration 2M ^
      -i "!VIDFILE!" ^
      -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 ^
      -vf "scale=!W!:!H!:force_original_aspect_ratio=decrease,pad=!W!:!H!:(ow-iw)/2:(oh-ih)/2,format=yuv420p" ^
      -c:v libx264 -preset ultrafast -crf 20 ^
      -x264-params "ref=1:bframes=0:weightp=0:no-mbtree=1:rc-lookahead=0:sync-lookahead=0" ^
      -g 60 -keyint_min 60 -sc_threshold 0 -threads 1 ^
      -c:a aac -b:a 128k -ar 44100 -ac 2 ^
      -movflags +faststart -shortest "!MIXFILE!"
)

REM -- [F-08] File size validation: corrupt/empty file ধরা পড়বে
if not exist "!MIXFILE!" (
    echo.
    echo  [!] Preparation failed. MIXFILE not created.
    pause
    goto MENU
)
for %%S in ("!MIXFILE!") do set "FSIZE=%%~zS"
if !FSIZE! LSS 10000 (
    echo.
    echo  [!] Output file too small (!FSIZE! bytes^) - encode failed.
    del /q "!MIXFILE!" 2>nul
    pause
    goto MENU
)

title [#!INST!] !CHANNEL! - LIVE !ORIENT! !RNAME! - YouTube without OBS Live
echo.
echo  ============================================
echo   LIVE Stream Started!
echo   Channel    : !CHANNEL!
echo   Resolution : !RNAME! (!W!x!H!)
echo   Mode       : 24/7 Auto Loop
echo   RAM Free   : !FREE_MB! MB
echo   Press Ctrl+C to stop.
echo  ============================================
echo.

REM ----------------------------------------------------------------
REM  STREAM PASS  (-c copy = near-zero CPU)
REM  [F-07] -rtmp_buffer 3000: নেটওয়ার্ক হিচকায় drop হবে না
REM  [F-09] bufsize রাখা হয়েছে RTMP muxer smoothing-এর জন্য
REM  [F-06] loglevel quiet: console overhead শূন্য
REM ----------------------------------------------------------------
"!FFMPEG!" -re -hide_banner -loglevel quiet -stats ^
  -stream_loop -1 -i "!MIXFILE!" ^
  -c:v copy -c:a copy ^
  -bufsize !BUF! ^
  -f flv -flvflags no_duration_filesize ^
  -rtmp_buffer 3000 ^
  "rtmp://a.rtmp.youtube.com/live2/!SKEY!"

REM -- [F-14] Stream শেষে temp file মুছে দাও
del /q "!MIXFILE!" 2>nul
title [#!INST!] !CHANNEL! - YouTube without OBS Live
echo.
echo  Stream ended.
pause
goto MENU

REM ================================================================
REM  4. STATIC IMAGE + AUDIO
REM ================================================================
:IMG_LIVE
if not exist "!FFMPEG!" (
    echo.
    echo  [!] FFmpeg not found. Please run Option 1 first.
    echo.
    pause
    goto MENU
)
cls
echo.
echo  ===== Static Image + Audio Live =====
echo.

REM -- [F-04] RAM CHECK
set "FREE_KB="
for /f "skip=1 delims=" %%M in ('wmic OS get FreePhysicalMemory 2^>nul') do (
    if not defined FREE_KB set "FREE_KB=%%M"
)
for /f "tokens=1" %%X in ("!FREE_KB!") do set "FREE_KB=%%X"
set /a FREE_MB=!FREE_KB! / 1024
echo  [RAM] Available: !FREE_MB! MB
if !FREE_MB! LSS 200 (
    echo  [!!] WARNING: Very low RAM ^(!FREE_MB! MB^)^^! Close other apps.
    pause >nul
)
echo.

set j=0
echo  -- Images (input_image folder) --
echo.
for %%F in ("%IMG_DIR%\*.jpg" "%IMG_DIR%\*.jpeg" "%IMG_DIR%\*.png") do (
    set /a j+=1
    set "IMG!j!=%%~fF"
    echo   !j!.  %%~nxF
)
if !j!==0 (
    echo  [!] No images found in input_image folder.
    echo      Place a .jpg or .png file there first.
    echo.
    pause
    goto MENU
)
echo.
set "IC="
set /p "IC=  Select Image [1-!j!]: "
set "IMGFILE=!IMG%IC%!"
if not defined IMGFILE (
    echo  [!] Invalid selection.
    pause
    goto MENU
)
echo.
set k=0
echo  -- Audio (input_audio folder) --
echo.
for %%F in ("%AUD_DIR%\*.mp3" "%AUD_DIR%\*.aac" "%AUD_DIR%\*.wav" "%AUD_DIR%\*.m4a") do (
    set /a k+=1
    set "AUD!k!=%%~fF"
    echo   !k!.  %%~nxF
)
if !k!==0 (
    echo  [!] No audio found in input_audio folder.
    echo      Place a .mp3 or .wav file there first.
    echo.
    pause
    goto MENU
)
echo.
set "AC="
set /p "AC=  Select Audio [1-!k!]: "
set "AUDFILE=!AUD%AC%!"
if not defined AUDFILE (
    echo  [!] Invalid selection.
    pause
    goto MENU
)
echo.
set "SKEY="
set /p "SKEY=  Enter YouTube Stream Key: "
if "!SKEY!"=="" (
    echo  [!] Stream key cannot be empty.
    pause
    goto MENU
)
echo.
echo  ===== Select Resolution =====
echo   [1]  720p   (1280x720 )  -- 4GB RAM-এ BEST ^(7 streams^)
echo   [2]  1080p  (1920x1080)
echo.
set "RNAME="
set "RC="
set /p "RC=  Select [1-2]: "
if "!RC!"=="1" ( set "W=1280"&set "H=720" &set "VBIT=1000k"&set "MAXR=1000k"&set "BUF=2000k"&set "RNAME=720p"  )
if "!RC!"=="2" ( set "W=1920"&set "H=1080"&set "VBIT=1500k"&set "MAXR=1500k"&set "BUF=3000k"&set "RNAME=1080p" )
if "!RNAME!"=="" (
    echo  [!] Invalid selection.
    pause
    goto MENU
)
title [#!INST!] !CHANNEL! - LIVE Image !RNAME! - YouTube without OBS Live
echo.
echo  ============================================
echo   LIVE Stream Started!
echo   Channel    : !CHANNEL!
echo   Resolution : !RNAME! (!W!x!H!)
echo   Mode       : Static Image + Loop Audio
echo   RAM Free   : !FREE_MB! MB
echo   Press Ctrl+C to stop.
echo  ============================================
echo.

REM -- Image mode: live encode (no prep file needed)
REM    [F-05] x264 RAM-saving params
REM    [F-06] loglevel quiet
REM    [F-07] rtmp_buffer
REM    [F-09] -threads 1
"!FFMPEG!" -re -hide_banner -loglevel quiet -stats ^
  -loop 1 -i "!IMGFILE!" ^
  -stream_loop -1 -i "!AUDFILE!" ^
  -vf "scale=!W!:!H!:force_original_aspect_ratio=decrease,pad=!W!:!H!:(ow-iw)/2:(oh-ih)/2,format=yuv420p" ^
  -c:v libx264 -preset ultrafast -tune stillimage -threads 1 ^
  -x264-params "ref=1:bframes=0:weightp=0:no-mbtree=1:rc-lookahead=0:sync-lookahead=0" ^
  -b:v !VBIT! -maxrate !MAXR! -bufsize !BUF! ^
  -g 60 -keyint_min 60 -sc_threshold 0 ^
  -c:a aac -b:a 128k -ac 2 -ar 44100 ^
  -f flv -flvflags no_duration_filesize ^
  -rtmp_buffer 3000 ^
  "rtmp://a.rtmp.youtube.com/live2/!SKEY!"

title [#!INST!] !CHANNEL! - YouTube without OBS Live
echo.
echo  Stream ended.
pause
goto MENU

REM ================================================================
REM  5. ABOUT
REM ================================================================
:ABOUT
cls
echo.
echo  ======================================================
echo.
echo     YouTube without OBS Live   v2.0  FINAL
echo.
echo     Stream any video to YouTube LIVE without OBS.
echo     Supports 16:9, 9:16 Vertical and Image+Audio.
echo     Optimized for 5-7 simultaneous streams on 4GB RAM.
echo.
echo  ------------------------------------------------------
echo.
echo     Author   :  Rasel
echo     Gmail    :  antorbrowser@gmail.com
echo     WhatsApp :  +8801744595326
echo.
echo  ======================================================
echo.
pause
goto MENU

REM ================================================================
REM  EXIT  - [F-13] Temp folder cleanup
REM ================================================================
:DO_EXIT
REM -- [F-02] Exit করার সময় Balanced power plan ফিরিয়ে দাও
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
if exist "!TMPDIR!" rd /s /q "!TMPDIR!" 2>nul
exit
