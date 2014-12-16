require_relative '../lib/SharedLib'

# 365.25/2 (days) = 6 months
# 365.25/2*24 (hours)
# 365.25/2*24*60 (mins)
# 365.25/2*24*60*60 (sec)
timeSpan = 365.25/2*24*60*60
timeSpan = 13*24*60*60 # 43 hour old
timeNow = Time.now.to_i
# puts "timeSpan=#{timeSpan}" 
# puts "timeNow=#{timeNow}" 
outdatedFiles = ""
list = Dir.glob("../../slot-controller_data/steps log records/**/*").each { 
	|file|
	if timeNow-File.mtime(file).to_i> timeSpan
		if outdatedFiles.length > 0
			outdatedFiles += "\n"
		end
		outdatedFiles += "#{file}"
	end 
}
outDatedFileReport = ""
if outdatedFiles.length>0
	outDatedFileReport = "Please note the following files are 6 months old.  They may need to be removed to free up hard drive space.:\n"
	outDatedFileReport += outdatedFiles

	shutdownEmailSubject = "BE2/MoSys 6 Months Old File Notification"
	systemID = SharedLib.getSystemID()						
	shutdownEmailMessage = ""
	shutdownEmailMessage += "System: #{systemID}\n"
	shutdownEmailMessage += outDatedFileReport

	# Get the list of emails so the the recipients will be notified if the system had shutdown.
	getEmailAddr = false
	emailFlagFound = false
	emailAddrListHolder = Array.new
	File.open("../#{SharedLib::Pc_SlotCtrlIps}", "r") do |f|
		f.each_line do |line|
			line = line.strip
			if line == "<emailList>"
				getEmailAddr = true
				emailFlagFound = true
			elsif line == "</emailList>"
				getEmailAddr = false
			elsif getEmailAddr == true
				emailAddrListHolder.push(line)
			end
		end
	end
	emailFolks = ""
	if emailFlagFound == true && getEmailAddr == false
		emailAddrListHolder.each {
			|emailAddr|
			if emailFolks.length > 0
				emailFolks += ","
			end
			emailFolks += emailAddr
		}
		puts "Sending shutdown message to '#{emailFolks}'."
		`echo \"#{shutdownEmailMessage}\" | mail -s \"#{shutdownEmailSubject}\" \"#{emailFolks}\"`
	end
end

