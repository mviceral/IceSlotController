# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require_relative "GpioTestPanel_common"
set :port, 4568

def uiTest
	tpg = TestPanelGui.new("#998899","#996699","#3399ff","#33BBff")
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
		<table>
			<tr><td>&nbsp;</td><td><center><font size=\"3\">Emulator Test Panel</font></center></td><td>&nbsp;</td></tr>
			<tr><td>&nbsp;</td><td><table id=\"main\" width=\"100%\" style=\"border: 1px solid black;\">
			<tr id=\"main\">
				<td id=\"main\" width=\"5%\" ><center><font size=\"1\">Addr</font></center></td>
				<td id=\"main\" width=\"5%\" ><center><font size=\"1\">Name</font></center></td>
				<td id=\"main\" width=\"5%\" ></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 7</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 6</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 5</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 4</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 3</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 2</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 1</font></center></td>
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">Bit 0</font></center></td>			
				<td id=\"main\" width=\"3%\" ><center><font size=\"1\">HEX</font></center></td>			
			</tr>"
			ui += tpg.testItemByte("0x00","SLOTADDR","SLOT1|SLOT0|SYS5|SYS4|SYS3|SYS2|SYS1|SYS0")
			ui += tpg.readItemBit("0x00","RESET_ALL","RST")	
			ui += tpg.readItemBit("0x01","STAT_LED","LEDEN| | | |LED3|LED2|LED1|LED0")	
			ui += tpg.readItemBit("0x02","WXT_CLEAR_LATCH","CLEAR")
			ui += tpg.testItemBit("0x02","EXT_INPUTS","FANT2B|FANT2A|FANT1B|FANT1A|SENSR2|SENSR1|USRSW2|USRSW1")
			ui += tpg.readItemBit("0x03","PS_ENABLE","P12V|N5V|P5V|PS6|PS8|PS9|PS10")	
			ui += tpg.readItemBit("0x04","SL_CNTL_EXT","POWER| |FAN1|FAN2|BUZR|LEDRED|LEDYEL|LEDGRN")	
			ui += tpg.readItemBit("0x05","SL_FAN_PWM","PWM7|PWM6|PWM5|PWM4|PWM3|PWM2|PWM1|PWM0")
			ui += tpg.testItemBit("0x06","ETS_ALM1","ALM7|ALM6|ALM5|ALM4|ALM3|ALM2|ALM1|ALM0")
			ui += tpg.testItemBit("0x07","ETS_ALM2","ALM15|ALM14|ALM13|ALM12|ALM11|ALM10|ALM9|ALM8")
			ui += tpg.testItemBit("0x08","ETS_ALM2","ALM23|ALM22|ALM21|ALM20|ALM19|ALM18|ALM17|ALM16")
			ui += tpg.readItemBit("0x09","ETS_ENA1","ETS7|ETS6|ETS5|ETS4|ETS3|ETS2|ETS1|ETS0")
			ui += tpg.readItemBit("0x0A","ETS_ENA2","ETS15|ETS14|ETS13|ETS12|ETS11|ETS10|ETS9|ETS8")
			ui += tpg.readItemBit("0x0B","ETS_ENA3","ETS23|ETS22|ETS21|ETS20|ETS19|ETS18|ETS17|ETS16")
			ui += tpg.readItemBit("0x0C","ETS_RX_SEL","RXMUX4|RXMUX3|RXMUX2|RXMUX1|RXMUX0")
			ui += tpg.readItemBit("0x0D","ANA_MEAS4_SEL","ANAMUX5|ANAMUX4|ANAMUX3|ANAMUX2|ANAMUX1|ANAMUX0")
			ui += 
		"</table></td><td>&nbsp;</td></tr>			
			<tr><td>&nbsp;</td></tr>
		</table>
	"
	ui += ""
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

