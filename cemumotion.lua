local packageNum = 0

-- data type
local DSUC_VersionReq = 0x100000
local DSUS_PortInfo = 0x100001
local DSUC_PadDataReq = 0x100002

local maxProtocolVer = 1001
local serverID = 0x12345678

-- caches
cacheReq = {}
cacheInfo = {}
cacheData = {}

function makeReqPackage(length, crc)
    local t = {}
    local ti = 1

    -- for k, v in pairs({"D", "S", "U", "S"}) do
    for k, v in pairs({0x44, 0x53, 0x55, 0x53}) do
        t[ti] = v
        ti = ti + 1
    end -- ver
    for k, v in pairs(writeUInt16LE(maxProtocolVer)) do
        t[ti] = v
        ti = ti + 1
    end -- ver
    for k, v in pairs(writeUInt16LE(length)) do
        t[ti] = v
        ti = ti + 1
    end -- length
    for k, v in pairs(writeUInt32LE(crc)) do
        t[ti] = v
        ti = ti + 1
    end -- crc
    for k, v in pairs(writeUInt32LE(serverID)) do
        t[ti] = v
        ti = ti + 1
    end -- id

    return t
end

function genReqPackage(length, crc)
    if #cacheReq == 0 then
        cacheReq = makeReqPackage(length, crc)
    else
        local ti = 7
        for k, v in pairs(writeUInt16LE(length)) do
            cacheReq[ti] = v
            ti = ti + 1
        end -- length
        for k, v in pairs(writeUInt32LE(crc)) do
            cacheReq[ti] = v
            ti = ti + 1
        end -- crc
    end
    return cacheReq
end

function sendReq(reqdata, s, port, ip)
    -- protocal start
    genReqPackage(#reqdata, 0)

    local str = ByteTableToString(cacheReq) .. ByteTableToString(reqdata)
    genReqPackage(#reqdata, crc32.hash(str))

    str = ByteTableToString(cacheReq) .. ByteTableToString(reqdata)
    if ip ~= nil and disconnect_ct == nil then s:send(port, ip, str) end
end

function makeInfoPackage()
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

    return reqTable
end

function genInfoPackage()
    if #cacheInfo == 0 then cacheInfo = makeInfoPackage() end
end

function decodeData(data, s, port, ip)
    if string.sub(data, 0, 4) == "DSUC" then
        lastData = data
        index = 5
        -- protocolVer = readUInt16LE(data, index)
        index = index + 2
        -- local packetSize = readUInt16LE(data, index)
        index = index + 2
        -- receivedCrc = readUInt32LE(data, index)
        -- setStr(data, index, {0x00, 0x00, 0x00, 0x00}) -- ignore crc check to save time
        -- print(crc32.hash(data))
        index = index + 4
        -- todo: checkcrc here
        -- clientId = readUInt32LE(data, index)
        index = index + 4
        local msgType = readUInt32LE(data, index)
        index = index + 4
        if msgType == DSUC_VersionReq then
            Log(1, "version req is ignore!")
            return nil
        elseif msgType == DSUS_PortInfo then
            numOfPadRequests = readUInt32LE(data, index)
            index = index + 4
            -- print("debuggg ---> ", numOfPadRequests)
            -- for i = 1,numOfPadRequests do
            genInfoPackage()
            sendReq(cacheInfo, s, port, ip)
            -- end
        elseif msgType == DSUC_PadDataReq then
            Log(1, "pad data req ignore") -- ignored
            -- flags = string.byte(data, index)
            -- index = index + 1
            -- idToRRegister = string.byte(data, index)
            -- index = index + 1
            -- macToRegister = {string.byte(data, index, index + 5)}
            -- index = index + 6
        else
            return nil -- drop unknown req
        end
        lastRequestTime = tmr.now()
        lastRequestSockets = s
        lastRequestIP = ip
        lastRequestPORT = port
    end
end

function makeDataPackage(ax, ay, az, gx, gy, gz, time)
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
    Log(1, string.format("packageNum at [%d]", reqTableIndex))
    for k, v in pairs(writeUInt32LE(0)) do -- packageNum
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
    Log(1, string.format("tmr at [%d]", reqTableIndex))
    for k, v in pairs(writeUInt32LE(time)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeUInt32LE(16)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end -- unknow

    Log(1, string.format("data at [%d]", reqTableIndex))
    for k, v in pairs(writeFloatLE(ax)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(ay)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(az)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(gx)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(gy)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end
    for k, v in pairs(writeFloatLE(gz)) do
        reqTable[reqTableIndex] = v
        reqTableIndex = reqTableIndex + 1
    end

    return reqTable
end

function genDataPackage(ax, ay, az, gx, gy, gz, time)
    if #cacheData == 0 then
        cacheData = makeDataPackage(ax, ay, az, gx, gy, gz, time)
    else
        -- package number
        local index = 17
        for k, v in pairs(writeUInt32LE(packageNum)) do -- packageNum
            cacheData[index] = v
            index = index + 1
        end
        -- time
        index = 53
        for k, v in pairs(writeUInt32LE(time)) do
            cacheData[index] = v
            index = index + 1
        end

        -- data
        index = 61
        for k, v in pairs(writeFloatLE(ax)) do
            cacheData[index] = v
            index = index + 1
        end
        for k, v in pairs(writeFloatLE(ay)) do
            cacheData[index] = v
            index = index + 1
        end
        for k, v in pairs(writeFloatLE(az)) do
            cacheData[index] = v
            index = index + 1
        end
        for k, v in pairs(writeFloatLE(gx)) do
            cacheData[index] = v
            index = index + 1
        end
        for k, v in pairs(writeFloatLE(gy)) do
            cacheData[index] = v
            index = index + 1
        end
        for k, v in pairs(writeFloatLE(gz)) do
            cacheData[index] = v
            index = index + 1
        end
    end

    packageNum = packageNum + 1
    if packageNum == 0xffffffff then packageNum = 0 end
end

function sendmpu()
    local time = tmr.now()
    local ax, ay, az, gx, gy, gz = readMpu()
    -- print(string.format(
    --         "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", 
    --         ax, ay, az, temp, gx, gy, gz))
    timeDebug("mpu6050")
    -- LogPoint()
    genDataPackage(ax, ay, az, gx, gy, gz, time)
    sendReq(cacheData, lastRequestSockets, lastRequestPORT, lastRequestIP)
    mputimer:start()
end

if mputimer == nil then mputimer = tmr.create() end
mputimer:alarm(10, tmr.ALARM_SEMI, sendmpu)
