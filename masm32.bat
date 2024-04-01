@echo off

setlocal
set VERSION=3.0.0.0

set MASM32=%MASM32_HOME%\bin\ml.exe
set LINK32=%MASM32_HOME%\bin\link.exe
set RC=%MASM32_HOME%\bin\rc.exe
set LIB=%MASM32_HOME%\lib

set INCLUDE=%TASM_HOME%\include

rem To enable debug info:
rem   * pass /Zi to ml
rem   * pass /debug:full to link


%MASM32% /nologo /D__masm__ /I%INCLUDE% /c /Cp /coff /WX ^
    /FlIcons.lst /FoIcons.obj ^
    Icons.asm

%RC% /foresource\merged.en-ru.res resource\merged.en-ru.rc
%RC% /foresource\merged.en.res    resource\merged.en.rc
%RC% /foresource\merged.ru.res    resource\merged.ru.rc

%LINK32% /nologo /map:Icons.map /out:Icons.exe ^
    /release ^
    /fixed ^
    /subsystem:windows,4.0 ^
    /version:%VERSION% ^
    "/libpath:%LIB%" ^
    Icons.obj ^
    kernel32.lib user32.lib gdi32.lib ^
    resource\merged.en-ru.res

%LINK32% /nologo /map:Icons.en.map /out:Icons.en.exe ^
    /release ^
    /fixed ^
    /subsystem:windows,4.0 ^
    /version:%VERSION% ^
    /libpath:%LIB% ^
    Icons.obj ^
    kernel32.lib user32.lib gdi32.lib ^
    resource\merged.en.res

%LINK32% /nologo /map:Icons.ru.map /out:Icons.ru.exe ^
    /release ^
    /fixed ^
    /subsystem:windows,4.0 ^
    /version:%VERSION% ^
    /libpath:%LIB% ^
    Icons.obj ^
    kernel32.lib user32.lib gdi32.lib ^
    resource\merged.ru.res
