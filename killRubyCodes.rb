def killProc(param)
	rubyProc = `ps -A | grep #{param}`
	# Determine how many lines
	lines = rubyProc.split("\n")
	ct = 0 
	procNumToKill = ""
	while ct<lines.length
		isolated = lines[ct].lstrip.chop
		isolatedParts = isolated.split(" ")
		puts "'#{param}' process# '#{isolatedParts[0]}'"
		ct += 1
		if procNumToKill.length > 0
			procNumToKill += " "
		end
		procNumToKill += isolatedParts[0]
	end

	if procNumToKill.length>0
		puts "kill -9 #{procNumToKill}"
		`kill -9 #{procNumToKill}`
	end
end

killProc("rackup")
killProc("ruby")
