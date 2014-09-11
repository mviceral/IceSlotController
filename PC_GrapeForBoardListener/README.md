To run the whole code, run the BASH script:
bash runEverything.sh

To run Sinatra that displays the GUI.
	ruby Sinatra.rb &

To run Grape that takes in data from BBB
	rackup &

# 
# To list the table names in an sqlite3 database, use the following command.
#
select sql from sqlite_master where tbl_name = 'latest' and type = 'table'
