#
# Make sure only one process is running for the the rackup board.
#
LockFile=/tmp/bbbBoardGrapeFileLock.txt
if [ -e ${LockFile} ] && kill -0 `cat ${LockFile}`; then
    echo "rackup board is already running"
    exit
fi

# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LockFile}; exit" INT TERM EXIT
echo $$ > ${LockFile}

# do stuff
sleep 3
cd /var/lib/cloud9/slot-controller/BBB_GrapeForPcListener/
sudo rackup

rm -f ${LockFile}
