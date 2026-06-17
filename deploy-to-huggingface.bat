@echo off
REM ============================================================
REM  Script de déploiement Livrago → HuggingFace Spaces
REM  Prérequis : git installé + compte HuggingFace
REM  Usage: deploy-to-huggingface.bat
REM ============================================================

set HF_USER=zakariaennaqui
set BASE=C:\Users\u1602\Documents\S7\Programmation JEE\projet\livrago
set TEMP_DIR=%BASE%\hf-deploy-temp

echo ========================================================
echo  Deploying Livrago to HuggingFace Spaces
echo  User: %HF_USER%
echo ========================================================
echo.
echo IMPORTANT: You will be asked for your HuggingFace credentials.
echo Use your HuggingFace username and an Access Token as password.
echo Get your token at: https://huggingface.co/settings/tokens
echo.
pause

REM Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

REM List of services and their Space names
set SERVICES=discovery-service:livrago-discovery api-gateway:livrago-gateway user-service:livrago-user order-service:livrago-order delivery-service:livrago-delivery warehouse-service:livrago-warehouse notification-service:livrago-notification product-service:livrago-product route-service:livrago-route tracking-service:livrago-tracking

for %%P in (%SERVICES%) do (
  for /f "tokens=1,2 delims=:" %%A in ("%%P") do (
    set SVC=%%A
    set SPACE=%%B
    call :deploy_service %%A %%B
  )
)

echo.
echo ========================================================
echo  All services deployed to HuggingFace!
echo  Check your spaces at: https://huggingface.co/%HF_USER%
echo ========================================================
goto :eof

:deploy_service
set SVC=%1
set SPACE=%2
set SPACE_DIR=%TEMP_DIR%\%SPACE%

echo.
echo [%SVC%] Deploying to https://huggingface.co/spaces/%HF_USER%/%SPACE%...

REM Clone the Space (must already exist on HuggingFace)
if exist "%SPACE_DIR%" (
  echo [%SVC%] Space directory exists, pulling latest...
  cd /d "%SPACE_DIR%"
  git pull
) else (
  echo [%SVC%] Cloning space...
  cd /d "%TEMP_DIR%"
  git clone https://huggingface.co/spaces/%HF_USER%/%SPACE% "%SPACE_DIR%"
  if errorlevel 1 (
    echo [%SVC%] ERROR: Could not clone. Make sure the Space '%SPACE%' exists on HuggingFace!
    echo         Create it at: https://huggingface.co/new-space
    echo         Name: %SPACE%, SDK: Docker, Visibility: Public
    goto :eof
  )
)

REM Copy service files to Space
cd /d "%SPACE_DIR%"
echo [%SVC%] Copying source files...

REM Copy Dockerfile
copy /Y "%BASE%\%SVC%\Dockerfile" "%SPACE_DIR%\Dockerfile" >nul

REM Copy source code
if exist "%SPACE_DIR%\src" rmdir /s /q "%SPACE_DIR%\src"
xcopy /E /I /Q "%BASE%\%SVC%\src" "%SPACE_DIR%\src" >nul

REM Copy pom.xml
copy /Y "%BASE%\%SVC%\pom.xml" "%SPACE_DIR%\pom.xml" >nul

REM Setup .gitattributes for LFS (just in case)
echo *.jar filter=lfs diff=lfs merge=lfs -text > "%SPACE_DIR%\.gitattributes"

REM Commit and push
git add .
git commit -m "Deploy %SVC% to HuggingFace Space"
git push

if errorlevel 1 (
  echo [%SVC%] Push failed. Check your credentials.
) else (
  echo [%SVC%] Successfully deployed!
)

goto :eof
