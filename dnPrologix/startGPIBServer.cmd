@echo off

set GPIB_INSTALL_DIR=%~dp0

REM
REM 
REM 
echo -----------------------------------------------------------
echo --                                                       --
echo --                   start GPIB MVC Server               -- 
echo --                                                       --
echo -----------------------------------------------------------                
echo GPIB installatie directory: %GPIB_INSTALL_DIR%
echo -----------------------------------------------------------

cd %GPIB_INSTALL_DIR%

REM
REM Start communicatie test programma
REM

dnPrologix.server.exe

pause