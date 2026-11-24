@echo off
rem Starts the game (not the editor). Double-click to play.
set GODOT=C:\Users\julie\Documents\GameDev\Godot\Godot_v4.6.1-stable_win64.exe
if not exist "%GODOT%" (
  echo Could not find Godot at %GODOT%
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0."
