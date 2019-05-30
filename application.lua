
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
        --print(k, string.format("%X",v))
        str = str..string.char(v)
    end
    -- print(str)
    
    return str
end

function sendReq(reqdata, s, port, ip)
    -- protocal start
    -- timeDebug("3")
    local t = {"D", "S", "U", "S"}; -- head
    for k, v in pairs(writeUInt16LE(maxProtocolVer)) do table_insert_byte(t, v); end -- ver
    for k, v in pairs(writeUInt16LE(#reqdata)) do table_insert_byte(t, v); end -- length
    for k, v in pairs(writeUInt32LE(0x00000000)) do table_insert_byte(t, v); end -- index
    for k, v in pairs(writeUInt32LE(serverID)) do table_insert_byte(t, v); end -- id
    for k,v in pairs(reqdata) do -- data
        table_insert_byte(t, v)
    end
    -- timeDebug("4")
    --print("-------------------------------")
    -- local str = ByteTableToString(t)
    local str = table.concat(t)
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
    str = replace_char(9, str, table.concat(crc))
    -- print("send[",str,"](", #reqdata, ",", #t, ",", #str,") to [",ip,":",port,"]")
    -- timeDebug("7")
    if ip ~= nil then
        s:send(port, ip, str);
    end
    -- timeDebug("8")
end

function sendReq2(reqdata, s, port, ip)
    -- protocal start
    -- timeDebug("3")
    local t = {"D", "S", "U", "S"}; -- head
    for k, v in pairs(writeUInt16LE(maxProtocolVer)) do table.insert(t, v); end -- ver
    for k, v in pairs(writeUInt16LE(#reqdata)) do table.insert(t, v); end -- length
    for k, v in pairs(writeUInt32LE(0x00000000)) do table.insert(t, v); end -- index
    for k, v in pairs(writeUInt32LE(serverID)) do table.insert(t, v); end -- id
    for k,v in pairs(reqdata) do -- data
        table.insert(t, v)
    end
    -- timeDebug("4")
    local str = table.serial(t)
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
    str = table.serial(t)
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
            debugMsg("version req is ignore!");
            return nil;
        elseif msgType == DSUS_PortInfo then
            numOfPadRequests = readUInt32LE(data, index);
            index = index + 4;
            --print("debuggg ---> ", numOfPadRequests)
            --for i = 1,numOfPadRequests do
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
            --end
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
