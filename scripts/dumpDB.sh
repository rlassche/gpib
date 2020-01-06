#!/bin/sh
#########################################################################
# Description:
#	Dump mysql databases and copy the zipped files to dropbox.
#
# Databases:
#	muziek
#	wiki
#########################################################################
BACKUPSERVER=192.168.123.30
DAYNR=`date +%d`

echo -n "Dump gpib DB..."
mysqldump -ugpib -pgpib gpib | gzip -9 > gpib.sql.gz

scp gpib.sql.gz $BACKUPSERVER:
echo "done";

echo "On the rpi3 you can import the database:"
echo 'zcat gpib.sql.gz | mysql -ugpib -pgpib gpib'
