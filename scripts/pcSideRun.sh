ruby killRubyCodes.rb
pushd ../lib/DRbSharedMemory/
bash runPcSharedMemory.sh &
popd
sleep 1m
pushd ../PC_GrapeForBoardListener/
rackup 2>/dev/null & 
popd
pushd ../PC_SinatraGui/
bash runSinatra.sh &
popd
