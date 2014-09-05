#
# Make sure only one process is running for Sinatra (Gui), and Grape (data reciever) processes.
#
BbbDataReceiverLock=/tmp/bbbDataReceiverLock.txt
if [ -e ${BbbDataReceiverLock} ] && kill -0 `cat ${BbbDataReceiverLock}`; then
    echo "DataReceiver.sh is already running"
    exit
fi

# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${BbbDataReceiverLock}; exit" INT TERM EXIT
echo $$ > ${BbbDataReceiverLock}

# do stuff
rackup Grape.ru

rm -f ${BbbDataReceiverLock}

        
