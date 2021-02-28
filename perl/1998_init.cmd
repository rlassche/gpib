#
# Special symbols:
# 1)	'#' symbol 
#		is comment in this cmd-file
# 2)	Empty lines 
#		are skipped.
# '!' lines i
#	are internal commands like:
#		exit
#		logfile


#
# Command file for GPIB Racal 1998
# Display version of the Prologix-GPIB-USB device (= internal command)
++help
++addr
++auto
! The version is:

#STOREDISRES10mSEC
SRS7


# Frequency channel B
FB

#Q7
#SRQGEN_MEAS_RDY_ERR_FREQCHANGE
RGS
#RECALL_GPIB_SFTW_ISS_NR
# Continue measurements
T0
++ver
! Nog een keer de version
++ver
++ver
