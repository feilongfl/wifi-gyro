lastData = ""

-- data type
DSUC_VersionReq = 0x100000
DSUS_PortInfo = 0x100001
DSUC_PadDataReq = 0x100002

maxProtocolVer = 1001
serverID = 0x12345678

lastRequestTime = nil
lastRequestIP = nil
lastRequestPORT = nil
lastRequestSockets = nil

function onUDPRecv(s, data, port, ip)
    -- debugMsg(string.format("received '%s' from %s:%d", data, ip, port))
    decodeData(data, s, port, ip)
end

Log(2, "init server at port => " .. PORT .. "...")
if udpSocket == nil then
    udpSocket = net.createUDPSocket()
    udpSocket:listen(PORT)
end
udpSocket:on("receive", onUDPRecv)
port, ip = udpSocket:getaddr()
Log(2, string.format("local UDP socket address / port: %s:%d", ip, PORT))
