# This script will run the processes for the BE2STRESS.
bash pcSideRun.sh 2>/dev/null &
ssh root@192.168.1.211 'bash -s' < sshScriptRunBoard.sh 2>/dev/null & 
