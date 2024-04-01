@echo off

setlocal
set PATH=%TASM_HOME%\bin;%PATH%

make /ftasm.gmk /b /dDEBUG INCLUDEPATH=%TASM_HOME%\include LIBPATH=%TASM_HOME%\lib %*
