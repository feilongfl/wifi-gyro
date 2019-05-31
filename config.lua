SSID="FeiLong_Route"
PASSWORD="QweR0219"
HOSTNAME="Wifi-Gyro"
PORT=26760
WAITTIME=3000
IICID=0
IICSDA=2
IICSCL=1
MPUADDR=0x68
COMPILELUA=true
COMPILECHECKFILE='.compile'
debugLevelMessage = {'debug', 'info', 'warning', 'error'}
DEBUGLEVEL = 1

function Log(level, msg)
    if(level > DEBUGLEVEL) then
        print(string.format("[%s][%d] -> %s", debugLevelMessage[level], tmr.now(), msg));
    end
end

ta = tmr.now()
function timeDebug(msg)
    tb = tmr.now()
    print(tb, msg, tb - ta)
    ta = tmr.now()
end
