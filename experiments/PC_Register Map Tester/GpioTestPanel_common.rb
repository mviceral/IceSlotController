# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
# require 'singleton'
# require 'forwardable'

require 'json'
require_relative '../PC_SharedMemTestPanel Ruby/SharedMemoryGPIO2'

class TestPanelGui

	def initialize (rC1Param,rC2Param,rCR1Param,rCR2Param, gpio2Param)
		@gpio2 = gpio2Param
		@rowNumber = 3
		@readRowNumber = 3
		@rowColor1 = rC1Param
		@rowColor2 = rC2Param
		@rowColorRead1 = rCR1Param
		@rowColorRead2 = rCR2Param
	end
	
	def getLatestBbbState
		#
		# Get the latest BBB register values.
		# 
		#
		begin
			latestBbbState = RestClient.get "http://192.168.7.2:8000/v1/bbbsetter/"
			#
			# latestBbbState is what you save into the share memory in the PC.
			#
			result = JSON.parse(latestBbbState.to_str)
			registers = result["registers"]
			@sharedGpio2 = SharedMemoryGpio2.new
			@sharedGpio2.WriteData("BbbShared"+registers.to_json)
			readMemory = @sharedGpio2.GetData()
			puts "readMemory = #{readMemory}"
		end
	end	
	
	def javaScript
		tbr = "
				function validateForm() {
					/*
						var theForm = document.forms[\"genericform\"];
						
						var _0x00Input = theForm[\"_0x00\"]
						var _0x05Input = theForm[\"_0x05\"]
						var _0x0CInput = theForm[\"_0x0C\"]
						var _0x0DInput = theForm[\"_0x0D\"]
												
						if ( _0x00Input != undefined && _0x00Input.value == \"Update\") {
							var x00 = parseInt(document.forms[\"genericform\"][\"hdn0x00\"].value);
							if ( (0<=x00 && x00 <=255) == false) {
								alert(\"Register 0x00 must be less that 256.\");
								return false;
							}
						}
						
						if ( _0x05Input != undefined && _0x05Input.value == \"Update\") {
							var x05 = parseInt(document.forms[\"genericform\"][\"hdn0x05\"].value);
							if ( (0<=x05 && x05<=255) == false) {
								alert(\"Register 0x05 must be less that 256.\");
								return false;
							}						
						} 
						
						if ( _0x0CInput != undefined && _0x0CInput.value == \"Update\") {
							var x0C = parseInt(document.forms[\"genericform\"][\"hdn0x0C\"].value);
							if ( (0<=x0C && x0C<=24) == false) {
								alert(\"Register 0x0C must be less that 24.\");
								return false;
							}
						}
						
						if ( _0x0DInput != undefined && _0x0DInput.value == \"Update\") {
							var x0D = parseInt(document.forms[\"genericform\"][\"hdn0x0D\"].value);
							if ( (0<=x0D && x0D<=48) == false) {
								alert(\"Register 0x0C must be less that 48.\");
								return false;
							}
						}						
					*/
						return true;
				}
						
				function checkByteValue(valuePara) {
						if ( valuePara == \"0x00\" ) {
							var x00 = parseInt(document.forms[\"genericform\"][\"hdn0x00\"].value);
							document.getElementById(\"value\").value = x00;
							if ( (0<=x00 && x00 <=255) == false) {
								alert(\"Register 0x00 must be less that 256.\");
								return false;
							}							
						}
						
						if ( valuePara == \"0x05\" ) {
							var x05 = parseInt(document.forms[\"genericform\"][\"hdn0x05\"].value);
							document.getElementById(\"value\").value = x05;
							if ( (0<=x05 && x05<=255) == false) {
								alert(\"Register 0x05 must be less that 256.\");
								return false;
							}						
						} 
						
						if ( valuePara == \"0x0C\" ) {
							var x0C = parseInt(document.forms[\"genericform\"][\"hdn0x0C\"].value);
							document.getElementById(\"value\").value = x0C;
							if ( (0<=x0C && x0C<=24) == false) {
								alert(\"Register 0x0C must be less that 24.\");
								return false;
							}
						}
						
						if ( valuePara == \"0x0D\" ) {
							var x0D = parseInt(document.forms[\"genericform\"][\"hdn0x0D\"].value);
							document.getElementById(\"value\").value = x0D;
							if ( (0<=x0D && x0D<=48) == false) {
								alert(\"Register 0x0D must be less that 48.\");
								return false;
							}
						}						
						document.getElementById(\"addr\").value = valuePara;
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
		"
		return tbr
	end
	
	def resetRowCount
		# This way, the colors will not keep switching every screen upgrade.
		@rowNumber = 3
		@readRowNumber = 3
	end
	
	def gpio2
		return @gpio2
	end
	
	def getRowReadNumber
		@readRowNumber += 1
		return @readRowNumber
	end
	
	def getRowNUmber
		@rowNumber += 1
		return @rowNumber
	end

	def byteType
		return 2
	end

	def bitType
		return 1
	end

	def getBitRadioBtns(addrParam,strParam)
		pieces = ""
		totalBits = 0
		while strParam.rindex('|') != nil
			at = strParam.rindex('|')+1
			toAdd = strParam[at..-1]
			if toAdd == " "
				pieces = "
				<td id=\"main\">
					<center>
						<input type=\"checkbox\" name=\"#{addrParam}#{totalBits}\" disabled>
					</center>
				</td>"+pieces
			else 
				pieces = "
				<td id=\"main\">
					<center>
						<input type=\"checkbox\" name=\"#{addrParam}#{totalBits}\" onchange=\"toggleCheckbox(this)\">
					</center>
				</td>"+pieces
			end

			at -= 2
			strParam = strParam[0..at]
			totalBits+=1
		end
	
		if strParam == " "
			pieces = "
				<td id=\"main\">
					<center>
						<input type=\"checkbox\" name=\"#{addrParam}#{totalBits}\" disabled>
					</center>
				</td>"+pieces
		else 
			pieces = "
				<td id=\"main\">
					<center>
						<input type=\"checkbox\" name=\"#{addrParam}#{totalBits}\" onchange=\"toggleCheckbox(this)\">
					</center>
				</td>"+pieces
		end
		totalBits+=1
	
		# Fill the rest of the bits.
		while totalBits<8
			pieces = "
				<td id=\"main\">
					<center>
						<input type=\"checkbox\" name=\"#{addrParam}#{totalBits}\" disabled>
					</center>
				</td>"+pieces
			totalBits+=1
		end
		return pieces	
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
	
	def hexToDisplay(addrParam)	
		hex_tbr = @gpio2.getGPIO2(addrParam[2..-1]).to_i.to_s(16)
		if hex_tbr.length<2
			hex_tbr = "0"+hex_tbr
		end
		return "0x"+hex_tbr
	end
	
	def dataBitsToDisplay(addrParam)
    dataBitsToDisplay_tbr = ""
		
		bits = @gpio2.getGPIO2(addrParam[2..-1]).to_i.to_s(2)
    while bits.length < 8
        bits = "0"+bits
    end
    
    ct = 0
    while ct<8
    	if bits[ct] == "1"
    		dataBitsToDisplay_tbr += "
    			<td id=\"main\">
    				<center>
							<font size=\"1\">X</font>
    				</center>
    			</td>"
    	else
    		dataBitsToDisplay_tbr += "
    			<td id=\"main\">
    			</td>"
    	end
    	ct += 1
    end
    return dataBitsToDisplay_tbr
	end

	def testItemByte(addrParam,addrName,bitLabelsParam)
		if getRowNUmber() % 2 == 0
			@rowColor = @rowColor1
		else
			@rowColor = @rowColor2
		end
		testItemBit_tbr = "" # tbr - to be returned	
		testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
				<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrName}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\">
					<center>
						<button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"checkByteValue('#{addrParam}')\" />
							Update
							</button>
					</center>
				</td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">"			
		testItemBit_tbr += "<td/><td/><td/><td/><td/><td/><td/><td align=\"right\"><font size=\"1\">(int-&gt;)</font></td>"
		testItemBit_tbr += "
				<td id=\"main\">
					<center>
						<input 
							type=\"text\" 
							id=\"text\" 
							name=\"hdn#{addrParam}\" 
							style=\"height:20px; width:50px; font-size:10px\"
							/>
					</center>
				</td>			
			</tr>"
		testItemBit_tbr += "
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\"><center><font size=\"1\">GPIO</font></center></td>"
		testItemBit_tbr += dataBitsToDisplay(addrParam)
		testItemBit_tbr += "
				<td id=\"main\"><center><font size=\"1\">"+hexToDisplay(addrParam)+"</font></center></td>			
			</tr>"
	end

	def readItemBit(addrParam,addrName,bitLabelsParam)
		if getRowReadNumber() % 2 == 0
			@rowColor = @rowColorRead1
		else
			@rowColor = @rowColorRead2
		end
		testItemBit_tbr = "" # tbr - to be returned	
		testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">#{addrName}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">GPIO</font></center></td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">"			
		testItemBit_tbr += dataBitsToDisplay(addrParam)
		testItemBit_tbr += "
				<td id=\"main\"><center><font size=\"1\">"+hexToDisplay(addrParam)+"</font></center></td>			
			</tr>"
	end

	def testItemBit(addrParam,addrName,bitLabelsParam)
		if getRowNUmber() % 2 == 0
			@rowColor = @rowColor1
		else
			@rowColor = @rowColor2
		end
		testItemBit_tbr = "" # tbr - to be returned	
		testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
				<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrName}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\">
					<center>
						<input 
							type=\"submit\" 
							style=\"height:20px; width:50px; font-size:10px\" 
							value=\"Update\" 
							name=\"_#{addrParam}\" />								
					</center>
				</td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">"	
		testItemBit_tbr += getBitRadioBtns(addrParam,bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\">
					<center><font size=\"1\"><label id=\"#{addrParam}lbl\">0x00</font></center>
					<input type=\"hidden\" name=\"hdn#{addrParam}\" id=\"hdn#{addrParam}\" value=\"\" />
				</td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\"><center><font size=\"1\">GPIO</font></center></td>"
		testItemBit_tbr += dataBitsToDisplay(addrParam)
		testItemBit_tbr += "
				<td id=\"main\"><center><font size=\"1\">"+hexToDisplay(addrParam)+"</font></center></td>			
			</tr>"
	end	
=begin	
    class << self
      extend Forwardable
      def_delegators :instance, *TestPanelGui.instance_methods(false)
    end
=end    
	# End of 'class testPanelGui'
end

