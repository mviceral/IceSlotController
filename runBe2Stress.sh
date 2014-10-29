# This script will run the processes for the BE2STRESS.
clear
echo "Processing. Please wait 10 sec."
bash pcSideRun.sh 2>/dev/null &
ssh root@192.168.1.211 'bash -s' < sshScriptRunBoard.sh 2>/dev/null & 
sleep 10 
clear
echo "Script complete."
