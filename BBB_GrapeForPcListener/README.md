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

-Then insert the following line.
optargs=quiet capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN

-Reboot the board:
shutdown -r now
