-- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("config.lua")
dofile("buffer.lua") -- todo
dofile("wifi.lua")

function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        
        dofile("application.lua")
        dofile("mpu6050.lua")
    end
end
