local function storeJail(ply, add, hasAccess)
    if not IsValid(ply) then return end

    -- Admin or Chief can set the Jail Position
    local Team = ply:Team()
    if (RPExtraTeams[Team] and RPExtraTeams[Team].chief and GAMEMODE.Config.chiefjailpos) or hasAccess then
        LynxonsRP.storeJailPos(ply, add)
    else
        local str = LynxonsRP.getPhrase("admin_only")
        if GAMEMODE.Config.chiefjailpos then
            str = LynxonsRP.getPhrase("chief_or") .. str
        end

        LynxonsRP.notify(ply, 1, 4, str)
    end
end
local function JailPos(ply)
    CAMI.PlayerHasAccess(ply, "LynxonsRP_AdminCommands", fp{storeJail, ply, false})

    return ""
end
LynxonsRP.defineChatCommand("jailpos", JailPos)
LynxonsRP.defineChatCommand("setjailpos", JailPos)

local function AddJailPos(ply)
    CAMI.PlayerHasAccess(ply, "LynxonsRP_AdminCommands", fp{storeJail, ply, true})

    return ""
end
LynxonsRP.defineChatCommand("addjailpos", AddJailPos)
