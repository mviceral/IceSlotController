require 'rubygems'
require 'sinatra'
require 'sqlite3'

def CreateDutCell(labelParam,rawDataParam)
	rawDataParam = rawDataParam[0].partition("@")
	isRunning = rawDataParam[2].partition(",")
	ambientTemp = isRunning[2].partition(",")
	dutTemp = ambientTemp[2].partition(",")
	toBeReturned = "<table>"
	toBeReturned += "<tr><td>"+labelParam+"</td></tr>"
	toBeReturned += "<tr><td>Temp</td><td>#{dutTemp[0]}C</td></tr>"
	toBeReturned += "<tr><td>Current</td><td>###A</td></tr>"
	toBeReturned += "</table>"
	return toBeReturned
	# End of 'CreateDutCell("S20",dut20[2])'
end

get '/about' do
	'A little about me.'
end

get '/form' do 
	erb :form
end

post '/form' do
	begin
		str = "
	<script type=\"text/javascript\">
	function loadXMLDoc()
	{
		var xmlhttp;
		if (window.XMLHttpRequest)
		{
			// code for IE7+, Firefox, Chrome, Opera, Safari
			xmlhttp=new XMLHttpRequest();
		}
		else
		{
			// code for IE6, IE5
			xmlhttp=new ActiveXObject(\"Microsoft.XMLHTTP\");
		}

		xmlhttp.onreadystatechange=function()
		{
			if (xmlhttp.readyState==4 && xmlhttp.status==200)
			{
				document.getElementById(\"myDiv\").innerHTML=xmlhttp.responseText;
			}
		}	
		xmlhttp.open(\"POST\",\"../form\",true);
		xmlhttp.send();
	}
	</script>

	<div id=\"myDiv\">
        		"
		db = SQLite3::Database.open "latest.db"
		db.results_as_hash = true

		ary = db.execute "SELECT * FROM latest where idData = 1"    
		asdf = []
		ary.each do |row|				
			dut0 = row['slotData'].partition("|")
			dut1 = dut0[2].partition("|")
			dut2 = dut1[2].partition("|")
			dut3 = dut2[2].partition("|")
			dut4 = dut3[2].partition("|")
			dut5 = dut4[2].partition("|")
			dut6 = dut5[2].partition("|")
			dut7 = dut6[2].partition("|")
			dut8 = dut7[2].partition("|")
			dut9 = dut8[2].partition("|")
			dut10 = dut9[2].partition("|")
			dut11 = dut10[2].partition("|")
			dut12 = dut11[2].partition("|")
			dut13 = dut12[2].partition("|")
			dut14 = dut13[2].partition("|")
			dut15 = dut14[2].partition("|")
			dut16 = dut15[2].partition("|")
			dut17 = dut16[2].partition("|")
			dut18 = dut17[2].partition("|")
			dut19 = dut18[2].partition("|")
			dut20 = dut19[2].partition("|")
			dut21 = dut20[2].partition("|")
			dut22 = dut21[2].partition("|")
			dut23 = dut22[2].partition("|")

			str += 	"#{Time.at(row['slotTime']).inspect}"
			str += 	"<table border=\"1\">"
			str += 	"<tr>"
			str += 	"<td>"+CreateDutCell("S20",dut20)+"</td>"
			str += 	"<td>"+CreateDutCell("S16",dut16)+"</td>"
			str += 	"<td>"+CreateDutCell("S12",dut12)+"</td>"
			str += 	"<td>"+CreateDutCell("S8",dut8)+"</td>"
			str += 	"<td>"+CreateDutCell("S4",dut4)+"</td>"
			str += 	"<td>"+CreateDutCell("S0",dut0)+"</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>"+CreateDutCell("S21",dut21)+"</td>"
			str += 	"<td>"+CreateDutCell("S17",dut17)+"</td>"
			str += 	"<td>"+CreateDutCell("S13",dut13)+"</td>"
			str += 	"<td>"+CreateDutCell("S9",dut9)+"</td>"
			str += 	"<td>"+CreateDutCell("S5",dut5)+"</td>"
			str += 	"<td>"+CreateDutCell("S1",dut1)+"</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>"+CreateDutCell("S22",dut22)+"</td>"
			str += 	"<td>"+CreateDutCell("S18",dut18)+"</td>"
			str += 	"<td>"+CreateDutCell("S14",dut14)+"</td>"
			str += 	"<td>"+CreateDutCell("S10",dut10)+"</td>"
			str += 	"<td>"+CreateDutCell("S6",dut6)+"</td>"
			str += 	"<td>"+CreateDutCell("S2",dut2)+"</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>"+CreateDutCell("S23",dut23)+"</td>"
			str += 	"<td>"+CreateDutCell("S19",dut19)+"</td>"
			str += 	"<td>"+CreateDutCell("S15",dut15)+"</td>"
			str += 	"<td>"+CreateDutCell("S11",dut11)+"</td>"
			str += 	"<td>"+CreateDutCell("S7",dut7)+"</td>"
			str += 	"<td>"+CreateDutCell("S3",dut4)+"</td>"
			str += 	"</tr>"
			str += 	"</table>"
		end

		rescue SQLite3::Exception => e 
		    puts "Exception occured"
		    puts e

		ensure
		    db.close if db
		
	end
	str += "</div>	
	<script type=\"text/javascript\">
	setInterval(function(){loadXMLDoc()},10000); # 5000 = 5 seconds
	</script>
	"
end

