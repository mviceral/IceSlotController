ruby killRubyCodes.rb
pushd ./lib/DRbSharedMemory/
ruby Server.rb & 
popd
pushd ./BBB_GrapeForPcListener/
rackup config.ru & 
popd
pushd ./BBB_Sampler/
bash runTcuSampler.sh & 
popd
