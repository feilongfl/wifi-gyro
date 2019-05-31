packageNum = 0


function sendReq(reqdata, s, port, ip)
    -- protocal start
    -- timeDebug("3")
    local t = {}
    local ti = 1
    for k, v in pairs({"D", "S", "U", "S"}) do
        t[ti] = v
        ti = ti + 1
    end -- ver
    for k, v in pairs(writeUInt16LE(maxProtocolVer)) do
        t[ti] = v
        ti = ti + 1
    end -- ver
    for k, v in pairs(writeUInt16LE(#reqdata)) do
        t[ti] = v
        ti = ti + 1
    end -- length
    for k, v in pairs(writeUInt32LE(0x00000000)) do
        t[ti] = v
        ti = ti + 1
    end -- index
    for k, v in pairs(writeUInt32LE(serverID)) do
        t[ti] = v
        ti = ti + 1
    end -- id
    for k, v in pairs(reqdata) do -- data
        t[ti] = v
        ti = ti + 1
    end
    -- timeDebug("4")
    local str = ByteTableToString(t)
    -- timeDebug("5")
    -- print("-------------------------------")
    -- print("crc[",str,"](", #reqdata, ",", #t, ",", #str,") to [",ip,":",port,"]")
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
    if ip ~= nil and disconnect_ct ~= nil then s:send(port, ip, str) end
    -- timeDebug("8")
end

function decodeData(data, s, port, ip)
    -- print("recv[",data,"] from [",ip,":",port,"]")
    if string.sub(data, 0, 4) == "DSUC" then
        lastData = data
        index = 5
        protocolVer = readUInt16LE(data, index)
        index = index + 2
        packetSize = readUInt16LE(data, index)
        index = index + 2
        receivedCrc = readUInt32LE(data, index)
        -- checkcrc
        -- print(receivedCrc)
        setStr(data, index, {0x00, 0x00, 0x00, 0x00})
        -- print(crc32.hash(data))
        index = index + 4

        -- checkcrc
        clientId = readUInt32LE(data, index)
        index = index + 4
        msgType = readUInt32LE(data, index)
        index = index + 4
        if msgType == DSUC_VersionReq then
            Log(1, "version req is ignore!")
            return nil
        elseif msgType == DSUS_PortInfo then
            numOfPadRequests = readUInt32LE(data, index)
            index = index + 4
            -- print("debuggg ---> ", numOfPadRequests)
            -- for i = 1,numOfPadRequests do
            local reqTable = writeUInt32LE(DSUS_PortInfo)
            local reqTableIndex = #reqTable + 1
            reqTable[reqTableIndex] = 0x00
            reqTableIndex = reqTableIndex + 1 -- pad id
            reqTable[reqTableIndex] = 0x02
            reqTableIndex = reqTableIndex + 1 -- state (connected)
            reqTable[reqTableIndex] = 0x02
            reqTableIndex = reqTableIndex + 1 -- model (generic)
            reqTable[reqTableIndex] = 0x01
            reqTableIndex = reqTableIndex + 1 -- connection type (usb)
            for i = 1, 5 do -- mac address
                reqTable[reqTableIndex] = 0x00
                reqTableIndex = reqTableIndex + 1
            end
            reqTable[reqTableIndex] = 0xff
            reqTableIndex = reqTableIndex + 1 -- mac 00:00:00:00:00:FF
            reqTable[reqTableIndex] = 0xef
            reqTableIndex = reqTableIndex + 1 -- battery (charged)
            reqTable[reqTableIndex] = 0x01
            reqTableIndex = reqTableIndex + 1 -- is active (true)

            sendReq(reqTable, s, port, ip)
            -- end
        elseif msgType == DSUC_PadDataReq then
            Log(1, "pad data req")
            flags = string.byte(data, index)
            index = index + 1
            idToRRegister = string.byte(data, index)
            index = index + 1
            macToRegister = {string.byte(data, index, index + 5)}
            index = index + 6
        else
            return nil -- drop unknown req
        end
        lastRequestTime = tmr.now()
        lastRequestSockets = s
        lastRequestIP = ip
        lastRequestPORT = port
    end
end

function sendmpu()
    local ax, ay, az, temp, gx, gy, gz = mpu6050.read()
    -- print(string.format(
    --         "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", 
    --         ax, ay, az, temp, gx, gy, gz))
    -- print("--------")
    timeDebug("mpu6050")
    local reqTable = writeUInt32LE(DSUC_PadDataReq)
    local reqTableIndex = #reqTable + 1
    reqTable[reqTableIndex] = 0x00
    reqTableIndex = reqTableIndex + 1 -- pad id
    reqTable[reqTableIndex] = 0x02
    reqTableIndex = reqTableIndex + 1 -- state (connected)
    reqTable[reqTableIndex] = 0x02
    reqTableIndex = reqTableIndex + 1 -- model (generic)
    reqTable[reqTableIndex] = 0x01
    reqTableIndex = reqTableIndex + 1 -- connection type (usb)
    for i = 1, 5 do -- mac address
        reqTable[reqTableIndex] = 0x00
        reqTableIndex = reqTableIndex + 1
    end
    reqTable[reqTableIndex] = 0xff
    reqTableIndex = reqTableIndex + 1 -- mac 00:00:00:00:00:FF
    reqTable[reqTableIndex] = 0xef
    reqTableIndex = reqTableIndex + 1 -- battery (charged)
    reqTable[reqTableIndex] = 0x01
    reqTableIndex = reqTableIndex + 1 -- is active (true)
    for k, v in pairs(writeUInt32LE(packageNum)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for i = 1, 4 do
        reqTable[reqTableIndex] = 0x00
        reqTableIndex = reqTableIndex + 1
    end -- unknow
    for k, v in pairs(writeUInt32LE(0xff00ff00)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end -- unknow
    for i = 1, 24 do
        reqTable[reqTableIndex] = 0x00
        reqTableIndex = reqTableIndex + 1
    end -- unknow
    for k, v in pairs(writeUInt32LE(tmr.now())) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeUInt32LE(16)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end -- unknow

    for k, v in pairs(writeFloatLE(ax / 32763)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(ay / 32763)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(az / 32763)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(gx / 32763)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(gy / 32763)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(gz / 32763)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    -- timeDebug("1")
    sendReq(reqTable, lastRequestSockets, lastRequestPORT, lastRequestIP)
    -- timeDebug("2")
    packageNum = packageNum + 1
    mputimer:start()
end

if mputimer == nil then mputimer = tmr.create() end
mputimer:alarm(10, tmr.ALARM_SEMI, sendmpu)
