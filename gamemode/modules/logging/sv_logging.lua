local function AdminLog(message, colour, allowedPlys)
    local RF = RecipientFilter()
    for _, v in pairs(allowedPlys) do
        local canHear = hook.Call("canSeeLogMessage", GAMEMODE, v, message, colour)

        if canHear then
            RF:AddPlayer(v)
        end
    end

    umsg.Start("DRPLogMsg", RF)
        umsg.Short(colour.r)
        umsg.Short(colour.g)
        umsg.Short(colour.b) -- Alpha is not needed
        umsg.String(message)
    umsg.End()
end

local LynxonsRPFile
function LynxonsRP.log(text, colour, noFileSave)
    if colour then
        CAMI.GetPlayersWithAccess("LynxonsRP_SeeEvents", fp{AdminLog, text, colour})
    end

    if not GAMEMODE.Config.logging or noFileSave then return end

    if not LynxonsRPFile then -- The log file of this session, if it's not there then make it!
        if not file.IsDir("LynxonsRP_logs", "DATA") then
            file.CreateDir("LynxonsRP_logs")
        end

        LynxonsRPFile = "LynxonsRP_logs/" .. os.date("%m_%d_%Y %I_%M %p") .. ".txt"
        file.Write(LynxonsRPFile, os.date() .. "\t" .. text)
        return
    end
    file.Append(LynxonsRPFile, "\n" .. os.date() .. "\t" .. (text or ""))
end
