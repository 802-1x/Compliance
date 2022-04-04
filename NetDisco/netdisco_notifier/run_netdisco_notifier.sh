#!/bin/bash
python3 /home/xxxx/netdisco_notifier/netdisco_notifier.py --config_file /home/xxxx/netdisco_notifier/notifier_config.json --notify all
#python3 netdisco_notifier.py --config_file notifier_config.json --notify immediate
#python3 netdisco_notifier.py --config_file notifier_config.json --notify historic

## crontab configuration:
## .---------------- minute (0 - 59)
## |  .------------- hour (0 - 23)
## |  |  .---------- day of month (1 - 31)
## |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
## |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7)  OR sun,mon,tue,wed,thu,fri,sat
## |  |  |  |  |
#	# *  *  *  *  *  command to be executed
## *  *  *  *  *  command --arg1 --arg2 file1 file2 2>&1
##
## run historic report every day at six AM
# 0  6  *  *  *  python3 /home/xxxx/netdisco_notifier/netdisco_notifier.py --config_file /home/xxxx/netdisco_notifier/notifier_config.json --notify historic
#
# # run immediate report every hour, on the hour
#  0  *  *  *  *  python3 /home/xxxx/netdisco_notifier/netdisco_notifier.py --config_file /home/xxxx/netdisco_notifier/notifier_config.json --notify immediate
#  ~
