bash Gui.sh &
bash DataReceiver.sh & 
ssh root@192.168.7.2 'bash -s' < fromPcRunTcuSamplerInBbb.sh &
ssh root@192.168.7.2 'bash -s' < fromPcRunSampledTcuSenderInBbb.sh &
