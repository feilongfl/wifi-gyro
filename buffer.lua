function readUInt16LE(data, offset)
    a,b = string.byte(data ,offset, offset + 1);
    return bit.bor(bit.lshift(b, 8), a);
end

function readUInt32LE(data, offset)
    a,b,c,d = string.byte(data ,offset, offset + 3);
    return bit.bor(bit.lshift(d, 24),bit.lshift(c, 16),bit.lshift(b, 8), a);
end

function writeUInt16LE(data)
    local t = {};
    for i = 0,1 do
        t[i + 1] = bit.band(0xff,bit.rshift(data, 8*i));
    end
    return t
end

function writeUInt32LE(data)
    local t = {};
    for i = 0,3 do
        t[i + 1] = bit.band(0xff,bit.rshift(data, 8*i));
    end
    return t
end

function writeFloatLE(data)
    a,b,c,d = float.fromFloattoByteArray(data)
    return {d,c,b,a}
end
