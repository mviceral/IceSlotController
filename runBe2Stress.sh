# This script will run the processes for the BE2STRESS.
clear
echo "The cronjob runs all the BE2 processes every min (if they're not running)."
echo "Once all are running, a browser will open a page 'http://localhost:4569' to view the BE2 application." 
echo "Processing. Please wait ~1 min."
bash scripts/pcSideRun.sh 2>/dev/null &
ssh root@192.168.1.211 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
ssh root@192.168.1.212 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
sleep 60  
xdg-open http://localhost:4569 &
clear
echo "Script complete.  BE2 application can be accessed through a browser at 'http://localhost:4569'."
