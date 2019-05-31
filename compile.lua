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

function checkCompileConfig()
    if COMPILELUA == false then
       dropCompile() 
    end
end