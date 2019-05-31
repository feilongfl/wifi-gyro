function Log(level, msg)
    if(level >= DEBUGLEVEL) then
        print(string.format("[%s][%d] -> %s", debugLevelMessage[level], tmr.now(), msg));
    end
end

ta = tmr.now()
function timeDebug(msg)
    tb = tmr.now()
    print(string.format("[time][%s][%d] -> %dus", msg, tb, tb - ta))
    ta = tmr.now()
end
