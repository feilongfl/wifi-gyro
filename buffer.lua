function readUInt16LE(data, offset)
    a,b = string.byte(data ,offset, offset + 1);
    return bit.bor(bit.lshift(b, 8), a);
end

function readUInt32LE(data, offset)
    a,b,c,d = string.byte(data ,offset, offset + 3);
    return bit.bor(bit.lshift(d, 24),bit.lshift(c, 16),bit.lshift(b, 8), a);
end

function writeUInt16LE(data)
    a,b = number.fromUint16ToBytes(data)
    return {b,a};
end

function writeUInt32LE(data)
    a,b,c,d = number.fromUint32ToBytes(data)
    return {d,c,b,a}
end

function writeFloatLE(data)
    a,b,c,d = float.fromFloattoByteArray(data)
    return {d,c,b,a}
end

function replace_char(pos, str, r)
    return str:sub(1, pos-1) .. r .. str:sub(pos+r:len())
end

function table_insert_byte(t, v)
    -- table.insert(t, string.char(v))
    t[#t + 1] = string.char(v)
end

function ByteTableToString(t)
    local tt = {}
    for _,v in pairs(t) do 
        tt[#tt + 1] = string.char(v)
    end
    return table.concat(tt)
end
