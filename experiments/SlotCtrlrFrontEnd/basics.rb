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

		db.execute "UPDATE Cars SET Price=#{rand(42-10) + 10} WHERE Id=1;"

		ary = db.execute "SELECT * FROM Cars"    
		asdf = []
		str += 	"<table style=\"width:300px;border:1px solid black;\">"
		ary.each do |row|
			str += 	"<tr>"
			str += 	"<td>#{row['Id']}</td>"
			str += 	"<td>#{row['Name']}</td>"
			str += 	"<td>#{row['Price']}</td>"
			str += 	"</tr>"
		end

		rescue SQLite3::Exception => e 
		    puts "Exception occured"
		    puts e

		ensure
		    db.close if db
		
	end
	str += "</table>
	</div>	
	<script type=\"text/javascript\">
	setInterval(function(){loadXMLDoc()},3000);
	</script>
	"
end

