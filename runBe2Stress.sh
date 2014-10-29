# This script will run the processes for the BE2STRESS.
bash pcSideRun.sh &
nohup ssh root@192.168.1.211 'bash -s' < sshScriptRunBoard.sh & 
