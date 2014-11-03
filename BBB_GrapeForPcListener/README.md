-To setup rackup in a fresh BBB, run the following first.
gem update
aptitude install ruby1.9.1-dev
gem install rack
gem install grape
apt-get install libsqlite3-dev
gem install sqlite3
gem install rest-client
pushd ../lib
ruby extconf.rb
make
popd
gem install beaglebone
mkdir /mnt/card
mount /dev/mmcblk0p1 /mnt/card
vi /mnt/card/uEnv.txt

- Set the time zone
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

-Then insert the following line.  No carriage return at the end of line?
optargs=quiet capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN

-Reboot the board:
shutdown -r now

#
# To setup the static ip address of BBB
# Read up on http://www.mathworks.com/help/simulink/ug/getting-the-beagleboard-ip-address.html
#
