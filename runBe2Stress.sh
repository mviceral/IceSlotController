# This script will run the processes for the BE2STRESS.
clear
echo "The cronjob runs all the processes every min (if they're not running)."
echo "Processing. Please wait ~1 min."
bash pcSideRun.sh 2>/dev/null &
ssh root@192.168.1.211 'bash -s' < sshScriptRunBoard.sh 2>/dev/null & 
ssh root@192.168.1.212 'bash -s' < sshScriptRunBoard.sh 2>/dev/null & 
sleep 60  
clear
echo "Script complete."
