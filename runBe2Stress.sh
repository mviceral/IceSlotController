# This script will run the processes for the BE2STRESS.
clear
echo "Processing. Please wait ~1.5 min."
bash pcSideRun.sh 2>/dev/null &
ssh root@192.168.1.211 'bash -s' < sshScriptRunBoard.sh 2>/dev/null & 
sleep 60  
sleep 30  
clear
echo "Script complete."
