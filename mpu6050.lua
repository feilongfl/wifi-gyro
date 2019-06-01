i2c.setup(IICID, IICSDA, IICSCL, i2c.FAST)
mpu6050.setup(0, 0, 0x00)
mpu6050.calcOffset(1000)

-- local function fitaccu(v, offset)
--     return (v - offset) * 2 -- max 2g
-- end

-- local function fitaccus(x, y, z)
--     return fitaccu(x, 0), fitaccu(y, 0), fitaccu(z, 0)
-- end

-- local function fitgyro(v, offset)
--     return (v - offset) * 250 -- max 500/s
-- end

-- local function fitgyros(x, y, z)
--     return fitgyro(x, 0), fitgyro(y, 0), fitgyro(z, 0)
-- end

function readMpu()
    local ax, ay, az, temp, gx, gz, gy = mpu6050.read() -- todo fix axias
    Log(1, string.format(
        "ax = %f, ay = %f, az = %f, temp = %f, gx = %f, gy = %f, gz = %f", ax,
        ay, az, temp, gx, gy, gz))

    -- ax, ay, az = fitaccus(ax, ay, az)
    -- gx, gy, gz = fitgyros(gx, gy, gz)

    return ax, ay, az, gx, gy, gz
end
