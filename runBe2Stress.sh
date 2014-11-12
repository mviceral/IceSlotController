# This script will run the processes for the BE2STRESS.
# clear
# echo "A browser will open a page 'http://localhost:4569' to view the BE2 application." 
#echo "Processing. Please wait ~1 min."
bash scripts/pcSideRun.sh 2>/dev/null &
ssh root@192.168.1.211 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
ssh root@192.168.1.212 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
#sleep 60  
xdg-open http://localhost:4569 &
clear
echo "BE2 start-up script complete.  BE2 application can be accessed through a browser at 'http://localhost:4569'."
echo "Once the the display values on the slots are active, they're ready for commands."
