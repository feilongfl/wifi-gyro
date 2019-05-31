-- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("config.lua")

function dropCompile()
    for k,v in pairs(file.list("lc")) do 
        Log(3, string.format("Drop file %s!", k))
        file.remove(k)
    end
end

function runlua(name)
    local lcname = name .. '.lc'
    local luaname = name .. '.lua'

    if file.exists(lcname) then
        dofile(lcname)
    elseif COMPILELUA then
        Log(3, string.format("File %s not found! Compile from %s", lcname, luaname))
        node.compile(luaname)
        dofile(lcname)
    else
        dofile(luaname)
    end
end

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

