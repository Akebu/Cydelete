#!/bin/bash
rm -rf /tmp/CydeleteError.log

for i in $(seq 1 3);
do
	Output=$(sudo apt-get -y remove $1 2>&1 | tail -1)
		if [[ "$Output" =~ "E:" ]]; then
			if [[ "$i" -eq "3" ]]; then
				echo -e "Package:"$1"\n"$Output >> /tmp/CydeleteError.log
				exit
			fi
			sleep 5
		else
			exit
		fi
done
