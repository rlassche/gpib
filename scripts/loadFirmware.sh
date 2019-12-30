#!/bin/bash
######################################################################
# The Agilent USB/GPIB interface requires a firmware update.
# The while loop makes sure that the upgrade is done several times!
# NOTE: Only one time fxload will NOT work!
# 
######################################################################

FIRMWARE_FILE=/opt/gpib_firmware-2008-08-10/agilent_82357a/measat_releaseX1.8.hex
if [ ! -f $FIRMWARE_FILE ]
then
	echo "Firmware upgrade file not found! ($FIRMWARE_FILE)";
	exit 1;
fi

modprobe gpib_common
if [ $? != 0 ]
then
	echo "ERROR: modprobe gpib_common failed!";
	exit 1
fi
modprobe agilent_82357a
if [ $? != 0 ]
then
	echo "ERROR: agilent_82357a failed!";
	exit 1
fi

# Return:
#	1234:5678 /dev/a/b/c
#
getFirmwareVersion() {
	local GPIB_DEV;
	GPIB_DEV=`lsusb | grep Agilent`;
	local FIRMWARE=`echo $GPIB_DEV | awk '{ print $6 }'`
	local DEV1=`echo $GPIB_DEV | awk '{ print $2 }'`
	local DEV2=`echo $GPIB_DEV | awk '{ print $4 }' | sed 's/://'`
	DEV="/dev/bus/usb/$DEV1/$DEV2"
	echo "$FIRMWARE $DEV";
}
RETVAL=$(getFirmwareVersion)
while [[ ! "$RETVAL" =~ ^"0957:0718 " ]]
do
	echo "Current firmware version and device: $RETVAL";
	DEV=`echo $RETVAL|awk '{ print $2 }'`

	echo "Upgrade firmware...";
	#echo fxload -t fx2 -D $DEV -I $FIRMWARE_FILE
	fxload -t fx2 -D $DEV -I $FIRMWARE_FILE
	sleep 5
	RETVAL=$(getFirmwareVersion)
done

