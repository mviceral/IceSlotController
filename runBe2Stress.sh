# To run this code, type in ". runBe2Stress.sh" and press enter.

# This script will run the processes for the BE2STRESS.
# Provide the three IP addresses of the slot controllers to SLOT1, SLOT2, and SLOT3 variables.

SLOT1=192.168.1.209
SLOT2=192.168.1.211
SLOT3=192.168.1.212

bash scripts/pcSideRun.sh 2>/dev/null &
ssh root@$SLOT1 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
ssh root@$SLOT2 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
ssh root@$SLOT3 'bash -s' < scripts/sshScriptRunBoard.sh 2>/dev/null & 
#sleep 60  
sleep 3 # wait for the noise from the top processes to show then clear the screen.
clear
echo "BE2 start-up script complete.  BE2 application can be accessed through"
echo "a browser at 'http://localhost:4569'.  Please wait for the page to load"
echo "since the browser is waiting for the slot controllers to respond "
echo "(at most, about ~1 minute)."
echo ""
echo "Once the the display values on the slots are active, they're ready for"
echo "commands."
read -n1 -r -p "Press any to continue..." key

#if [ "$key" = ' ' ]; then
#    # Space pressed, do something
#fi
xdg-open http://localhost:4569 2>/dev/null &

# do the ftp folder mount 
/etc/init.d/setFtpMosys
clear
exit
