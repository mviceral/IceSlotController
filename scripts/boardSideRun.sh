ruby killRubyCodes.rb
pushd ../lib/DRbSharedMemory/
bash runSharedMemory.sh &
popd
pushd ../BBB_GrapeForPcListener/
bash runBoardGrape.sh &
popd
pushd ../BBB_Sampler/
bash runSampler.sh & 
popd
