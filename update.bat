@echo off
title Lua Code Editor Update
set /p changes="Changes: "

git commit -a -m "%changes%"
git push

gmad.exe create -folder "./" -out ".gma"
if exist ".gma" (
	gmpublish.exe update -addon ".gma" -id "2173212443" -changes "%changes%"
) else (
	echo Could not create gma archive, aborting
)

if exist ".gma" (
	del /Q ".gma"
)

pause