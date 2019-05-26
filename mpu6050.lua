

function debugMsg(msg)
    if DEBUGMSG == true then
        print(msg);
    end
end

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
    for k, v in pairs(writeUInt32LE(packageNum)) do table.insert(reqTable, v); end
    for i = 1,32 do
        table.insert(reqTable, 0x00); 
    end
    for k, v in pairs(writeUInt32LE(tmr.now())) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(0)) do table.insert(reqTable, v); end

    for k, v in pairs(writeUInt32LE(ax / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(ay / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(az / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(gx / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(gy / 32763)) do table.insert(reqTable, v); end
    for k, v in pairs(writeUInt32LE(gz / 32763)) do table.insert(reqTable, v); end
    
    sendReq(reqTable, lastRequestSockets, lastRequestPORT, lastRequestIP);

    packageNum = packageNum + 1
    mputimer:start()
end

if mputimer == nil then 
    mputimer = tmr.create()
end
mputimer:alarm(100, tmr.ALARM_SEMI, sendmpu)

