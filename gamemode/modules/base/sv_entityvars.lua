local meta = FindMetaTable("Player")

local LynxonsRPVars = {}
local privateLynxonsRPVars = {}

--[[---------------------------------------------------------------------------
Pooled networking strings
---------------------------------------------------------------------------]]
util.AddNetworkString("LynxonsRP_InitializeVars")
util.AddNetworkString("LynxonsRP_PlayerVar")
util.AddNetworkString("LynxonsRP_PlayerVarRemoval")
util.AddNetworkString("LynxonsRP_LynxonsRPVarDisconnect")

--[[---------------------------------------------------------------------------
Player vars
---------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
Remove a player's LynxonsRPVar
---------------------------------------------------------------------------]]
function meta:removeLynxonsRPVar(var, target)
    local vars = LynxonsRPVars[self]
    hook.Call("LynxonsRPVarChanged", nil, self, var, vars and vars[var], nil)
    target = target or player.GetAll()

    LynxonsRPVars[self] = LynxonsRPVars[self] or {}
    LynxonsRPVars[self][var] = nil

    net.Start("LynxonsRP_PlayerVarRemoval")
        net.WriteUInt(self:UserID(), 16)
        LynxonsRP.writeNetLynxonsRPVarRemoval(var)
    net.Send(target)
end

--[[---------------------------------------------------------------------------
Set a player's LynxonsRPVar
---------------------------------------------------------------------------]]
function meta:setLynxonsRPVar(var, value, target)
    target = target or player.GetAll()

    if value == nil then return self:removeLynxonsRPVar(var, target) end

    local vars = LynxonsRPVars[self]
    hook.Call("LynxonsRPVarChanged", nil, self, var, vars and vars[var], value)

    LynxonsRPVars[self] = LynxonsRPVars[self] or {}
    LynxonsRPVars[self][var] = value

    net.Start("LynxonsRP_PlayerVar")
        net.WriteUInt(self:UserID(), 16)
        LynxonsRP.writeNetLynxonsRPVar(var, value)
    net.Send(target)
end

--[[---------------------------------------------------------------------------
Set a private LynxonsRPVar
---------------------------------------------------------------------------]]
function meta:setSelfLynxonsRPVar(var, value)
    privateLynxonsRPVars[self] = privateLynxonsRPVars[self] or {}
    privateLynxonsRPVars[self][var] = true

    self:setLynxonsRPVar(var, value, self)
end

--[[---------------------------------------------------------------------------
Get a LynxonsRPVar
---------------------------------------------------------------------------]]
function meta:getLynxonsRPVar(var, fallback)
    local vars = LynxonsRPVars[self]
    if vars == nil then return fallback end

    local results = vars[var]
    if results == nil then return fallback end

    return results
end

--[[---------------------------------------------------------------------------
Backwards compatibility: Set ply.LynxonsRPVars attribute
---------------------------------------------------------------------------]]
function meta:setLynxonsRPVarsAttribute()
    LynxonsRPVars[self] = LynxonsRPVars[self] or {}
    -- With a reference to the table, ply.LynxonsRPVars should always remain
    -- up-to-date. One needs only be careful that LynxonsRPVars[ply] is never
    -- replaced by a different table.
    self.LynxonsRPVars = LynxonsRPVars[self]
end


--[[---------------------------------------------------------------------------
Send the LynxonsRPVars to a client
---------------------------------------------------------------------------]]
function meta:sendLynxonsRPVars()
    if self:EntIndex() == 0 then return end

    local plys = player.GetAll()

    net.Start("LynxonsRP_InitializeVars")
        net.WriteUInt(#plys, 8)
        for _, target in ipairs(plys) do
            net.WriteUInt(target:UserID(), 16)

            local vars = {}
            for var, value in pairs(LynxonsRPVars[target] or {}) do
                if self ~= target and (privateLynxonsRPVars[target] or {})[var] then continue end
                table.insert(vars, var)
            end

            local vars_cnt = #vars
            net.WriteUInt(vars_cnt, LynxonsRP.LynxonsRP_ID_BITS + 2) -- Allow for three times as many unknown LynxonsRPVars than the limit
            for i = 1, vars_cnt, 1 do
                LynxonsRP.writeNetLynxonsRPVar(vars[i], LynxonsRPVars[target][vars[i]])
            end
        end
    net.Send(self)
end
concommand.Add("_sendLynxonsRPvars", function(ply)
    if ply.LynxonsRPVarsSent and ply.LynxonsRPVarsSent > (CurTime() - 3) then return end -- prevent spammers
    ply.LynxonsRPVarsSent = CurTime()
    ply:sendLynxonsRPVars()
end)

--[[---------------------------------------------------------------------------
Admin LynxonsRPVar commands
---------------------------------------------------------------------------]]
local function setRPName(ply, args)
    if not args[2] or string.len(args[2]) < 2 or string.len(args[2]) > 30 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), "<2/>30"))
        return
    end

    local name = table.concat(args, " ", 2)

    local target = LynxonsRP.findPlayer(args[1])

    if not target then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", args[1]))
        return
    end

    local oldname = target:Nick()

    LynxonsRP.retrieveRPNames(name, function(taken)
        if not IsValid(target) then return end

        if taken then
            LynxonsRP.notify(ply, 1, 5, LynxonsRP.getPhrase("unable", "RPname", LynxonsRP.getPhrase("already_taken")))
            return
        end

        LynxonsRP.storeRPName(target, name)
        target:setLynxonsRPVar("rpname", name)

        LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("you_set_x_name", oldname, name))

        local nick = ""
        if ply:EntIndex() == 0 then
            nick = "Console"
        else
            nick = ply:Nick()
        end
        LynxonsRP.notify(target, 0, 4, LynxonsRP.getPhrase("x_set_your_name", nick, name))
        if ply:EntIndex() == 0 then
            LynxonsRP.log("Console set " .. target:SteamName() .. "'s name to " .. name, Color(30, 30, 30))
        else
            LynxonsRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") set " .. target:SteamName() .. "'s name to " .. name, Color(30, 30, 30))
        end
    end)
end
LynxonsRP.definePrivilegedChatCommand("forcerpname", "LynxonsRP_AdminCommands", setRPName)

local function freerpname(ply, args)
    local name = args ~= "" and args or IsValid(ply) and ply:Nick() or ""

    MySQLite.query(("UPDATE LynxonsRP_player SET rpname = NULL WHERE rpname = %s"):format(MySQLite.SQLStr(name)))

    local nick = IsValid(ply) and ply:Nick() or "Console"
    LynxonsRP.log(("%s has freed the rp name '%s'"):format(nick, name), Color(30, 30, 30))
    LynxonsRP.notify(ply, 0, 4, ("'%s' has been freed"):format(name))
end
LynxonsRP.definePrivilegedChatCommand("freerpname", "LynxonsRP_AdminCommands", freerpname)

local function RPName(ply, args)
    if ply.LastNameChange and ply.LastNameChange > (CurTime() - 5) then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("have_to_wait", math.ceil(5 - (CurTime() - ply.LastNameChange)), "/rpname"))
        return ""
    end

    if not GAMEMODE.Config.allowrpnames then
        LynxonsRP.notify(ply, 1, 6, LynxonsRP.getPhrase("disabled", "/rpname", ""))
        return ""
    end

    args = args:find"^%s*$" and '' or args:match"^%s*(.*%S)"

    local canChangeName, reason = hook.Call("CanChangeRPName", GAMEMODE, ply, args)
    if canChangeName == false then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", "/rpname", reason or ""))
        return ""
    end

    ply:setRPName(args)
    ply.LastNameChange = CurTime()
    return ""
end
LynxonsRP.defineChatCommand("rpname", RPName)
LynxonsRP.defineChatCommand("name", RPName)
LynxonsRP.defineChatCommand("nick", RPName)

--[[---------------------------------------------------------------------------
Setting the RP name
---------------------------------------------------------------------------]]
function meta:setRPName(name, firstRun)
    -- Make sure nobody on this server already has this RP name
    local lowername = string.lower(tostring(name))
    LynxonsRP.retrieveRPNames(name, function(taken)
        if not IsValid(self) or string.len(lowername) < 2 and not firstrun then return end
        -- If we found that this name exists for another player
        if taken then
            if firstRun then
                -- If we just connected and another player happens to be using our steam name as their RP name
                -- Put a 1 after our steam name
                LynxonsRP.storeRPName(self, name .. " 1")
                LynxonsRP.notify(self, 0, 12, LynxonsRP.getPhrase("someone_stole_steam_name"))
            else
                LynxonsRP.notify(self, 1, 5, LynxonsRP.getPhrase("unable", "/rpname", LynxonsRP.getPhrase("already_taken")))
                return ""
            end
        else
            if not firstRun then -- Don't save the steam name in the database
                LynxonsRP.notifyAll(2, 6, LynxonsRP.getPhrase("rpname_changed", self:SteamName(), name))
                LynxonsRP.storeRPName(self, name)
            end
        end
    end)
end

--[[---------------------------------------------------------------------------
Maximum entity values
---------------------------------------------------------------------------]]
local maxEntities = {}
function meta:addCustomEntity(entTable)
    maxEntities[self] = maxEntities[self] or {}
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] or 0
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] + 1
end

function meta:removeCustomEntity(entTable)
    maxEntities[self] = maxEntities[self] or {}
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] or 0
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] - 1
end

function meta:customEntityLimitReached(entTable)
    maxEntities[self] = maxEntities[self] or {}
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] or 0
    local max = entTable.getMax and entTable.getMax(self) or entTable.max

    return max ~= 0 and maxEntities[self][entTable.cmd] >= max
end

function meta:customEntityCount(entTable)
    local entities = maxEntities[self]
    if entities == nil then return 0 end

    entities = entities[entTable.cmd]
    if entities == nil then return 0 end

    return entities
end

hook.Add("PlayerDisconnected", "LynxonsRP_VarRemoval", function(ply)
    maxEntities[ply] = nil

    net.Start("LynxonsRP_LynxonsRPVarDisconnect")
        net.WriteUInt(ply:UserID(), 16)
    net.Broadcast()
end)

hook.Add("EntityRemoved", "LynxonsRP_VarRemoval", function(ent) -- We use EntityRemoved to clear players of tables, because it is always called after the PlayerDisconnected hook
    if ent:IsPlayer() then
        LynxonsRPVars[ent] = nil
        privateLynxonsRPVars[ent] = nil
    end
end)
