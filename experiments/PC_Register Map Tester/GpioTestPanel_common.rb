# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
# require 'singleton'
# require 'forwardable'


class TestPanelGui

	def initialize (rC1Param,rC2Param,rCR1Param,rCR2Param)
		@rowNumber = 3
		@readRowNumber = 3
		@rowColor1 = rC1Param
		@rowColor2 = rC2Param
		@rowColorRead1 = rCR1Param
		@rowColorRead2 = rCR2Param
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

	def getBitRadioBtns(strParam)
		pieces = ""
		totalBits = 0
		while strParam.index('|') != nil
			totalBits+=1
			at = strParam.index('|')
			toAdd = strParam[0..(at-1)]
			if toAdd == " "
				pieces += "<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>"
			else 
				pieces += "<td id=\"main\"><center><input type=\"radio\" name=\"x004\"></center></td>"
			end

			at += 1
			strParam = strParam[at..-1]
		end
	
		if strParam == " "
			pieces += "<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>"
		else 
			pieces += "<td id=\"main\"><center><input type=\"radio\" name=\"x004\"></center></td>"
		end
		totalBits += 1
	
		# Fill the rest of the bits.
		while totalBits<8
			totalBits+=1
			pieces = "<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>"+pieces
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

	def testItemByte(addrParam,bitLabelsParam)
		if getRowNUmber() % 2 == 0
			@rowColor = @rowColor1
		else
			@rowColor = @rowColor2
		end
		testItemBit_tbr = "" # tbr - to be returned	
		testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><button type=\"button\" style=\"height:20px; width:50px; font-size:10px\">Update</button></center></td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\"><center><input type=\"radio\" name=\"x007\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x006\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x005\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x004\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x003\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x002\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x001\" disabled></center></td>
				<td id=\"main\"><center><input type=\"radio\" name=\"x000\" disabled></center></td>
			"
		testItemBit_tbr += "
				<td id=\"main\"><center><input type=\"text\" id=\"text\" name=\"text_name\" style=\"height:20px; width:50px; font-size:10px\" /></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">
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
		if getRowReadNumber() % 2 == 0
			@rowColor = @rowColorRead1
		else
			@rowColor = @rowColorRead2
		end
		testItemBit_tbr = "" # tbr - to be returned	
		testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\"><center><font size=\"1\">GPIO</font></center></td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">			
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
			@rowColor = @rowColor1
		else
			@rowColor = @rowColor2
		end
		testItemBit_tbr = "" # tbr - to be returned	
		testItemBit_tbr += "<tr id=\"main\" bgcolor=\"#{@rowColor}\">
				<td id=\"main\" rowspan=\"3\" valign=\"center\"><center><font size=\"1\">#{addrParam}</font></center></td>
				<td id=\"main\" rowspan=\"2\" valign=\"center\">
					<center>
						<button type=\"button\" style=\"height:20px; width:50px; font-size:10px\">Update</button></button></center></td>"
		testItemBit_tbr += getBitLables(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">"	
		testItemBit_tbr += getBitRadioBtns(bitLabelsParam)
		testItemBit_tbr += "
				<td id=\"main\"><center><font size=\"1\">0x1</font></center></td>			
			</tr>
			<tr id=\"main\" bgcolor=\"#{@rowColor}\">
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
=begin	
    class << self
      extend Forwardable
      def_delegators :instance, *TestPanelGui.instance_methods(false)
    end
=end    
	# End of 'class testPanelGui'
end

