#
# Make sure only one process is running for the TCU Sampler.
#
LockFile=/tmp/pcSharedMemoryFileLock.txt
if [ -e ${LockFile} ] && kill -0 `cat ${LockFile}`; then
    echo "runTcuSampler.sh is already running"
    exit
fi

# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LockFile}; exit" INT TERM EXIT
echo $$ > ${LockFile}

# do stuff
# cd /home/cseven/slot-controller/lib/DRbSharedMemory/
cd /home/marvinv/slot-controller/lib/DRbSharedMemory
ruby Server.rb

rm -f ${LockFile}
