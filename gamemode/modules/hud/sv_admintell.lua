--[[---------------------------------------------------------------------------
Messages
---------------------------------------------------------------------------]]
local function ccTell(ply, args)
    local target = LynxonsRP.findPlayer(args[1])

    if target then
        local msg = ""

        for n = 2, #args do
            msg = msg .. args[n] .. " "
        end

        umsg.Start("AdminTell", target)
            umsg.String(msg)
        umsg.End()

        if ply:EntIndex() == 0 then
            LynxonsRP.log("Console did admintell \"" .. msg .. "\" on " .. target:SteamName(), Color(30, 30, 30))
        else
            LynxonsRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") did admintell \"" .. msg .. "\" on " .. target:SteamName(), Color(30, 30, 30))
        end
    else
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(args[1])))
    end
end
LynxonsRP.definePrivilegedChatCommand("admintell", "LynxonsRP_AdminCommands", ccTell)

local function ccTellAll(ply, args)
    umsg.Start("AdminTell")
        umsg.String(args)
    umsg.End()

    if ply:EntIndex() == 0 then
        LynxonsRP.log("Console did admintellall \"" .. args .. "\"", Color(30, 30, 30))
    else
        LynxonsRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") did admintellall \"" .. args .. "\"", Color(30, 30, 30))
    end

end
LynxonsRP.definePrivilegedChatCommand("admintellall", "LynxonsRP_AdminCommands", ccTellAll)
