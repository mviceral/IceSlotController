# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
# require 'singleton'
# require 'forwardable'

require 'json'
require_relative '../BBB_Shared Memory for GPIO2 Ruby/SharedMemoryGPIO2'

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
		hex_tbr = @gpio2.getGPIO2(addrParam[2..-1].to_i(16).to_i).to_i.to_s(16)
		if hex_tbr.length<2
			hex_tbr = "0"+hex_tbr
		end
		return "0x"+hex_tbr
	end
	
	def dataBitsToDisplay(addrParam)
    dataBitsToDisplay_tbr = ""
		
		bits = @gpio2.getGPIO2(addrParam[2..-1].to_i(16).to_i).to_i.to_s(2)
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
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><button type=\"button\" style=\"height:20px; width:50px; font-size:10px\">Update</button></center></td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">"			
		testItemBit_tbr += dataBitsToDisplay(addrParam)
		testItemBit_tbr += "
				<td id=\"main\">
					<center>
						<input 
							type=\"text\" 
							id=\"text\" 
							name=\"#{addrParam}\" 
							style=\"height:20px; width:50px; font-size:10px\" />
					<input type=\"hidden\" name=\"hdn#{addrParam}\" id=\"hdn#{addrParam}\" value=\"\" />
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

