SSID="FeiLong_Route"
PASSWORD="QweR0219"
HOSTNAME="Wifi-Gyro"
PORT=26760
DEBUGMSG=true
WAITTIME=3000
IICID=0
IICSDA=2
IICSCL=1
MPUADDR=0x68

function debugMsg(msg)
    if DEBUGMSG == true then
        print(msg);
    end
end
