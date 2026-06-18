@echo off
REM ============================================================
REM  Script de déploiement Livrago → HuggingFace (theutwo)
REM  Services: route, tracking
REM ============================================================

set HF_USER=theutwo
set HF_TOKEN=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
set BASE=C:\Users\u1602\Documents\S7\Programmation JEE\projet\livrago
set TEMP_DIR=%BASE%\hf-deploy-temp

echo ========================================================
echo  Deploying to HuggingFace Spaces
echo  User: %HF_USER%
echo ========================================================
echo.

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

set SERVICES=route-service:livrago-route tracking-service:livrago-tracking

for %%P in (%SERVICES%) do (
  for /f "tokens=1,2 delims=:" %%A in ("%%P") do (
    call :deploy_service %%A %%B
  )
)

echo.
echo ========================================================
echo  Done! Check: https://huggingface.co/%HF_USER%
echo ========================================================
goto :eof

:deploy_service
set SVC=%1
set SPACE=%2
set SPACE_DIR=%TEMP_DIR%\%HF_USER%-%SPACE%

echo.
echo [%SVC%] Deploying to https://huggingface.co/spaces/%HF_USER%/%SPACE%...

if exist "%SPACE_DIR%" (
  echo [%SVC%] Updating existing local clone...
  cd /d "%SPACE_DIR%"
  git pull
) else (
  echo [%SVC%] Cloning space...
  cd /d "%TEMP_DIR%"
  git clone https://%HF_USER%:%HF_TOKEN%@huggingface.co/spaces/%HF_USER%/%SPACE% "%SPACE_DIR%"
  if errorlevel 1 (
    echo [%SVC%] ERROR: Space '%SPACE%' not found. Create it first on HuggingFace!
    goto :eof
  )
)

cd /d "%SPACE_DIR%"

copy /Y "%BASE%\%SVC%\Dockerfile" "%SPACE_DIR%\Dockerfile" >nul
if exist "%SPACE_DIR%\src" rmdir /s /q "%SPACE_DIR%\src"
xcopy /E /I /Q "%BASE%\%SVC%\src" "%SPACE_DIR%\src" >nul
copy /Y "%BASE%\%SVC%\pom.xml" "%SPACE_DIR%\pom.xml" >nul
echo *.jar filter=lfs diff=lfs merge=lfs -text > "%SPACE_DIR%\.gitattributes"

git add .
git commit -m "Deploy %SVC%"
git push

if errorlevel 1 (
  echo [%SVC%] Push failed. Check credentials or create the Space first.
) else (
  echo [%SVC%] Successfully deployed!
)

goto :eof
