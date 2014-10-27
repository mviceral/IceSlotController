pushd /var/lib/cloud9/slot-controller/
ruby killRubyCodes.rb
pushd ./lib/DRbSharedMemory/
nohup ruby Server.rb & 
popd
pushd ./BBB_Sampler/
nohup bash runTcuSampler.sh & 
popd
# pushd ./BBB_GrapeForPcListener/
# nohup nice rackup config.ru & 
# popd
