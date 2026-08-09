@echo off
set ADDONNAME=Buffalo
set SOURCE=%~dp0
set TARGET=C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\

copy %SOURCE%\%ADDONNAME%\*.lua "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.toc "%TARGET%\%ADDONNAME%\" /Y
copy %SOURCE%\%ADDONNAME%\*.xml "%TARGET%\%ADDONNAME%\" /Y

echo.
