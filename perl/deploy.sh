#
#
VERSION='1.0';
COMPILE_DATE='07-JUL-2018';

hostname=`hostname`

if [ $hostname = "www.software-development-consulting.nl" ]
then
	WEBHOME=/var/www/software-development-consulting.nl-ssl/www/docs
else if [ $hostname = "homesrv" ]
then
	WEBHOME=/var/www/ubuntu.localdomain/docs
else if [ $hostname = "hp-probook" ]
then
	WEBHOME=/var/www/html/docs
else if [ $hostname = "pc-henk" ]
then
	WEBHOME=/usr/share/nginx/pc-henk.mijn-hobbies.nl/docs
else if [ $hostname = "rpi3" ]
then
	WEBHOME=/var/www/html/docs
else
	WEBHOME=/var/www/ubuntu.localdomain/docs
fi
fi
fi
fi
fi

DEST=/home/rlassche/zzp/perldev/ppm	

SITE_PERL=/usr/local/lib/site_perl/

if [ ! -d $WEBHOME/SDC ]
then
	echo mkdir -p $WEBHOME/SDC
	mkdir -p $WEBHOME/SDC
fi

if [ ! -d $SITE_PERL/SDC ]
then
	echo mkdir -p $SITE_PERL/SDC
	mkdir -p $SITE_PERL/SDC
fi

echo "SITE_PERL: $SITE_PERL\n" ;

file=SDC/GPIB.pm
echo cp $file $SITE_PERL
cp $file $SITE_PERL/SDC && echo "Copy $file to $SITE_LIB/SDC"
echo "$file: \""`grep "self.*VERSION" $file | sed -e 's/.*=\"//'`
pod2html $file > $WEBHOME/$file.html

