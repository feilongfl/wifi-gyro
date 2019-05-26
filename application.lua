
lastData = ""

--data type
DSUC_VersionReq = 0x100000;
DSUS_PortInfo = 0x100001;
DSUC_PadDataReq = 0x100002;

maxProtocolVer = 1001;
serverID = 0x12345678;

lastRequestTime = nil;
lastRequestIP = nil;
lastRequestPORT = nil;
lastRequestSockets = nil;

function onUDPRecv(s, data, port, ip)    
    --debugMsg(string.format("received '%s' from %s:%d", data, ip, port))
    decodeData(data, s, port, ip);
end

function debugMsg(msg)
    if DEBUGMSG == true then
        print(msg);
    end
end

function readUInt16LE(data, offset)
    a,b = string.byte(data ,offset, offset + 1);
    return bit.bor(bit.lshift(b, 8), a);
end

function readUInt32LE(data, offset)
    a,b,c,d = string.byte(data ,offset, offset + 3);
    return bit.bor(bit.lshift(d, 24),bit.lshift(c, 16),bit.lshift(b, 8), a);
end

function setStr(data, offset, val)
    local t = {};
    local str = "";
    for i = 1,lastData:len() do
        table.insert(t, lastData:byte(i))
    end

    for k,v in pairs(val) do
        t[offset + k - 1] = v
    end

    for k,v in pairs(t) do 
        print(k, string.format("%X",v))
        str = str..string.char(v)
    end
    print(str)
    
    return str
end

function writeUInt16LE(data)
    local t = {};
    for i = 0,1 do
        t[i + 1] = bit.band(0xff,bit.rshift(data, 8*i));
    end
    return t
end

function writeUInt32LE(data)
    local t = {};
    for i = 0,3 do
        t[i + 1] = bit.band(0xff,bit.rshift(data, 8*i));
    end
    return t
end

function sendReq(reqdata, s, port, ip)
    local str = "";
    local t = {string.byte("DSUS",1,4)};
    for k, v in pairs(writeUInt16LE(maxProtocolVer)) do table.insert(t, v); end
    for k, v in pairs(writeUInt16LE(#reqdata)) do table.insert(t, v); end
    for k, v in pairs(writeUInt32LE(0x00000000)) do table.insert(t, v); end
    for k, v in pairs(writeUInt32LE(serverID)) do table.insert(t, v); end
    for k,v in pairs(t) do 
        str = str..string.char(v)
    end
    for k, v in pairs(writeUInt32LE(crc32.xcrc32(str))) do 
        t[7+k] = v;
    end
    local str = "";
    for k,v in pairs(t) do 
        str = str..string.char(v)
    end
    debugMsg(str);
    s:send(port, ip, str);
end

function decodeData(data, s, port, ip)
    if string.sub(data,0,4) == "DSUC" then
        lastData = data;
        index = 5;
        protocolVer = readUInt16LE(data, index);
        index = index + 2;
        packetSize = readUInt16LE(data, index);
        index = index + 2;
        receivedCrc = readUInt32LE(data, index);
        -- checkcrc
        print(receivedCrc)
        setStr(data,index,{0x00,0x00,0x00,0x00})
        print(crc32.xcrc32(data))
        index = index + 4;
        
        -- checkcrc
        clientId = readUInt32LE(data, index);
        index = index + 4;
        msgType = readUInt32LE(data, index);
        index = index + 4;
        if msgType == DSUC_VersionReq then
            debugMsg("version req is ignore!");
            return nil;
        elseif msgType == DSUS_PortInfo then
            numOfPadRequests = readUInt32LE(data, index);
            index = index + 4;
            for i = 1,numOfPadRequests do
                reqTable = writeUInt32LE(DSUS_PortInfo);
                table.insert(reqTable, 0x00); -- pad id
                table.insert(reqTable, 0x02); -- state (connected)
                table.insert(reqTable, 0x02); -- model (generic)
                table.insert(reqTable, 0x01); -- connection type (usb)
                for i = 1,5 do -- mac address
                    table.insert(reqTable, 0x00); 
                end
                table.insert(reqTable, 0xff); -- mac 00:00:00:00:00:FF
                table.insert(reqTable, 0xef); -- battery (charged)
                table.insert(reqTable, 0x01); -- is active (true)
                
                sendReq(reqTable, s, port, ip);
            end
        elseif msgType == DSUC_PadDataReq then
            debugMsg("pad data req");
            flags = string.byte(data, index);
            index = index + 1;
            idToRRegister = string.byte(data, index);
            index = index + 1;
            macToRegister = {string.byte(data, index, index + 5)};
            index = index + 6;
        else 
            return nil--drop unknown req
        end
        lastRequestTime = tmr.now();
        lastRequestSockets = s;
        lastRequestIP = ip;
        lastRequestPORT = port;
    end
end

print("init server at port => "..PORT.."...")
if udpSocket == nil then
    udpSocket = net.createUDPSocket()
    udpSocket:listen(PORT)
end
udpSocket:on("receive", onUDPRecv)
port, ip = udpSocket:getaddr()
print(string.format("local UDP socket address / port: %s:%d", ip, PORT))
