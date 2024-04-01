@echo off

setlocal
set TASM32=%TASM_HOME%\bin\tasm32.exe
set LINK32=%TASM_HOME%\bin\tlink32.exe
set BRC32=%TASM_HOME%\bin\brcc32
set IMPLIB=%TASM_HOME%\lib\import32.lib

set INCLUDE=%TASM_HOME%\include

rem To enable debug info:
rem   * pass /zi to tasm32
rem   * pass /v  to tlink32


%TASM32% /c /D__tasm__ /I%INCLUDE% /ml /z /w2 /m3 ^
    Icons.asm, Icons.obj, Icons.lst

%BRC32% /foresource\merged.en-ru.res resource\merged.en-ru.rc
%BRC32% /foresource\merged.en.res    resource\merged.en.rc
%BRC32% /foresource\merged.ru.res    resource\merged.ru.rc

%LINK32% /Tpe /aa /m /s /c /V4.0 ^
    Icons.obj, Icons.exe, Icons.map, %IMPLIB%, , ^
    resource\merged.en-ru.res

rem or a list of: Icons.res Icons.version.en-ru.res Icons.en.res Icons.ru.res Icons.manifest.res

%LINK32% /Tpe /aa /m /s /c /V4.0 ^
    Icons.obj, Icons.en.exe, Icons.en.map, %IMPLIB%, , ^
    resource\merged.en.res

%LINK32% /Tpe /aa /m /s /c /V4.0 ^
    Icons.obj, Icons.ru.exe, Icons.ru.map, %IMPLIB%, , ^
    resource\merged.ru.res
