require 'rubygems'
require 'sinatra'
require 'sqlite3'

get '/about' do
	'A little about me.'
end

get '/form' do 
	erb :form
end

post '/form' do
	begin
		str = "
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
			dut1 = row['slotData'].partition("|")
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
			dut24 = dut23[2].partition("|")

			dut1 = dut1[0].partition("@")
			dut2 = dut2[0].partition("@")
			dut3 = dut3[0].partition("@")
			dut4 = dut4[0].partition("@")
			dut5 = dut5[0].partition("@")
			dut6 = dut6[0].partition("@")
			dut7 = dut7[0].partition("@")
			dut8 = dut8[0].partition("@")
			dut9 = dut9[0].partition("@")
			dut10 = dut10[0].partition("@")
			dut11 = dut11[0].partition("@")
			dut12 = dut12[0].partition("@")
			dut13 = dut13[0].partition("@")
			dut14 = dut14[0].partition("@")
			dut15 = dut15[0].partition("@")
			dut16 = dut16[0].partition("@")
			dut17 = dut17[0].partition("@")
			dut18 = dut18[0].partition("@")
			dut19 = dut19[0].partition("@")
			dut20 = dut20[0].partition("@")
			dut21 = dut21[0].partition("@")
			dut22 = dut22[0].partition("@")
			dut23 = dut23[0].partition("@")
			dut24 = dut24[0].partition("@")
			
			str += 	"#{Time.at(row['slotTime']).inspect}"
			str += 	"<table border=\"1\">"
			str += 	"<tr>"
			str += 	"<td>#{dut1[2]}</td>"
			str += 	"<td>#{dut2[2]}</td>"
			str += 	"<td>#{dut3[2]}</td>"
			str += 	"<td>#{dut4[2]}</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>#{dut5[2]}</td>"
			str += 	"<td>#{dut6[2]}</td>"
			str += 	"<td>#{dut7[2]}</td>"
			str += 	"<td>#{dut8[2]}</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>#{dut9[2]}</td>"
			str += 	"<td>#{dut10[2]}</td>"
			str += 	"<td>#{dut11[2]}</td>"
			str += 	"<td>#{dut12[2]}</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>#{dut13[2]}</td>"
			str += 	"<td>#{dut14[2]}</td>"
			str += 	"<td>#{dut15[2]}</td>"
			str += 	"<td>#{dut16[2]}</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>#{dut17[2]}</td>"
			str += 	"<td>#{dut18[2]}</td>"
			str += 	"<td>#{dut19[2]}</td>"
			str += 	"<td>#{dut20[2]}</td>"
			str += 	"</tr>"
			str += 	"<tr>"
			str += 	"<td>#{dut21[2]}</td>"
			str += 	"<td>#{dut22[2]}</td>"
			str += 	"<td>#{dut23[2]}</td>"
			str += 	"<td>#{dut24[2]}</td>"
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
	setInterval(function(){loadXMLDoc()},3000);
	</script>
	"
end

