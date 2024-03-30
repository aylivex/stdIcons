@echo off

setlocal
set PATH=%TASM_HOME%\bin;%PATH%

make /b /dDEBUG INCLUDEPATH=%TASM_HOME%\include LIBPATH=%TASM_HOME%\lib %*
