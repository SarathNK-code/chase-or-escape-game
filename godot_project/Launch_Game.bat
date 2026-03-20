@echo off
echo Launching Chase or Escape Game in Godot Engine...
echo.

REM Set paths
set GODOT_EXE="C:\Users\Srivalli T\OneDrive\Sarath\Github_Projects\Godot_v4.6.1-stable_win64.exe"
set PROJECT_PATH="C:\Users\Srivalli T\OneDrive\Sarath\Github_Projects\ChaseOrEscape_Godot"

REM Check if Godot exists
if not exist %GODOT_EXE% (
    echo ERROR: Godot Engine not found at %GODOT_EXE%
    echo Please ensure Godot is installed at the correct location.
    pause
    exit /b 1
)

REM Check if project exists
if not exist %PROJECT_PATH% (
    echo ERROR: Project folder not found at %PROJECT_PATH%
    echo Please ensure the project files are in the correct location.
    pause
    exit /b 1
)

REM Launch Godot with the project
echo Starting Godot Engine...
%GODOT_EXE% --path %PROJECT_PATH% --editor

echo.
echo If Godot doesn't open, please manually:
echo 1. Open Godot Engine
echo 2. Click "Import" 
echo 3. Select: %PROJECT_PATH%
echo 4. Press F5 to play
echo.
pause
