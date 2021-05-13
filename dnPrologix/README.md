# General

There are 3 project:

* Console
  Console version for testing gpib.
* Server
  REST server for gpib

# Console

Project directory: `dnPrologix.console`

# Test

Project directory: `dnPrologix.test`


# REST Server

* Project directory `dnPrologix.server`
* GPIB config file
  Parameter `GpibConfig` in file `appsettings.*.json`

# GpibConfig file



# Deploy software

Script:

```
# DEPLOY_DIR is C:\temp\GPIB
# CONFIGURATION is git or develop
deploy.cmd %CONFIGURATION%
```

ZIP file `gpib-win-%CONFIGURATION%.zip`



# Dotnet on RPI

https://docs.microsoft.com/en-us/dotnet/iot/deployment

https://www.petecodes.co.uk/install-and-use-microsoft-dot-net-5-with-the-raspberry-pi/

Additional:

dotnet tool install dotnet-ef -g
