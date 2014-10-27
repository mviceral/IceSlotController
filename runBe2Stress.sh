# This script will run the processes for the BE2STRESS.
bash pcSideRun.sh &
ssh root@192.168.1.212 'bash -s' < sshScriptRunBoard.sh & 
