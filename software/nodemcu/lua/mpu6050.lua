

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
    i2c.address(id, dev_addr, i2c.RECEIVER)
    --if i2c.address(id, dev_addr, i2c.RECEIVER) == false then
    --    i2c.stop(id)
    --    return nil; 
    --end 
    c = i2c.read(id, 1)
    i2c.stop(id)
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

i2c.setup(IICID, IICSDA, IICSCL, i2c.SLOW)
--set_reg(IICID, 0x68, 0x6B, 0x00);
hmc5883l.setup()
function readMpu()
local x,y,z = hmc5883l.read()
print(string.format("x = %d, y = %d, z = %d", x, y, z))

for i = 1,0x7f do
    reg = read_reg(IICID, 0x1e, 0x04)
    --reg = read_reg(IICID, 0x68, 0x75)
    if reg == nil then 
        debugMsg("unable connect to gyro!")
        else
        print(i)
    end
end

    reg = read_reg(IICID, 0x1e, 0x04)
    --reg = read_reg(IICID, 0x68, 0x75)
    if reg == nil then 
        debugMsg("unable connect to gyro!")
        mputimer:start()
        return
    end
    print(string.byte(reg))

    mputimer:start()
end

if mputimer == nil then 
    mputimer = tmr.create()
end
mputimer:alarm(1000, tmr.ALARM_SEMI, readMpu)
mputimer:start()

