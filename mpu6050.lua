i2c.setup(IICID, IICSDA, IICSCL, i2c.SLOW)
mpu6050.setup()

local function fitaccu(v, offset)
    return (v - offset) / (0x10000 / 2 - 1) * 2 -- max 2g
end

local function fitaccus(x, y, z)
    return fitaccu(x, 0), fitaccu(y, 0), fitaccu(z, 0)
end

local function fitgyro(v, offset)
    return (v - offset) / (0x10000 / 2 - 1) * 250 -- max 250/s
end

local function fitgyros(x, y, z)
    return fitgyro(x, 0), fitgyro(y, 0), fitgyro(z, 0)
end

function readMpu()
    local ax, ay, az, temp, gx, gy, gz = mpu6050.read()
    Log(1, string.format(
        "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", ax,
        ay, az, temp, gx, gy, gz))

    ax, ay, az = fitaccus(ax, ay, az)
    gx, gy, gz = fitgyros(gx, gy, gz)

    return ax, ay, az, gx, gy, gz
end
