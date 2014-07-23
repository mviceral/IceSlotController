require 'rubygems'
require 'sinatra'
require 'sqlite3'

set :cellWidth,  95

def SlotCell(temp1Param, temp2Param)
	toBeReturned = "<table bgcolor=\"#ffaa77\" width=\"#{settings.cellWidth}\">"
	toBeReturned += "<tr><td><font size=\"1\">SLOT</font></td></tr>"
	toBeReturned += "<tr><td><font size=\"1\">TEMP1</font></td><td><font size=\"1\">#{temp1Param}C</font></td></tr>"
	toBeReturned += "<tr><td><font size=\"1\">TEMP2</font></td><td><font size=\"1\">#{temp2Param}C</font></td></tr>"
	toBeReturned += "</table>"
	return toBeReturned
	# End of 'DutCell("S20",dut20[2])'
end

def PNPCell(posVolt, negVolt, largeVolt)
	toBeReturned = "<table bgcolor=\"#6699aa\" width=\"#{settings.cellWidth}\">"
	toBeReturned += "<tr><td><font size=\"1\">P5V</font></td><td><font size=\"1\">#{posVolt}V</font></td></tr>"
	toBeReturned += "<tr><td><font size=\"1\">N5V</font></td><td><font size=\"1\">#{negVolt}V</font></td></tr>"
	toBeReturned += "<tr><td><font size=\"1\">P12V</font></td><td><font size=\"1\">#{largeVolt}V</font></td></tr>"
	toBeReturned += "</table>"
	return toBeReturned
	# End of 'DutCell("S20",dut20[2])'
end

def PsCell(labelParam,rawDataParam)
	rawDataParam = rawDataParam[0].partition("@")
	isRunning = rawDataParam[2].partition(",")
	ambientTemp = isRunning[2].partition(",")
	dutTemp = ambientTemp[2].partition(",")
	toBeReturned = "<table bgcolor=\"#6699aa\" width=\"#{settings.cellWidth}\">"
	toBeReturned += "<tr><td><font size=\"1\">"+labelParam+"</font></td></tr>"
	toBeReturned += "<tr>"
	if labelParam == "S8"
		bgcolor = "bgcolor=\"#ff0000\""
	else
		bgcolor = ""
	end
	toBeReturned += "	<td #{bgcolor} ><font size=\"1\">Voltage</font></td><td #{bgcolor} ><font size=\"1\">#{dutTemp[0]}V</font></td>"
	toBeReturned += "</tr>"
	toBeReturned += "<tr><td><font size=\"1\">Current</font></td><td><font size=\"1\">###A</font></td></tr>"
	toBeReturned += "</table>"
	return toBeReturned
	# End of 'DutCell("S20",dut20[2])'
end

def DutCell(labelParam,rawDataParam)
	rawDataParam = rawDataParam[0].partition("@")
	isRunning = rawDataParam[2].partition(",")
	ambientTemp = isRunning[2].partition(",")
	dutTemp = ambientTemp[2].partition(",")
	toBeReturned = "<table bgcolor=\"#99bb11\" width=\"#{settings.cellWidth}\">"
	toBeReturned += "<tr><td><font size=\"1\">"+labelParam+"</font></td></tr>"
	toBeReturned += "<tr>"
	if labelParam == "S8"
		bgcolor = "bgcolor=\"#ff0000\""
	else
		bgcolor = ""
	end
	toBeReturned += "	<td #{bgcolor} ><font size=\"1\">Temp</font></td><td #{bgcolor} ><font size=\"1\">#{dutTemp[0]}C</font></td>"
	toBeReturned += "</tr>"
	toBeReturned += "<tr><td><font size=\"1\">Current</font></td><td><font size=\"1\">###A</font></td></tr>"
	toBeReturned += "</table>"
	return toBeReturned
	# End of 'DutCell("S20",dut20[2])'
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
	<style>
	#slotA
	{
	border:1px solid black;
	border-collapse:collapse;
	}
	</style>
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

			str += 	"<table style=\"border-collapse : collapse; border : 1px solid black;\"  bgcolor=\"#000000\">"
			str += 	"<tr>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S20",dut20)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S16",dut16)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S12",dut12)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S8",dut8)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S4",dut4)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S0",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS0",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS4",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS8",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("5V",dut0)+"</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S21",dut21)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S17",dut17)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S13",dut13)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S9",dut9)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S5",dut5)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S1",dut1)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS1",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS5",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS9",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("12V",dut0)+"</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S22",dut22)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S18",dut18)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S14",dut14)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S10",dut10)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S6",dut6)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S2",dut2)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS2",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS6",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS10",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("24V",dut0)+"</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S23",dut23)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S19",dut19)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S15",dut15)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S11",dut11)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S7",dut7)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S3",dut4)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS3",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS7",dut0)+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PNPCell("5.01","-5.10","12.24")+"</td>"
			str += 	"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+SlotCell("55.5","45.5")+"</td>"
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
	setInterval(function(){loadXMLDoc()},10000); 
	</script>
	"
end

