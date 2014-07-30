# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'rubygems'
require 'sinatra'
require 'sqlite3'

set :cellWidth,  95
def getBitInputs(strParam)
	pieces = ""
	totalBits = 0
	while strParam.index('|') != nil
		totalBits+=1
		at = strParam.index('|')
		toAdd = strParam[0..(at-1)]
		pieces += "<td><input type=\"radio\" name=\""+toAdd+"\" value=\"1\"></td>"
		at += 1
		strParam = strParam[at..-1]
	end
	
	pieces += "<td><input type=\"radio\" name=\""+strParam+"\" value=\"1\"></td>"
	totalBits += 1
	
	# Fill the rest of the bits.
	while totalBits<8
		totalBits+=1
		pieces = "<td valign=\"BOTTOM\"><input type=\"radio\" disabled></td>"+pieces
	end
	return pieces	
	# End of def getBitLables
end

def getBitLables(strParam)
	pieces = ""
	totalBits = 0
	while strParam.index('|') != nil
		totalBits+=1
		at = strParam.index('|')
		toAdd = strParam[0..(at-1)]
		pieces += "<td><center>"+makeVertical(toAdd)+"</center></td>"
		at += 1
		strParam = strParam[at..-1]
	end
	
	pieces += "<td><center>"+makeVertical(strParam)+"</center></td>"
	totalBits += 1
	
	# Fill the rest of the bits.
	while totalBits<8
		totalBits+=1
		pieces = "<td valign=\"BOTTOM\">&nbsp;</td>"+pieces
	end
	return pieces	
	# End of def getBitLables
end

def bitInput(strParam)
	bitLabels = getBitLables(strParam)
	bitInput = getBitInputs(strParam)
	bitInput_tbr = "" # tbr - to be returned
	bitInput_tbr += "
		<table>
			<tr>
				"+bitLabels+"
			</tr>
			<tr>
				"+bitInput+"
			</tr>
		</table>"
	# End of def bitInput
end
def makeVertical (textParam)
	makeVertical_tbr = ""
	ct = 0
	while ct < textParam.length
		makeVertical_tbr += "<span><font size=\"1\" style=\"display: block;\">" +textParam[ct]+ "</font></span>"
		ct += 1
	end
	return makeVertical_tbr
end
def uiTest
	ui = "
	<style>
	table {
		  border-collapse: collapse;
	}

	table, td, th {
		  border: 1px solid black;
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
	<center>
	<table width=\"100%\" style=\"border: 1px solid black;\">
		<tr style=\"border: 1px solid black;\">
			<td colspan=\"5\"><center>Application</center></td>
		</tr>
		
		<tr>
			<td width=\"5%\"></td>
			<td width=\"15%\" valign=\"2\"><center/>Register</td>
			<td><center/>Input</td><td><center>GPIO Values</center></td>
			<td><center>Effect after GPIO Update (user input or emulator)</center></td>
		</tr>
		
		<tr>
			<td width=\"5%\" rowspan=\"2\" valign=\"center\"><button type=\"button\">Update</button></td>
			<td rowspan=\"2\" valign=\"center\"><center>PS_ENABLE</center></td>
			<td rowspan=\"2\" width=\"15%\">"+bitInput("P12V|N5V|P5V|PS6|PS8|PS9|PS10")+"</td><td/><td rowspan=\"2\"/>
		</tr>
		
		<tr>			
			<td/><!--GPIO Value-->
		</tr>
	</table>
        		"
	ui += "</div>	
	</center>
	<script type=\"text/javascript\">
	setInterval(function(){loadXMLDoc()},10000); 
	</script>
	"

	return ui
end


get '/about' do
	'A little about me.'
end

get '/form' do 
	uiDisplay = uiTest
end

post '/form' do
	uiDisplay = uiTest
end

