@echo off
REM Laatste update: 03-MAR-2021
REM
REM Deploy GPIB C# version
REM


REM
REM tmp-directory for building all exe and dll files
REM
SET DEPLOY_DIR=c:\temp\gpib

REM
REM Final directory where 
SET RESTSERVER_HOME=C:\GPIB

IF "%1" == "" GOTO ERROR
	echo OKAY, GOTO %1
	REM
	REM References the site-specific variables in file : environments\environment.%CONFIGURATION%.ts
	REM
	SET CONFIGURATION=%1
	GOTO %CONFIGURATION%
:ERROR
	echo Define git branch: master, develop
	GOTO EINDE
:master
:develop

git checkout %CONFIGURATION%
pause
REM git checkout master



GOTO PUBLISH

:PUBLISH
echo dotnet publish in %DEPLOY_DIR%
call dotnet publish --output %DEPLOY_DIR% --configuration Release --runtime win-x64 --no-self-contained
COPY dnPrologix.test\gpib.json %DEPLOY_DIR%\gpib.json.example

DEL C:\temp\gpib-win-%CONFIGURATION%.zip /Q/F/S
echo Create file C:\temp\gpib-win-%CONFIGURATION%.zip
call powershell Compress-Archive -LiteralPath %DEPLOY_DIR% -DestinationPath C:\temp\gpib-win-%CONFIGURATION%.zip

echo SCP c:/temp/gpib-win-%CONFIGURATION%.zip to pi@rpi4
call scp c:/temp/gpib-win-%CONFIGURATION%.zip pi@rpi4:/var/www/l-oss.nl/downloads




REM
REM Generate the documentation. Files are stored in c:\inetpub\wwwroot\docs\backend\
REM The Angular deployment CAN copy the files to another directory if required.
REM Call Doxygen

REM COPY %CMD_FILE%  %RESTSERVER_HOME%
REM COPY %CMD_SHORTCUT% %RESTSERVER_HOME%

REM Start RESTServer by typing:
:EINDE
echo Good bye 