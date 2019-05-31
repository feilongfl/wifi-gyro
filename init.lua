-- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("config.lua")
dofile("log.lua")
dofile("compile.lua")
checkCompileConfig()

runlua("buffer")
runlua("wifi")

function startup()
    if file.open("init.lua") == nil then
        Log(4, "init.lua deleted or renamed")
    else
        Log(2, "Running")
        file.close("init.lua")
        
        runlua("application")
        runlua("mpu6050")
    end
end

