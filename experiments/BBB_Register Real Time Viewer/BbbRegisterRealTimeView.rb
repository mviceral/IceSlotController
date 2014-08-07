require 'socket'               # Get sockets from stdlib
require 'json'

def getBits(dataParam)
    # puts "dataParam=#{dataParam} dataParam.class=#{dataParam.class} #{__LINE__}-#{__FILE__}"
    if dataParam.nil? == true
        bits = "0"
    else
        bits = dataParam.to_s(2)
    end
    while bits.length < 8
        bits = "0"+bits
    end
    return bits
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
server = TCPServer.open(2000)  # Socket to listen on port 2000
loop {                         # Servers run forever
    client = server.accept       # Wait for a client to connect
    h = JSON.parse(client.gets)
    puts ""
    puts "#{Time.new.inspect}"
    puts "0x0 : #{getBits(h[0.to_s])}:#{hv(h[0.to_s])},  0x1 : #{getBits(h[1.to_s])}:#{hv(h[1.to_s])},  0x2 : #{getBits(h[2.to_s])}:#{hv(h[2.to_s])}"
    puts "0x3 : #{getBits(h[3.to_s])}:#{hv(h[3.to_s])},  0x4 : #{getBits(h[4.to_s])}:#{hv(h[4.to_s])},  0x5 : #{getBits(h[5.to_s])}:#{hv(h[5.to_s])}"
    puts "0x6 : #{getBits(h[6.to_s])}:#{hv(h[6.to_s])},  0x7 : #{getBits(h[7.to_s])}:#{hv(h[7.to_s])},  0x8 : #{getBits(h[8.to_s])}:#{hv(h[8.to_s])}"
    puts "0x9 : #{getBits(h[9.to_s])}:#{hv(h[9.to_s])},  0xa : #{getBits(h[10.to_s])}:#{hv(h[10.to_s])},  0xb : #{getBits(h[11.to_s])}:#{hv(h[11.to_s])}"
    puts "0xc : #{getBits(h[12.to_s])}:#{hv(h[12.to_s])},  0xd : #{getBits(h[13.to_s])}:#{hv(h[13.to_s])}"
    client.close                 # Disconnect from the client
}