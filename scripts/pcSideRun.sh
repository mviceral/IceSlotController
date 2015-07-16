pushd scripts
ruby killRubyCodes.rb
popd
sleep 2
pushd ./lib/DRbSharedMemory/
bash runPcSharedMemory.sh &
popd
pushd ./PC_GrapeForBoardListener/
rackup -p9292 --host 0.0.0.0 2>/dev/null & 
popd
pushd ./PC_SinatraGui/
bash runSinatra.sh &
popd
