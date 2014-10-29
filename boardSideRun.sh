ruby killRubyCodes.rb
pushd ./lib/DRbSharedMemory/
ls -l
nohup nice ruby Server.rb & 
popd
pushd ./BBB_GrapeForPcListener/
ls -l
nohup nice rackup config.ru & 
popd
pushd ./BBB_Sampler/
ls -l
nohup nice bash runTcuSampler.sh & 
popd
