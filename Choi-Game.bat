@echo off
cd /d "%~dp0"
title Co Vua Doraemon TV
echo.
echo ============================================
echo   Co Vua Doraemon TV
echo ============================================
echo.
echo  [1] Mo game (trinh duyet) - KHUYEN NGHI
echo  [2] Mo + server local (PWA / offline tot hon)
echo  [3] Huong dan build APK GitHub
echo.
choice /C 123 /N /M "Chon: "
if errorlevel 3 goto help
if errorlevel 2 goto server
if errorlevel 1 goto browser

:browser
start "" "%~dp0web\index.html"
exit /b 0

:server
echo.
echo Dang chay server tai http://127.0.0.1:8765
echo Bam Ctrl+C de tat server.
echo.
start "" http://127.0.0.1:8765/index.html
where py >nul 2>&1 && py -m http.server 8765 --directory web && exit /b 0
where python >nul 2>&1 && python -m http.server 8765 --directory web && exit /b 0
where node >nul 2>&1 && npx --yes serve web -l 8765 && exit /b 0
echo Khong co Python/Node. Mo truc tiep file...
start "" "%~dp0web\index.html"
exit /b 0

:help
echo.
echo === Build APK (may nha, co GitHub) ===
echo 1. Push toan bo project len GitHub
echo 2. Actions -^> "Build Android APK (WebView)" -^> Run workflow
echo 3. Tai artifact doraemon-chess-tv-apk
echo 4. Cai APK len Xiaomi TV (USB / adb install)
echo.
echo Chi tiet: docs\GITHUB_BUILD.md va docs\WEB_TV.md
echo.
pause
exit /b 0
