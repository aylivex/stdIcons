@echo off
for %%e in (*.exe) do dumpbin /headers %%e >%%e.txt
