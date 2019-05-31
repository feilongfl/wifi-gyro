i2c.setup(IICID, IICSDA, IICSCL, i2c.SLOW)
mpu6050.setup()

function readMpu()
    local ax, ay, az, temp, gx, gy, gz = mpu6050.read()
    Log(1, string.format(
        "ax = %d, ay = %d, az = %d, temp = %d, gx = %d, gy = %d, gz = %d", ax,
        ay, az, temp, gx, gy, gz))

    mputimer:start()
end
