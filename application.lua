
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

function setStr(data, offset, val)
    local t = {};
    for i = 1,lastData:len() do
        table.insert(t, lastData:byte(i))
    end

    for k,v in pairs(val) do
        t[offset + k - 1] = v
    end

    local str = ByteTableToString(t)
    -- print(str)
    
    return str
end

function sendReq(reqdata, s, port, ip)
    -- protocal start
    -- timeDebug("3")
    local t = {"D", "S", "U", "S"}; -- head
    for k, v in pairs(writeUInt16LE(maxProtocolVer)) do t[#t + 1] = v; end -- ver
    for k, v in pairs(writeUInt16LE(#reqdata)) do t[#t + 1] = v; end -- length
    for k, v in pairs(writeUInt32LE(0x00000000)) do t[#t + 1] = v; end -- index
    for k, v in pairs(writeUInt32LE(serverID)) do t[#t + 1] = v; end -- id
    for k,v in pairs(reqdata) do -- data
        t[#t + 1] = v
    end
    -- timeDebug("4")
    local str = ByteTableToString(t)
    -- timeDebug("5")
    --print("-------------------------------")
    --print("crc[",str,"](", #reqdata, ",", #t, ",", #str,") to [",ip,":",port,"]")
    local crc = {}
    for k, v in pairs(writeUInt32LE(crc32.hash(str))) do -- crc
      --  print(k, string.format("%X",v))
        t[k + 8] = v
        crc[#crc + 1] = string.char(v)
    end
    -- timeDebug("6")
    -- protocal fin
    -- str = replace_char(9, str, table.concat(crc))
    str = ByteTableToString(t)
    -- print("send[",str,"](", #reqdata, ",", #t, ",", #str,") to [",ip,":",port,"]")
    -- timeDebug("7")
    if ip ~= nil then
        s:send(port, ip, str);
    end
    -- timeDebug("8")
end

reqTable = {}

function decodeData(data, s, port, ip)
    -- print("recv[",data,"] from [",ip,":",port,"]")
    if string.sub(data,0,4) == "DSUC" then
        lastData = data;
        index = 5;
        protocolVer = readUInt16LE(data, index);
        index = index + 2;
        packetSize = readUInt16LE(data, index);
        index = index + 2;
        receivedCrc = readUInt32LE(data, index);
        -- checkcrc
        --print(receivedCrc)
        setStr(data,index,{0x00,0x00,0x00,0x00})
        --print(crc32.hash(data))
        index = index + 4;
        
        -- checkcrc
        clientId = readUInt32LE(data, index);
        index = index + 4;
        msgType = readUInt32LE(data, index);
        index = index + 4;
        if msgType == DSUC_VersionReq then
            Log(1, "version req is ignore!");
            return nil;
        elseif msgType == DSUS_PortInfo then
            numOfPadRequests = readUInt32LE(data, index);
            index = index + 4;
            --print("debuggg ---> ", numOfPadRequests)
            --for i = 1,numOfPadRequests do
                reqTable = writeUInt32LE(DSUS_PortInfo);
                reqTable[#reqTable + 1] = 0x00; -- pad id
                reqTable[#reqTable + 1] = 0x02; -- state (connected)
                reqTable[#reqTable + 1] = 0x02; -- model (generic)
                reqTable[#reqTable + 1] = 0x01; -- connection type (usb)
                for i = 1,5 do -- mac address
                    reqTable[#reqTable + 1] = 0x00; 
                end
                reqTable[#reqTable + 1] = 0xff; -- mac 00:00:00:00:00:FF
                reqTable[#reqTable + 1] = 0xef; -- battery (charged)
                reqTable[#reqTable + 1] = 0x01; -- is active (true)
                
                sendReq(reqTable, s, port, ip);
            --end
        elseif msgType == DSUC_PadDataReq then
            Log(1, "pad data req");
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

Log(2, "init server at port => "..PORT.."...")
if udpSocket == nil then
    udpSocket = net.createUDPSocket()
    udpSocket:listen(PORT)
end
udpSocket:on("receive", onUDPRecv)
port, ip = udpSocket:getaddr()
Log(2, string.format("local UDP socket address / port: %s:%d", ip, PORT))
