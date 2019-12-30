#!/bin/sh
#####################################################################
# Description:
# Install some required packages for the gpib-project with Perl.
#####################################################################
sudo locale-gen nl_NL.UTF-8
sudo apt-get update && \
	apt-get upgrade && \
	apt-get install build-essential binutils-dev libssl-dev libusb-dev \
	bison flex libmpfr-dev libexpat1-dev linux-headers-$(uname -r) \
	fxload qtbase5-dev
