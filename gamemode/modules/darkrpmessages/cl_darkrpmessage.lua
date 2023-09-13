local MotdMessage =
[[
===========================================================================
                        Добро пожаловать на сервер!
===========================================================================
]]

local function drawMOTD(text)
    MsgC(Color(255, 20, 20, 255), MotdMessage, color_white, text, Color(255, 20, 20, 255))
end

local function receiveMOTD(html, len, headers, code)
    if not headers or headers.Status and string.sub(headers.Status, 1, 3) ~= "200" then return end
    drawMOTD(html)
end

local function showMOTD()
    http.Fetch("https://raw.githubusercontent.com/Foroney/LynxonsRPMotd/master/motd.txt", receiveMOTD, fn.Id)
end
timer.Simple(5, showMOTD)

concommand.Add("LynxonsRP_motd", MotdMessage)
