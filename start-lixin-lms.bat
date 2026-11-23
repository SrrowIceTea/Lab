@echo off
setlocal

echo.
echo ============================================================
echo   Lixin LMS - Start All Services (NO Docker)
echo ============================================================
echo.
echo   Services to start:
echo     MySQL              3306  (must be running already)
echo     user-service       8083
echo     experiment-module  8084
echo     image-service      8086
echo     ai-agent-service   8010
echo     frontend           5173
echo.
echo   No Docker container will be started.
echo.

set "ROOT=%~dp0"
set "BACKEND=%ROOT%seclab-backend"
set "FRONTEND=%ROOT%SecLab-FrontEnd-2"
set "GRADLE_813=C:\Users\m1866\.gradle\wrapper\dists\gradle-8.13-bin\bynj8867joaln2pdnozgpow3q\gradle-8.13\bin\gradle.bat"

netstat -ano | findstr /R /C:":3306 .*LISTENING" >nul
if errorlevel 1 (
    echo [WARN] MySQL is not listening on 3306. Start MySQL first.
    echo        This script will NOT start Docker as a substitute.
    pause
    exit /b 1
)
echo [OK] MySQL 3306 is running

netstat -ano | findstr /R /C:":8083 .*LISTENING" >nul
if errorlevel 1 (
    echo [START] user-service 8083
    start "LMS-user-service-8083" /D "%BACKEND%\user-service" cmd /k gradlew.bat bootRun --no-daemon
) else (
    echo [SKIP] user-service 8083 already in use
)

netstat -ano | findstr /R /C:":8084 .*LISTENING" >nul
if errorlevel 1 (
    echo [START] experiment-module-service 8084
    start "LMS-experiment-8084" /D "%BACKEND%\experiment-module-service" cmd /k gradlew.bat bootRun --no-daemon
) else (
    echo [SKIP] experiment-module 8084 already in use
)

if exist "%GRADLE_813%" (
    netstat -ano | findstr /R /C:":8086 .*LISTENING" >nul
    if errorlevel 1 (
        echo [START] image-service 8086
        start "LMS-image-service-8086" /D "%BACKEND%\image-service" cmd /k "%GRADLE_813%" bootRun --no-daemon
    ) else (
        echo [SKIP] image-service 8086 already in use
    )
) else (
    echo [SKIP] image-service 8086 - local Gradle 8.13 not found
)

netstat -ano | findstr /R /C:":8010 .*LISTENING" >nul
if errorlevel 1 (
    echo [START] ai-agent-service 8010
    start "LMS-ai-agent-8010" /D "%BACKEND%\ai-agent-service" cmd /k "set PYTHONIOENCODING=utf-8&& python main.py"
) else (
    echo [SKIP] ai-agent 8010 already in use
)

netstat -ano | findstr /R /C:":5173 .*LISTENING" >nul
if errorlevel 1 (
    echo [START] frontend 5173
    start "LMS-frontend-5173" /D "%FRONTEND%" cmd /k npm run dev
) else (
    echo [SKIP] frontend 5173 already in use
)

echo.
echo ============================================================
echo   Done. Each service runs in its own window.
echo   Frontend: http://127.0.0.1:5173
echo   Teacher: admin / 123456
echo   Student: 123456 / 123456
echo   To stop a service, just close its window.
echo ============================================================
echo.
pause
