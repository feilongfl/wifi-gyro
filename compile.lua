function dropCompile()
    for k, v in pairs(file.list("lc")) do
        Log(3, string.format("Drop file %s!", k))
        file.remove(k)
    end
end

function runlua(name)
    local lcname = name .. '.lc'
    local luaname = name .. '.lua'

    if file.exists(luaname) and COMPILELUA then
        if file.exists(lcname) then file.remove(lcname) end
        Log(3, string.format("File %s found! Compile to %s", luaname, lcname))
        node.compile(luaname)
        file.remove(luaname)
        dofile(lcname)
    elseif file.exists(lcname) then
        dofile(lcname)
    else
        Log(4, string.format("File %s/%s not found!", luaname, lcname))
    end
end
