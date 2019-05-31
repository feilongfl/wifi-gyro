
i2c.setup(IICID, IICSDA, IICSCL, i2c.SLOW)
mpu6050.setup()

function readMpu()
    local ax,ay,az,temp,gx,gy,gz = mpu6050.read()
    Log(1, string.format(
            "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", 
            ax, ay, az, temp, gx, gy, gz))
            
    mputimer:start()
end

packageNum = 0;

function sendmpu()
    local ax,ay,az,temp,gx,gy,gz = mpu6050.read()
    -- print(string.format(
    --         "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", 
    --         ax, ay, az, temp, gx, gy, gz))
    -- print("--------")
    timeDebug("mpu6050")
    local reqTable = writeUInt32LE(DSUC_PadDataReq);
    local reqTableIndex = #reqTable + 1
    reqTable[reqTableIndex] = 0x00; reqTableIndex = reqTableIndex + 1 -- pad id
    reqTable[reqTableIndex] = 0x02; reqTableIndex = reqTableIndex + 1 -- state (connected)
    reqTable[reqTableIndex] = 0x02; reqTableIndex = reqTableIndex + 1 -- model (generic)
    reqTable[reqTableIndex] = 0x01; reqTableIndex = reqTableIndex + 1 -- connection type (usb)
    for i = 1,5 do -- mac address
        reqTable[reqTableIndex] = 0x00; reqTableIndex = reqTableIndex + 1 
    end
    reqTable[reqTableIndex] = 0xff; reqTableIndex = reqTableIndex + 1 -- mac 00:00:00:00:00:FF
    reqTable[reqTableIndex] = 0xef; reqTableIndex = reqTableIndex + 1 -- battery (charged)
    reqTable[reqTableIndex] = 0x01; reqTableIndex = reqTableIndex + 1 -- is active (true)
    for k, v in pairs(writeUInt32LE(packageNum)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for i = 1,4 do
        reqTable[reqTableIndex] = 0x00; reqTableIndex = reqTableIndex + 1
    end -- unknow
    for k, v in pairs(writeUInt32LE(0xff00ff00)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end -- unknow
    for i = 1,24 do
        reqTable[reqTableIndex] = 0x00; reqTableIndex = reqTableIndex + 1
    end-- unknow
    for k, v in pairs(writeUInt32LE(tmr.now())) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for k, v in pairs(writeUInt32LE(16)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end -- unknow

    for k, v in pairs(writeFloatLE(ax / 32763)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for k, v in pairs(writeFloatLE(ay / 32763)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for k, v in pairs(writeFloatLE(az / 32763)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for k, v in pairs(writeFloatLE(gx / 32763)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for k, v in pairs(writeFloatLE(gy / 32763)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    for k, v in pairs(writeFloatLE(gz / 32763)) do reqTable[reqTableIndex] = v; reqTableIndex = reqTableIndex + 1 end
    -- timeDebug("1")
    sendReq(reqTable, lastRequestSockets, lastRequestPORT, lastRequestIP);
    -- timeDebug("2")
    packageNum = packageNum + 1
    mputimer:start()
end

if mputimer == nil then 
    mputimer = tmr.create()
end
mputimer:alarm(10, tmr.ALARM_SEMI, sendmpu)
