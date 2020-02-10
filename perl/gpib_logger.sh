#!/bin/bash
device='1998';
cmd_file='1998_init.cmd';
#perl gpib_logger.pl --device $device --command_file $cmd_file --log_type txt
#perl gpib_logger.pl --device $device --command_file $cmd_file --log_type txt --max_count 5
perl gpib_logger.pl --device $device --command_file $cmd_file --log_type txt --max_count 0
