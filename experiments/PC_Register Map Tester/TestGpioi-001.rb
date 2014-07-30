# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'rubygems'
require 'sinatra'
require 'sqlite3'

set :cellWidth,  95
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
			<td><center/>Input</td><td>GPIO Values</td>
			<td>Effect after GPIO Update (user input or emulator)</td>
		</tr>
		
		<tr>
			<td width=\"5%\" rowspan=\"2\" valign=\"bottom\"><button type=\"button\">Update</button><td rowspan=\"2\" valign=\"bottom\"><center>SlotAddr</center></td>
			<td width=\"15%\">"+makeVertical("SLOT1")+"</td><td/><td rowspan=\"2\"/>
		</tr>
		
		<tr>
			<td><input type=\"text\" name=\"pin\" maxlength=\"4\" size=\"4\"></td>
			<td/>
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

