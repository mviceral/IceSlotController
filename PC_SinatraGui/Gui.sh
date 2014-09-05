#
# Make sure only one process is running for Sinatra (Gui), and Grape (data reciever) processes.
#
BbbGuiLock=/tmp/bbbGuiLock.txt
if [ -e ${BbbGuiLock} ] && kill -0 `cat ${BbbGuiLock}`; then
    echo "Gui.sh is already running"
    exit
fi

# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${BbbGuiLock}; exit" INT TERM EXIT
echo $$ > ${BbbGuiLock}

# do stuff
ruby Sinatra.rb

rm -f ${BbbGuiLock}

        
