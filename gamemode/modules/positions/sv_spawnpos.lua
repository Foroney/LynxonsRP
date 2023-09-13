local function SetSpawnPos(ply, args)
    local pos = ply:GetPos()
    local t

    for k, v in pairs(RPExtraTeams) do
        if args == v.command then
            t = k
            LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("updated_spawnpos", v.name))
            break
        end
    end

    if t then
        LynxonsRP.storeTeamSpawnPos(t, {pos.x, pos.y, pos.z})
    else
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(args)))
    end
end
LynxonsRP.definePrivilegedChatCommand("setspawn", "LynxonsRP_AdminCommands", SetSpawnPos)

local function AddSpawnPos(ply, args)
    local pos = ply:GetPos()
    local t

    for k, v in pairs(RPExtraTeams) do
        if args == v.command then
            t = k
            LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("created_spawnpos", v.name))
            break
        end
    end

    if t then
        LynxonsRP.addTeamSpawnPos(t, {pos.x, pos.y, pos.z})
    else
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(args)))
    end
end
LynxonsRP.definePrivilegedChatCommand("addspawn", "LynxonsRP_AdminCommands", AddSpawnPos)

local function RemoveSpawnPos(ply, args)
    local t

    for k, v in pairs(RPExtraTeams) do
        if args == v.command then
            t = k
            LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("remove_spawnpos", v.name))
            break
        end
    end

    if t then
        LynxonsRP.removeTeamSpawnPos(t)
    else
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(args)))
    end
end
LynxonsRP.definePrivilegedChatCommand("removespawn", "LynxonsRP_AdminCommands", RemoveSpawnPos)
