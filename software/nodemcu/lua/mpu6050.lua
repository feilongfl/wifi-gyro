

function debugMsg(msg)
    if DEBUGMSG == true then
        print(msg);
    end
end

function read_reg(id, dev_addr, reg_addr)
    i2c.start(id)
    if i2c.address(id, dev_addr, i2c.TRANSMITTER) == false then
        i2c.stop(id)
        return nil; 
    end 
    i2c.write(id, reg_addr)

    i2c.stop(id)
    i2c.start(id)
    if i2c.address(id, dev_addr, i2c.RECEIVER) == false then
        i2c.stop(id)
        print(11,gpio.read(1),gpio.read(2))
        return nil; 
    end 
    c = i2c.read(id, 1)
    i2c.stop(id)

    return c
end

function set_reg(id, dev_addr, reg_addr, val)
    i2c.start(id)
    if i2c.address(id, dev_addr, i2c.TRANSMITTER) == false then
        i2c.stop(id)
        return nil; 
    end 
    i2c.write(id, reg_addr)
    i2c.write(id, val)
    i2c.stop(id)
end

function i2cScan()
    for i = 0x00,0x7f do
        i2c.start(0)
        print(i, i2c.address(0, i, i2c.TRANSMITTER))
        i2c.stop(0)
    end
end

function i2cDump(id, dev_addr)
    for i = 0x0d,0x75 do
        r = read_reg(id, dev_addr, i)
        if r ~= nil then
            print(i," -> ", string.byte(r))
        else
            print(i, "err")
        end
        --print(gpio.read(1),gpio.read(2))

        tmr.delay(100)
    end
end

i2c.setup(IICID, IICSDA, IICSCL, i2c.SLOW)
gpio.mode(IICSDA, gpio.OUTPUT, gpio.FLOAT)
gpio.mode(IICSCL, gpio.OUTPUT, gpio.FLOAT)
set_reg(IICID, 0x68, 0x6B, 0x00);
--mpu6050.setup()
function readMpu()
    --local ax,ay,az,temp,gx,gy,gz = mpu6050.read()
    --print(string.format(
    --        "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", 
    --        ax, ay, az, temp, gx, gy, gz))
    --print(read_reg(0,0x68,0x75))
    mputimer:start()
end

if mputimer == nil then 
    mputimer = tmr.create()
end
mputimer:alarm(1000, tmr.ALARM_SEMI, readMpu)
--mputimer:start()

