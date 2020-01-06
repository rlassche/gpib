#!/bin/bash
set -x
APACHE_ROOT=/var/www/html
DATE=`date '+%Y-%m-%d.%H:%M:%S'`
if [ -d dist/ngGPIB ] 
then
	rm -r "dist/ngGPIB"
fi
APACHE_CONFIG=/etc/apache2/sites-enabled/000-default.conf
DOCUMENTROOT=`awk '/DocumentRoot/ { print $2 }' $APACHE_CONFIG`
[ -d $DOCUMENROOT ] \
	&& rm -rf $DOCUMENTROOT/gpib \
	&& mkdir $DOCUMENTROOT/gpib
if [ $? -ne 0 ]
then
	echo "Failed to remove/create $DOCUMENTROOT/gpib directory." 
fi

ng build --prod --base-href /gpib/ 
#	&& ssh rpi3 mv /var/www/html/gpib "/var/www/html/gpib.$DATE"
#echo p -r dist/gpib/ rpi3:/var/www/html
#scp -r dist/gpib/ rpi3:/var/www/html

echo cp -r dist/ngGPIB/ $DOCUMENTROOT
cp -r dist/ngGPIB/ $DOCUMENTROOT
#echo "Clean the Apache disk cache:"
#echo "*** Goto rpi3 and run: /etc/apache2/cleanDiskCache.sh ***"
#ng build --prod --base-href /gpib/  \
ssh rpi3 mv $APACHE_ROOT/gpib "$APACHE_ROOT/gpib.$DATE"
scp -r dist/ngGPIB/ rpi3:/var/www/html/gpib
echo "Clean the Apache disk cache on rpi3:"
echo "*** Goto rpi3 and run: /etc/apache2/cleanDiskCache.sh ***"
ssh rpi3 /etc/apache2/cleanDiskCache.sh

sudo rm -rf $APACHE_ROOT/gpib \
	&& cp -r dist/ngGPIB/ $APACHE_ROOT
