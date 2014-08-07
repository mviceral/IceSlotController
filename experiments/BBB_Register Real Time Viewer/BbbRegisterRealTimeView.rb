require 'socket'               # Get sockets from stdlib
require 'json'

def showValues(dataParam)
    # puts "dataParam=#{dataParam} dataParam.class=#{dataParam.class} #{__LINE__}-#{__FILE__}"
    if dataParam.nil? == true
        bits = "0"
    else
        bits = dataParam.to_s(2)
    end
    while bits.length < 8
        bits = "0"+bits
    end
    return "#{bits}:#{hv(dataParam)}"
end

def hv(dataParam)
    #
    # hex value
    #
    if dataParam.nil? == true
        h = "00"
    else
        h = dataParam.to_s(16)
        if h.length<2
            h = "0"+h
        end
    end
    return "0x"+h
end

puts "Code is now running."
server = TCPServer.open(2000)  # Socket to listen on port 2000
loop {                         # Servers run forever
    client = server.accept       # Wait for a client to connect
    h = JSON.parse(client.gets)
    puts ""
    puts "#{Time.new.inspect}"
    puts "0x0 : #{showValues(h[0.to_s])},  0x5 : #{showValues(h[5.to_s])},  0xa : #{showValues(h[10.to_s])}"
    puts "0x1 : #{showValues(h[1.to_s])},  0x6 : #{showValues(h[6.to_s])},  0xb : #{showValues(h[11.to_s])}"
    puts "0x2 : #{showValues(h[2.to_s])},  0x7 : #{showValues(h[7.to_s])},  0xc : #{showValues(h[12.to_s])}"
    puts "0x3 : #{showValues(h[3.to_s])},  0x8 : #{showValues(h[8.to_s])},  0xd : #{showValues(h[13.to_s])}"
    puts "0x4 : #{showValues(h[4.to_s])},  0x9 : #{showValues(h[9.to_s])}"
    client.close                 # Disconnect from the client
}