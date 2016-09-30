#!/bin/bash
Output=$(sudo apt-get -y remove $1 2>&1 >/dev/null)
if Output
then
	exit
else
	echo $Output >> /tmp/cydeleteError
fi
exit
