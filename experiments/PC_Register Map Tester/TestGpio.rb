# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'rubygems'
require 'sinatra'
require 'sqlite3'

set :rowNumber,  0
set :rowColor,  0
set :gpioRowColor,  0
set :readRowColor,  0

def getRowNUmber
	settings.rowNumber += 1
	return settings.rowNumber
end

def byteType
	return 2
end

def bitType
	return 1
end

def getBitLables(strParam)
	pieces = ""
	totalBits = 0
	while strParam.index('|') != nil
		totalBits+=1
		at = strParam.index('|')
		toAdd = strParam[0..(at-1)]
		pieces += "<td id=\"main\"><center><font size=\"1\">#{toAdd}</font></center></td>"

		at += 1
		strParam = strParam[at..-1]
	end
	
	pieces += "<td id=\"main\"><center><font size=\"1\">#{strParam}</font?</center></td>"
	totalBits += 1
	
	# Fill the rest of the bits.
	while totalBits<8
		totalBits+=1
		pieces = "<td id=\"main\"><center>&nbsp;</center></td>"+pieces
	end
	return pieces	
	# End of def getBitLables
end

def testItemByte(addrParam,bitLabelsParam)
	if getRowNUmber() % 2 == 0
		settings.rowColor = "#33ddaa"
		# settings.gpioRowColor = "#66ffaa"
		settings.gpioRowColor = settings.rowColor
	else
		settings.rowColor = "#99bb33"
		#settings.gpioRowColor = "#33ddff"
		settings.gpioRowColor = settings.rowColor
	end
	testItemBit_tbr = "" # tbr - to be returned	
	testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{settings.rowColor}\">
			<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
			<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><button type=\"button\" style=\"height:20px; width:50px; font-size:10px\">Update</button></center></td>"
	testItemBit_tbr += getBitLables(bitLabelsParam)
	testItemBit_tbr += "
			<td id=\"main\"><center></center></td>			
		</tr>
		<tr id=\"main\" bgcolor=\"#{settings.rowColor}\">
			<td id=\"main\"><center><input type=\"radio\" name=\"x007\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x006\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x005\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x003\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x002\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x001\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x000\" disabled></center></td>
			<td id=\"main\"><center><input type=\"text\" id=\"text\" name=\"text_name\" style=\"height:20px; width:50px; font-size:10px\" /></center></td>			
		</tr>
		<tr id=\"main\" bgcolor=\"#{settings.gpioRowColor}\">
			<td id=\"main\"><center><font size=\"1\">GPIO</font></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x007\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x006\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x005\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x003\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x002\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x001\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x000\" disabled></center></td>
			<td id=\"main\"><center><font size=\"1\">0x1</font></center></td>			
		</tr>"
end

def readItemBit(addrParam,bitLabelsParam)
	settings.rowColor = "#3399cc"
	# settings.gpioRowColor = "#66ffaa"
	settings.gpioRowColor = settings.rowColor
	testItemBit_tbr = "" # tbr - to be returned	
	testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{settings.rowColor}\">
			<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
			<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">GPIO</font></center></td>"
	testItemBit_tbr += getBitLables(bitLabelsParam)
	testItemBit_tbr += "
			<td id=\"main\"><center></center></td>			
		</tr>
		<tr id=\"main\" bgcolor=\"#{settings.gpioRowColor}\">
			
			<td id=\"main\"><center><input type=\"radio\" name=\"x007\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x006\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x005\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x003\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x002\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x001\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x000\" disabled></center></td>
			<td id=\"main\"><center><font size=\"1\">0x1</font></center></td>			
		</tr>"
end

def testItemBit(addrParam,bitLabelsParam)
	if getRowNUmber() % 2 == 0
		settings.rowColor = "#33ddaa"
		# settings.gpioRowColor = "#66ffaa"
		settings.gpioRowColor = settings.rowColor
	else
		settings.rowColor = "#99bb33"
		#settings.gpioRowColor = "#33ddff"
		settings.gpioRowColor = settings.rowColor
	end
	testItemBit_tbr = "" # tbr - to be returned	
	testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{settings.rowColor}\">
			<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
			<td id=\"main\" rowspan=\"2\" valign=\"center\">
				<center>
					<button type=\"button\" style=\"height:20px; width:50px; font-size:10px\">Update</button></button></center></td>"
	testItemBit_tbr += getBitLables(bitLabelsParam)
	testItemBit_tbr += "
			<td id=\"main\"><center></center></td>			
		</tr>
		<tr id=\"main\" bgcolor=\"#{settings.rowColor}\">
			<td id=\"main\"><center><input type=\"radio\" name=\"x007\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x006\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x005\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x004\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x003\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x002\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x001\"></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x000\"></center></td>
			<td id=\"main\"><center><font size=\"1\">0x1</font></center></td>			
		</tr>
		<tr id=\"main\" bgcolor=\"#{settings.gpioRowColor}\">
			<td id=\"main\"><center><font size=\"1\">GPIO</font></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x007\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x006\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x005\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x003\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x002\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x001\" disabled></center></td>
			<td id=\"main\"><center><input type=\"radio\" name=\"x000\" disabled></center></td>
			<td id=\"main\"><center><font size=\"1\">0x1</font></center></td>			
		</tr>"
end
def uiTest
	settings.rowNumber = 3
	ui = "
	<style>
	table#main {
		  border-collapse: collapse;
	}

	table#main, td#main, th#main {
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
	<table id=\"main\" width=\"100%\" style=\"border: 1px solid black;\">
		<tr id=\"main\">
			<td id=\"main\" width=\"5%\" ></td>
			<td id=\"main\" width=\"5%\" ></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">7</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">6</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">5</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">4</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">3</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">2</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">1</font></center></td>
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">0</font></center></td>			
			<td id=\"main\" width=\"3%\" ><center><font size=\"1\">HEX</font></center></td>			
		</tr>"
		ui += readItemBit("0x00 SLOTADDR","SLOT1|SLOT0|SYS5|SYS4|SYS3|SYS2|SYS1|SYS0")
		ui += testItemBit("0x00 RESET_ALL","RST")	
		ui += testItemBit("0x01 STAT_LED","LEDEN| | | |LED3|LED2|LED1|LED0")	
		ui += testItemBit("0x02 WXT_CLEAR_LATCH","CLEAR")
		ui += readItemBit("0x02 EXT_INPUTS","FANT2B|FANT2A|FANT1B|FANT1A|SENSR2|SENSR1|USRSW2|USRSW1")
		ui += testItemBit("0x03 PS_ENABLE","P12V|N5V|P5V|PS6|PS8|PS9|PS10")	
		ui += testItemBit("0x04 SL_CNTL_EXT","POWER| |FAN1|FAN2|BUZR|LEDRED|LEDYEL|LEDGRN")	
		ui += testItemByte("0x05 SL_FAN_PWM","PWM7|PWM6|PWM5|PWM4|PWM3|PWM2|PWM1|PWM0")
		ui += readItemBit("0x06 ETS_ALM1","ALM7|ALM6|ALM5|ALM4|ALM3|ALM2|ALM1|ALM0")
		ui += readItemBit("0x07 ETS_ALM2","ALM15|ALM14|ALM13|ALM12|ALM11|ALM10|ALM9|ALM8")
		ui += readItemBit("0x08 ETS_ALM2","ALM23|ALM22|ALM21|ALM20|ALM19|ALM18|ALM17|ALM16")
		ui += testItemBit("0x09 ETS_ENA1","ETS7|ETS6|ETS5|ETS4|ETS3|ETS2|ETS1|ETS0")
		ui += testItemBit("0x0A ETS_ENA2","ETS15|ETS14|ETS13|ETS12|ETS11|ETS10|ETS9|ETS8")
		ui += testItemBit("0x0B ETS_ENA3","ETS23|ETS22|ETS21|ETS20|ETS19|ETS18|ETS17|ETS16")
		ui += testItemByte("0x0C ETS_RX_SEL","RXMUX4|RXMUX3|RXMUX2|RXMUX1|RXMUX0")
		ui += testItemByte("0x0D ANA_MEAS4_SEL","ANAMUX5|ANAMUX4|ANAMUX3|ANAMUX2|ANAMUX1|ANAMUX0")
		ui += 
	"</table>
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

