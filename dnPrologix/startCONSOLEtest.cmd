@echo off

set GPIB_INSTALL_DIR=%~dp0
REM
REM 
REM 
echo -----------------------------------------------------------
echo --                                                       --
echo --                   start GPIB CONSOLE test             -- 
echo --                                                       --
echo -----------------------------------------------------------                
echo GPIB installatie directory: %GPIB_INSTALL_DIR%
echo ----------------------------------------------------------
echo GPIB installatie directory: %GPIB_INSTALL_DIR%

cd %GPIB_INSTALL_DIR%

REM
REM Start communicatie test programma
REM

dnPrologix.console.exe

pause