ruby killRubyCodes.rb
pushd ../lib/DRbSharedMemory/
ruby Server.rb &
popd
pushd ../PC_GrapeForBoardListener/
rackup -p9292 --host 0.0.0.0 2>/dev/null & 
popd
pushd ../PC_SinatraGui/
ruby Sinatra.rb &
popd
