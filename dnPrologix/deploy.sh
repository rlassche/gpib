#!/bin/sh
TARFILE=/tmp/gpib-linux.tar.gz

echo "git checkout master ..."
git checkout master
echo "dotnet publish ..."
dotnet publish --output /tmp/gpib$$ --configuration Release --no-self-contained
cd /tmp/gpib$$
tar cvfz $TARFILE .
echo "File $TARFILE generated"
rm -rf /tmp/gpib$$
scp $TARFILE  pi@rpi4:/var/www/l-oss.nl/downloads
