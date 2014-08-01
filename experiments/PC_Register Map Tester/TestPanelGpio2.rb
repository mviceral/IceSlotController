# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'rubygems'
require 'sinatra'
# require 'sqlite3'
require_relative "GpioTestPanel_common"
require 'json'
require_relative '../BBB_Shared Memory for GPIO2 Ruby/SharedMemoryGPIO2'
require_relative '../BBB_GPIO2 Interface Ruby/GPIO2'

set :port, 4568
set :sharedMem, ""
set :tpg, TestPanelGui.new("#00ffbb","#99ffbb","#ccaa33","#cccc33",GPIO2.new)
def uiTest
	ui = "
	<html>
		<body>
			<form action=\"/\" method=\"POST\">
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
					var idOfHexLabel = idOfRow.concat(\"lbl\");
					var idOfHiddenInput = \"hdn\";
					idOfHiddenInput = idOfHiddenInput.concat(idOfRow);
					var hiddenField = document.getElementById(idOfHiddenInput);		
					var myTextField = document.getElementById(idOfHexLabel);		
					hiddenField.value = whatIsChecked
					myTextField.innerHTML = whatIsChecked.toString(16).toUpperCase();
					if (myTextField.innerHTML.length<2)
						myTextField.innerHTML = \"0x0\"+myTextField.innerHTML;
					else
						myTextField.innerHTML = \"0x\"+myTextField.innerHTML;
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
						ui += settings.tpg.readItemBit("0x00","SLOTADDR","SLOT1|SLOT0|SYS5|SYS4|SYS3|SYS2|SYS1|SYS0")
						ui += settings.tpg.testItemBit("0x00","RESET_ALL","RST")	
						ui += settings.tpg.testItemBit("0x01","STAT_LED","LEDEN| | | |LED3|LED2|LED1|LED0")	
						ui += settings.tpg.testItemBit("0x02","WXT_CLEAR_LATCH","CLEAR")
						ui += settings.tpg.readItemBit(
							"0x02",
							"EXT_INPUTS","FANT2B|FANT2A|FANT1B|FANT1A|SENSR2|SENSR1|USRSW2|USRSW1")
						ui += settings.tpg.testItemBit("0x03","PS_ENABLE","P12V|N5V|P5V|PS6|PS8|PS9|PS10")	
						ui += settings.tpg.testItemBit("0x04","SL_CNTL_EXT","POWER| |FAN1|FAN2|BUZR|LEDRED|LEDYEL|LEDGRN")	
						ui += settings.tpg.testItemByte("0x05","SL_FAN_PWM","PWM7|PWM6|PWM5|PWM4|PWM3|PWM2|PWM1|PWM0")
						ui += settings.tpg.readItemBit("0x06","ETS_ALM1","ALM7|ALM6|ALM5|ALM4|ALM3|ALM2|ALM1|ALM0")
						ui += settings.tpg.readItemBit("0x07","ETS_ALM2","ALM15|ALM14|ALM13|ALM12|ALM11|ALM10|ALM9|ALM8")
						ui += settings.tpg.readItemBit("0x08","ETS_ALM2","ALM23|ALM22|ALM21|ALM20|ALM19|ALM18|ALM17|ALM16")
						ui += settings.tpg.testItemBit("0x09","ETS_ENA1","ETS7|ETS6|ETS5|ETS4|ETS3|ETS2|ETS1|ETS0")
						ui += settings.tpg.testItemBit("0x0A","ETS_ENA2","ETS15|ETS14|ETS13|ETS12|ETS11|ETS10|ETS9|ETS8")
						ui += settings.tpg.testItemBit("0x0B","ETS_ENA3","ETS23|ETS22|ETS21|ETS20|ETS19|ETS18|ETS17|ETS16")
						ui += settings.tpg.testItemByte("0x0C","ETS_RX_SEL","RXMUX4|RXMUX3|RXMUX2|RXMUX1|RXMUX0")
						ui += settings.tpg.testItemByte("0x0D","ANA_MEAS4_SEL","ANAMUX5|ANAMUX4|ANAMUX3|ANAMUX2|ANAMUX1|ANAMUX0")
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
			</form>
		</body>
	</html>
	"

	return ui
end

post '/' do
	settings.sharedMem = ""
	if params[:_0x00] == "Update"
		# settings.sharedMem += "0x00 : Hex value = '#{params[:hdn0x00]}'"
		settings.tpg.gpio2.setGPIO2(0x00.to_i,params[:hdn0x00])
	elsif params[:_0x01] == "Update"
		settings.sharedMem += "0x01 : Hex value = '#{params[:hdn0x01]}'"
		settings.tpg.gpio2.setGPIO2(0x01.to_i,params[:hdn0x01])
	elsif params[:_0x02] == "Update"
		# settings.sharedMem += "0x02 : Hex value = '#{params[:hdn0x02]}'"
		settings.tpg.gpio2.setGPIO2(0x02.to_i,params[:hdn0x02])
	elsif params[:_0x03] == "Update"
		# settings.sharedMem += "0x03 : Hex value = '#{params[:hdn0x03]}'"
		settings.tpg.gpio2.setGPIO2(0x03.to_i,params[:hdn0x03])
	elsif params[:_0x04] == "Update"
		# settings.sharedMem += "0x04 : Hex value = '#{params[:hdn0x04]}'"
		settings.tpg.gpio2.setGPIO2(0x04.to_i,params[:hdn0x04])
	elsif params[:_0x05] == "Update"
		# settings.sharedMem += "0x05 : Hex value = '#{params[:hdn0x05]}'"
		settings.tpg.gpio2.setGPIO2(0x05.to_i,params[:hdn0x05])
	elsif params[:_0x06] == "Update"
		# settings.sharedMem += "0x06 : Hex value = '#{params[:hdn0x06]}'"
		settings.tpg.gpio2.setGPIO2(0x06.to_i,params[:hdn0x06])
	elsif params[:_0x07] == "Update"
		# settings.sharedMem += "0x07 : Hex value = '#{params[:hdn0x07]}'"
		settings.tpg.gpio2.setGPIO2(0x07.to_i,params[:hdn0x07])
	elsif params[:_0x08] == "Update"
		# settings.sharedMem += "0x08 : Hex value = '#{params[:hdn0x08]}'"
		settings.tpg.gpio2.setGPIO2(0x08.to_i,params[:hdn0x08])
	elsif params[:_0x09] == "Update"
		# settings.sharedMem += "0x09 : Hex value = '#{params[:hdn0x09]}'"
		settings.tpg.gpio2.setGPIO2(0x09.to_i,params[:hdn0x09])
	elsif params[:_0x0A] == "Update"
		# settings.sharedMem += "0x0A : Hex value = '#{params[:hdn0x0A]}'"
		settings.tpg.gpio2.setGPIO2(0x0A.to_i,params[:hdn0x0A])
	elsif params[:_0x0B] == "Update"
		# settings.sharedMem += "0x0B : Hex value = '#{params[:hdn0x0B]}'"
		settings.tpg.gpio2.setGPIO2(0x0B.to_i,params[:hdn0x0B])
	end	
	# settings.sharedMem += "Contented of shared memory: '#{parsed.to_json}'"
	settings.sharedMem += uiTest
	settings.tpg.resetRowCount
	uiDisplay = "#{settings.sharedMem}"
end

get '/' do
	uiDisplay = uiTest
end

get '/about' do
	'A little about me.'
end

get '/form' do	
	uiDisplay = "A You said '#{params[:submit]}'" + uiTest
end

post '/form' do	
	uiDisplay = "B You said '#{params[:submit]}'" + uiTest
end

