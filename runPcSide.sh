ruby killRubyCodes.rb
pushd ./lib/DRbSharedMemory/
ruby Server.rb &
popd
pushd ./PC_GrapeForBoardListener/
rackup & 
popd
pushd ./PC_SinatraGui/
ruby Sinatra.rb
popd
