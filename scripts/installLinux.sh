#!/bin/sh
#####################################################################
# Description:
# Install some required packages for the gpib-project with Perl.
#####################################################################
sudo locale-gen nl_NL.UTF-8
sudo apt-get update && \
	apt-get upgrade && \
	apt-get install build-essential binutils-dev libssl-dev libusb-dev \
	bison flex libmpfr-dev libexpat1-dev fxload qtbase5-dev

# Plain linux
#sudo apt-get install linux-headers-$(uname -r)

# Raspbery pi
#sudo apt-get install raspberrypi-kernel-headers
