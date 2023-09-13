local plyMeta = FindMetaTable("Player")
local finishWarrantRequest
local arrestedPlayers = {}

--[[---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------]]
function plyMeta:warrant(warranter, reason)
    if self.warranted then return end
    local suppressMsg = hook.Call("playerWarranted", GAMEMODE, self, warranter, reason)

    self.warranted = true
    timer.Simple(GAMEMODE.Config.searchtime, function()
        if not IsValid(self) then return end
        self:unWarrant(warranter)
    end)

    if suppressMsg then return end

    local warranterNick = IsValid(warranter) and warranter:Nick() or LynxonsRP.getPhrase("disconnected_player")
    local centerMessage = LynxonsRP.getPhrase("warrant_approved", self:Nick(), reason, warranterNick)
    local printMessage = LynxonsRP.getPhrase("warrant_ordered", warranterNick, self:Nick(), reason)

    for _, b in ipairs(player.GetAll()) do
        b:PrintMessage(HUD_PRINTCENTER, centerMessage)
        b:PrintMessage(HUD_PRINTCONSOLE, printMessage)
    end

    LynxonsRP.notify(warranter, 0, 4, LynxonsRP.getPhrase("warrant_approved2"))
end

function plyMeta:unWarrant(unwarranter)
    if not self.warranted then return end

    local suppressMsg = hook.Call("playerUnWarranted", GAMEMODE, self, unwarranter)

    self.warranted = false

    if suppressMsg then return end

    LynxonsRP.notify(unwarranter, 2, 4, LynxonsRP.getPhrase("warrant_expired", self:Nick()))
end

function plyMeta:requestWarrant(suspect, actor, reason)
    local question = LynxonsRP.getPhrase("warrant_request", actor:Nick(), suspect:Nick(), reason)
    LynxonsRP.createQuestion(question, suspect:EntIndex() .. "warrant", self, 40, finishWarrantRequest, actor, suspect, reason)
end

function plyMeta:wanted(actor, reason, time)
    local suppressMsg = hook.Call("playerWanted", LynxonsRP.hooks, self, actor, reason)

    self:setLynxonsRPVar("wanted", true)
    self:setLynxonsRPVar("wantedReason", reason)

    if time and time > 0 or GAMEMODE.Config.wantedtime > 0 then
        timer.Create(self:SteamID64() .. " wantedtimer", time or GAMEMODE.Config.wantedtime, 1, function()
            if not IsValid(self) then return end
            self:unWanted()
        end)
    end

    if suppressMsg then return end

    local actorNick = IsValid(actor) and actor:Nick() or LynxonsRP.getPhrase("disconnected_player")
    local centerMessage = LynxonsRP.getPhrase("wanted_by_police", self:Nick(), reason, actorNick)
    local printMessage = LynxonsRP.getPhrase("wanted_by_police_print", actorNick, self:Nick(), reason)

    for _, ply in ipairs(player.GetAll()) do
        ply:PrintMessage(HUD_PRINTCENTER, centerMessage)
        ply:PrintMessage(HUD_PRINTCONSOLE, printMessage)
    end

    LynxonsRP.log(string.Replace(printMessage, "\n", " "), Color(0, 150, 255))
end

function plyMeta:unWanted(actor)
    local suppressMsg = hook.Call("playerUnWanted", GAMEMODE, self, actor)
    self:setLynxonsRPVar("wanted", nil)
    self:setLynxonsRPVar("wantedReason", nil)

    timer.Remove(self:SteamID64() .. " wantedtimer")

    if suppressMsg then return end

    local expiredMessage = IsValid(actor) and LynxonsRP.getPhrase("wanted_revoked", self:Nick(), actor:Nick() or "") or
        LynxonsRP.getPhrase("wanted_expired", self:Nick())

    LynxonsRP.log(string.Replace(expiredMessage, "\n", " "), Color(0, 150, 255))

    for _, ply in ipairs(player.GetAll()) do
        ply:PrintMessage(HUD_PRINTCENTER, expiredMessage)
        ply:PrintMessage(HUD_PRINTCONSOLE, expiredMessage)
    end
end

function plyMeta:arrest(time, arrester)
    time = time or GAMEMODE.Config.jailtimer or 120

    hook.Call("playerArrested", LynxonsRP.hooks, self, time, arrester)
    if self:InVehicle() then self:ExitVehicle() end
    self:setLynxonsRPVar("Arrested", true)
    arrestedPlayers[self:SteamID()] = true

    -- Always get sent to jail when Arrest() is called, even when already under arrest
    if GAMEMODE.Config.teletojail and LynxonsRP.jailPosCount() ~= 0 then
        self:Spawn()
    end
end

function plyMeta:unArrest(unarrester, teleportOverride)
    if not self:isArrested() then return end

    self:setLynxonsRPVar("Arrested", nil)
    arrestedPlayers[self:SteamID()] = nil
    hook.Call("playerUnArrested", LynxonsRP.hooks, self, unarrester, teleportOverride)
end

--[[---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------]]
local function CombineRequest(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return
        end

        local col = team.GetColor(ply:Team())
        local col2 = Color(255, 0, 0, 255)
        local phrase = LynxonsRP.getPhrase("request")
        local name = ply:Nick()
        for _, v in ipairs(player.GetAll()) do
            if v:isCP() or v == ply then
                LynxonsRP.talkToPerson(v, col, phrase .. " " .. name, col2, text, ply)
            end
        end
    end
    return args, DoSay
end
for _, cmd in ipairs{"cr", "911", "999", "112", "000"} do
    LynxonsRP.defineChatCommand(cmd, CombineRequest, 1.5)
end

local function warrantCommand(ply, args)
    local target = LynxonsRP.findPlayer(args[1])
    local reason = table.concat(args, " ", 2)

    local canRequest, message = hook.Call("canRequestWarrant", LynxonsRP.hooks, target, ply, reason)
    if not canRequest then
        if message then LynxonsRP.notify(ply, 1, 4, message) end
        return ""
    end

    local Team = ply:Team()
    if not RPExtraTeams[Team] or not RPExtraTeams[Team].mayor then -- No need to search through all the teams if the player is a mayor
        local mayors = {}

        for k, v in pairs(RPExtraTeams) do
            if v.mayor then
                table.Add(mayors, team.GetPlayers(k))
            end
        end

        if not table.IsEmpty(mayors) then -- Request a warrant if there's a mayor
            local mayor = table.Random(mayors)
            mayor:requestWarrant(target, ply, reason)
            LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("warrant_request2", mayor:Nick()))
            return ""
        end
    end

    target:warrant(ply, reason)

    return ""
end
LynxonsRP.defineChatCommand("warrant", warrantCommand)

local function unwarrantCommand(ply, args)
    local target = LynxonsRP.findPlayer(args[1])
    local reason = table.concat(args, " ", 2)

    local canRemove, message = hook.Call("canRemoveWarrant", LynxonsRP.hooks, target, ply, reason)
    if not canRemove then
        if message then LynxonsRP.notify(ply, 1, 4, message) end
        return ""
    end

    target:unWarrant(ply, reason)

    return ""
end
LynxonsRP.defineChatCommand("unwarrant", unwarrantCommand)

local function wantedCommand(ply, args)
    local target = LynxonsRP.findPlayer(args[1])
    local reason = table.concat(args, " ", 2)

    local canWanted, message = hook.Call("canWanted", LynxonsRP.hooks, target, ply, reason)
    if not canWanted then
        if message then LynxonsRP.notify(ply, 1, 4, message) end
        return ""
    end

    target:wanted(ply, reason)

    return ""
end
LynxonsRP.defineChatCommand("wanted", wantedCommand)

local function unwantedCommand(ply, args)
    local target = LynxonsRP.findPlayer(args)

    local canUnwant, message = hook.Call("canUnwant", LynxonsRP.hooks, target, ply)
    if not canUnwant then
        if message then LynxonsRP.notify(ply, 1, 4, message) end
        return ""
    end

    target:unWanted(ply)

    return ""
end
LynxonsRP.defineChatCommand("unwanted", unwantedCommand)

--[[---------------------------------------------------------------------------
Admin commands
---------------------------------------------------------------------------]]
local function ccArrest(ply, args)
    if LynxonsRP.jailPosCount() == 0 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("no_jail_pos"))
        return
    end

    local targets = LynxonsRP.findPlayers(args[1])

    if not targets then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", args[1]))
        return
    end

    for _, target in pairs(targets) do
        local length = tonumber(args[2])
        if length then
            target:arrest(length, ply)
        else
            target:arrest(nil, ply)
        end

        if ply:EntIndex() == 0 then
            LynxonsRP.log("Console force-arrested " .. target:SteamName(), Color(0, 255, 255))
        else
            LynxonsRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-arrested " .. target:SteamName(), Color(0, 255, 255))
        end
    end
end
LynxonsRP.definePrivilegedChatCommand("arrest", "LynxonsRP_AdminCommands", ccArrest)

local function ccUnarrest(ply, args)
    local targets = LynxonsRP.findPlayers(args[1])

    if not targets then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", args[1]))
        return
    end

    for _, target in pairs(targets) do
        target:unArrest(ply)
        if not target:Alive() then target:Spawn() end

        if ply:EntIndex() == 0 then
            LynxonsRP.log("Console force-unarrested " .. target:SteamName(), Color(0, 255, 255))
        else
            LynxonsRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-unarrested " .. target:SteamName(), Color(0, 255, 255))
        end
    end
end
LynxonsRP.definePrivilegedChatCommand("unarrest", "LynxonsRP_AdminCommands", ccUnarrest)

--[[---------------------------------------------------------------------------
Callback functions
---------------------------------------------------------------------------]]
function finishWarrantRequest(choice, mayor, initiator, suspect, reason)
    if not tobool(choice) then
        LynxonsRP.notify(initiator, 1, 4, LynxonsRP.getPhrase("warrant_denied", mayor:Nick()))
        return
    end
    if IsValid(suspect) then
        suspect:warrant(initiator, reason)
    end
end

--[[---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------]]

function LynxonsRP.hooks:canArrest(arrester, arrestee)
    if IsValid(arrestee) and arrestee:IsPlayer() and arrestee:isCP() and not GAMEMODE.Config.cpcanarrestcp then
        return false, LynxonsRP.getPhrase("cant_arrest_other_cp")
    end

    if not GAMEMODE.Config.npcarrest and arrestee:IsNPC() then
        return false, LynxonsRP.getPhrase("unable", "arrest", "NPC")
    end

    if GAMEMODE.Config.needwantedforarrest and not arrestee:IsNPC() and not arrestee:getLynxonsRPVar("wanted") then
        return false, LynxonsRP.getPhrase("must_be_wanted_for_arrest")
    end

    if arrestee:IsPlayer() and arrestee.FAdmin_GetGlobal and arrestee:FAdmin_GetGlobal("fadmin_jailed") then
        return false, LynxonsRP.getPhrase("cant_arrest_fadmin_jailed")
    end

    local jpc = LynxonsRP.jailPosCount()

    if not jpc or jpc == 0 then
        return false, LynxonsRP.getPhrase("cant_arrest_no_jail_pos")
    end

    if arrestee.Babygod then
        return false, LynxonsRP.getPhrase("cant_arrest_spawning_players")
    end

    return true
end

function LynxonsRP.hooks:playerArrested(ply, time, arrester)
    if ply:isWanted() then ply:unWanted(arrester) end
    local job = RPExtraTeams[ply:Team()]
    if not job or not job.hasLicense then
        ply:setLynxonsRPVar("HasGunlicense", nil)
    end

    ply:StripWeapons()
    ply:StripAmmo()

    if ply:isArrested() then return end -- hasn't been arrested before

    ply:PrintMessage(HUD_PRINTCENTER, LynxonsRP.getPhrase("youre_arrested", time))

    local phrase = LynxonsRP.getPhrase("hes_arrested", ply:Nick(), time)
    for _, v in ipairs(player.GetAll()) do
        if v == ply then continue end
        v:PrintMessage(HUD_PRINTCENTER, phrase)
    end

    local steamID = ply:SteamID()
    timer.Create(ply:SteamID64() .. "jailtimer", time, 1, function()
        if IsValid(ply) then ply:unArrest() end
        arrestedPlayers[steamID] = nil
    end)
    umsg.Start("GotArrested", ply)
        umsg.Float(time)
    umsg.End()
end

function LynxonsRP.hooks:playerUnArrested(ply, actor, teleportOverride)
    if ply:InVehicle() then ply:ExitVehicle() end

    if ply.Sleeping then
        LynxonsRP.toggleSleep(ply, "force")
    end

    if not ply:Alive() and not GAMEMODE.Config.respawninjail then
        ply.NextSpawnTime = CurTime()
    end

    gamemode.Call("PlayerLoadout", ply)
    -- teleportOverride can either be nil, false, or a vector. Nil means "do not
    -- modify behavior", false means "do not teleport", and a vector means
    -- "teleport to this place instead"
    if (GAMEMODE.Config.telefromjail or teleportOverride ~= nil) and teleportOverride ~= false then
        local pos
        if isvector(teleportOverride) then
            pos = teleportOverride
        else
            local ent
            ent, pos = hook.Call("PlayerSelectSpawn", GAMEMODE, ply)
            pos = pos or ent:GetPos()
        end
        -- workaround for SetPos in weapon event bug
        timer.Simple(0, function() if IsValid(ply) then ply:SetPos(pos) end end)
    end

    timer.Remove(ply:SteamID64() .. "jailtimer")
    LynxonsRP.notifyAll(0, 4, LynxonsRP.getPhrase("hes_unarrested", ply:Nick()))
end

hook.Add("PlayerInitialSpawn", "Arrested", function(ply)
    if not arrestedPlayers[ply:SteamID()] then return end
    local time = GAMEMODE.Config.jailtimer
    -- Delay the actual arrest by a single frame to allow
    -- the player to initialise
    timer.Simple(0, function()
        -- In case the timer ended right this tick
        if not IsValid(ply) or not arrestedPlayers[ply:SteamID()] then return end

        ply:arrest(time)
    end)
    LynxonsRP.notify(ply, 0, 5, LynxonsRP.getPhrase("jail_punishment", time))
end)

function LynxonsRP.hooks:canGiveLicense(ply, target)
    -- Mayors can hand out licenses
    if ply:isMayor() then return true end

    local reason = LynxonsRP.getPhrase("incorrect_job", "/givelicense")

    local players = player.GetAll()
    -- Chiefs can if there is no mayor
    local mayorExists = #fn.Filter(plyMeta.isMayor, players) > 0
    if mayorExists then return false, reason end

    if ply:isChief() then return true end

    -- CPs can if there are no chiefs nor mayors
    local chiefExists = #fn.Filter(plyMeta.isChief, players) > 0
    if chiefExists then return false, reason end

    if ply:isCP() then return true end

    return false, reason
end
