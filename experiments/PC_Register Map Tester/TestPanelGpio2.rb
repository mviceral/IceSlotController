# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require_relative "GpioTestPanel_common"
set :port, 4567
def uiTest
	tpg = TestPanelGui.new("#00ffbb","#99ffbb","#ccaa33","#cccc33")
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
	function toggleCheckbox(element)
	{
		// alert('element.name.length='+element.name.length+'');
		//int hold = element.name.length-1;
		var idOfRow = element.name.substring(0, element.name.length-1);
		// var idOfRow=\"asdf\";
		// alert('Checkbox got pressed.  element.name='+element.name+'.  idOfRow='+idOfRow+'');
		var id0 = idOfRow.concat(\"0\");
		var id1 = idOfRow.concat(\"1\");
		var id2 = idOfRow.concat(\"2\");
		var id3 = idOfRow.concat(\"3\");
		var id4 = idOfRow.concat(\"4\");
		var id5 = idOfRow.concat(\"5\");
		var id6 = idOfRow.concat(\"6\");
		var id7 = idOfRow.concat(\"7\");
		var checkBox0 = document.getElementsByName(id0);
		var checkBox1 = document.getElementsByName(id1);
		var checkBox2 = document.getElementsByName(id2);
		var checkBox3 = document.getElementsByName(id3);
		var checkBox4 = document.getElementsByName(id4);
		var checkBox5 = document.getElementsByName(id5);
		var checkBox6 = document.getElementsByName(id6);
		var checkBox7 = document.getElementsByName(id7);
		/*
		alert(''+checkBox7[0].checked+','
						+checkBox6[0].checked+','
						+checkBox5[0].checked+','
						+checkBox4[0].checked+','
						+checkBox3[0].checked+','
						+checkBox2[0].checked+','
						+checkBox1[0].checked+','
						+checkBox0[0].checked);
		*/
		var whatIsChecked = 0;
		if (checkBox7[0].checked)						
			whatIsChecked += 128;
		if (checkBox6[0].checked)						
			whatIsChecked += 64;
		if (checkBox5[0].checked)						
			whatIsChecked += 32;
		if (checkBox4[0].checked)						
			whatIsChecked += 16;
		if (checkBox3[0].checked)						
			whatIsChecked += 8;
		if (checkBox2[0].checked)						
			whatIsChecked += 4;
		if (checkBox1[0].checked)						
			whatIsChecked += 2;
		if (checkBox0[0].checked)						
			whatIsChecked += 1;
		var myTextField = document.getElementById(idOfRow);		
		myTextField.innerHTML = \"0x\"+whatIsChecked.toString(16).toUpperCase();
		// myTextField.value = \"Hello World\";
		// alert(\"Checkbox got pressed.  element.name=\"+element.name+\".  idOfRow=\"+idOfRow+\"\");
	}
	</script>

	<div id=\"myDiv\">
	<center>
		<table>
			<tr><td>&nbsp;</td><td><center><font size=\"3\">Application Test Panel</font></center></td><td>&nbsp;</td></tr>
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
			ui += tpg.readItemBit("0x00","SLOTADDR","SLOT1|SLOT0|SYS5|SYS4|SYS3|SYS2|SYS1|SYS0")
			ui += tpg.testItemBit("0x00","RESET_ALL","RST")	
			ui += tpg.testItemBit("0x01","STAT_LED","LEDEN| | | |LED3|LED2|LED1|LED0")	
			ui += tpg.testItemBit("0x02","WXT_CLEAR_LATCH","CLEAR")
			ui += tpg.readItemBit("0x02","EXT_INPUTS","FANT2B|FANT2A|FANT1B|FANT1A|SENSR2|SENSR1|USRSW2|USRSW1")
			ui += tpg.testItemBit("0x03","PS_ENABLE","P12V|N5V|P5V|PS6|PS8|PS9|PS10")	
			ui += tpg.testItemBit("0x04","SL_CNTL_EXT","POWER| |FAN1|FAN2|BUZR|LEDRED|LEDYEL|LEDGRN")	
			ui += tpg.testItemByte("0x05","SL_FAN_PWM","PWM7|PWM6|PWM5|PWM4|PWM3|PWM2|PWM1|PWM0")
			ui += tpg.readItemBit("0x06","ETS_ALM1","ALM7|ALM6|ALM5|ALM4|ALM3|ALM2|ALM1|ALM0")
			ui += tpg.readItemBit("0x07","ETS_ALM2","ALM15|ALM14|ALM13|ALM12|ALM11|ALM10|ALM9|ALM8")
			ui += tpg.readItemBit("0x08","ETS_ALM2","ALM23|ALM22|ALM21|ALM20|ALM19|ALM18|ALM17|ALM16")
			ui += tpg.testItemBit("0x09","ETS_ENA1","ETS7|ETS6|ETS5|ETS4|ETS3|ETS2|ETS1|ETS0")
			ui += tpg.testItemBit("0x0A","ETS_ENA2","ETS15|ETS14|ETS13|ETS12|ETS11|ETS10|ETS9|ETS8")
			ui += tpg.testItemBit("0x0B","ETS_ENA3","ETS23|ETS22|ETS21|ETS20|ETS19|ETS18|ETS17|ETS16")
			ui += tpg.testItemByte("0x0C","ETS_RX_SEL","RXMUX4|RXMUX3|RXMUX2|RXMUX1|RXMUX0")
			ui += tpg.testItemByte("0x0D","ANA_MEAS4_SEL","ANAMUX5|ANAMUX4|ANAMUX3|ANAMUX2|ANAMUX1|ANAMUX0")
			ui += 
		"</table></td><td>&nbsp;</td></tr>
			<tr>
				<td>&nbsp;</td><td><center><table id=\"main\"><tr id=\"main\" bgcolor=\"#33dd66\"><td id=\"main\" width=\"10%\"><center><font size=\"2\">App response</font></center></td><td id=\"main\" width=\"90%\"><font size=\"2\">App response sample</font></td></tr></table></center></td><td>&nbsp;</td></tr>
			<tr><td>&nbsp;</td></tr>
		</table>
	"
	ui += ""
	ui += "</div>	
	</center>
	<script type=\"text/javascript\">
	// setInterval(function(){loadXMLDoc()},10000); 
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

