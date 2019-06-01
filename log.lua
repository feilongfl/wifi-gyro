function Log(level, msg)
    if (level >= DEBUGLEVEL) then
        print(string.format("[%s][%d] -> %s", debugLevelMessage[level],
                            tmr.now(), msg))
    end
end

pointIndex = 1
function LogPoint()
    if pointIndex == MaxPointLength then
        print(".")
        pointIndex = 1
    else
        uart.write(0, ".")
        pointIndex = pointIndex + 1
    end
end


ta = tmr.now()
function timeDebug(msg)
    tb = tmr.now()
    if TIMEDEBUG then
        print(string.format("[time][%s][%d] -> %dus", msg, tb, tb - ta))
    else
        LogPoint()
    end
    ta = tmr.now()
end

