
i2c.setup(IICID, IICSDA, IICSCL, i2c.SLOW)
mpu6050.setup()

function readMpu()
    local ax,ay,az,temp,gx,gy,gz = mpu6050.read()
    print(string.format(
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

    reqTable = writeUInt32LE(DSUC_PadDataReq);
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
    for k, v in pairs(writeUInt32LE(packageNum)) do table.insert(reqTable, v); end
    for i = 1,4 do
        table.insert(reqTable, 0x00); 
    end -- unknow
    for k, v in pairs(writeUInt32LE(0xff00ff00)) do table.insert(reqTable, v); end -- unknow
    for i = 1,24 do
        table.insert(reqTable, 0x00); 
    end-- unknow
    for k, v in pairs(writeUInt32LE(tmr.now())) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(16)) do table.insert(reqTable, v); end -- unknow

    for k, v in pairs(writeFloatLE(ax / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeFloatLE(ay / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeFloatLE(az / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeFloatLE(gx / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeFloatLE(gy / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeFloatLE(gz / 32763)) do table.insert(reqTable, v); end
   
    sendReq(reqTable, lastRequestSockets, lastRequestPORT, lastRequestIP);

    packageNum = packageNum + 1
    mputimer:start()
end

if mputimer == nil then 
    mputimer = tmr.create()
end
mputimer:alarm(10, tmr.ALARM_SEMI, sendmpu)

