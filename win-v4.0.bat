@echo off
for %%e in (*.exe) do %MASM32_HOME%\bin\editbin /subsystem:windows,4.0 %%e
