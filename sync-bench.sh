#!/bin/bash
cd ~/Downloads/chia-blockchain #change this to your chia location
cp ~/.chia/mainnet/db/blockchain_v2_mainnet.sqlite ~/chia-scripts/blockchain_v2_backup.sqlite # make a backup of your current db
sleep 1 #wait so we are sure it has moved
ls -la ~/chia-scripts #print so user knows it has made a backup
rm ~/.chia/mainnet/db/blockchain_v2_mainnet.sqlite # delete the original db
nodeip=$1 # first parameter is the ip:port of a node you want to use to sync
. ./activate #start chia
chia start farmer # start the farmer

blockheight=$(chia show -s | grep -oP "Height:       \K.*") # chia show and then grep the number after height: so we know where it is in the sync
chia peer -a $nodeip full_node # add our peer (make sure that outbound is 0 in the config.yaml so no others are connected automaticaly

echo Blockchain synchronised to peak: $blockheight 
i=1 # simple counter so the node isnt added every time but the check is done so we dont wait
treshold=$2 # what height to stop at
start=$(date +%s%N) # a timer to check how long it took to start syncing
while [ -z "$blockheight" ] # while no blockheight(chia hasnt started syncing yet and is starting
do

if [ "$i" -gt 30 ]
then

chia peer -a $nodeip full_node
i=1
fi

blockheight=$(chia show -s | grep -oP "Height:       \K.*")

sleep 1
i=$((i+1))
done
end=$(date +%s%N) # enc the startup timer
echo "Startup time: $(($end-$start)) ns"
i=1

start=$(date +%s%N) # start the timer for our sync time
while [ "$treshold" -gt "$blockheight" ]; # wait until our desired height has been reached
do

	if [ "$i" -gt 10 ]
	then
	chia peer -a $nodeip full_node
	i=1
	fi



	blockheight=$(chia show -s | grep -oP "Height:       \K.*")
	echo Blockchain synchronised to peak: $blockheight
	i=$((i+1))
done


if [ "$blockheight" -ge "$treshold" ] # if the height has been reached stop chia and the timer
then
end=$(date +%s%N)
echo "Sync time: $(($end-$start)) ns"
chia stop farmer
fi
