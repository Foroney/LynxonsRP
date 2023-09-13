--[[---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------]]
local meta = FindMetaTable("Player")
function meta:changeTeam(t, force, suppressNotification, ignoreMaxMembers)
    local prevTeam = self:Team()
    local notify = suppressNotification and fn.Id or LynxonsRP.notify
    local notifyAll = suppressNotification and fn.Id or LynxonsRP.notifyAll

    if self:isArrested() and not force then
        notify(self, 1, 4, LynxonsRP.getPhrase("unable", team.GetName(t), ""))
        return false
    end

    local allowed, time = self:changeAllowed(t)
    if t ~= GAMEMODE.DefaultTeam and not allowed and not force then
        local notif = time and LynxonsRP.getPhrase("have_to_wait", math.ceil(time), "/job, " .. LynxonsRP.getPhrase("banned_or_demoted")) or LynxonsRP.getPhrase("unable", team.GetName(t), LynxonsRP.getPhrase("banned_or_demoted"))
        notify(self, 1, 4, notif)
        return false
    end

    if self.LastJob and GAMEMODE.Config.changejobtime - (CurTime() - self.LastJob) >= 0 and not force then
        notify(self, 1, 4, LynxonsRP.getPhrase("have_to_wait", math.ceil(GAMEMODE.Config.changejobtime - (CurTime() - self.LastJob)), "/job"))
        return false
    end

    if self.IsBeingDemoted then
        self:teamBan()
        self.IsBeingDemoted = false
        self:changeTeam(GAMEMODE.DefaultTeam, true)
        LynxonsRP.destroyVotesWithEnt(self)
        notify(self, 1, 4, LynxonsRP.getPhrase("tried_to_avoid_demotion"))

        return false
    end


    if prevTeam == t then
        notify(self, 1, 4, LynxonsRP.getPhrase("unable", team.GetName(t), ""))
        return false
    end

    local TEAM = RPExtraTeams[t]
    if not TEAM then return false end

    if TEAM.customCheck and not TEAM.customCheck(self) and (not force or force and not GAMEMODE.Config.adminBypassJobRestrictions) then
        local message = isfunction(TEAM.CustomCheckFailMsg) and TEAM.CustomCheckFailMsg(self, TEAM) or
            TEAM.CustomCheckFailMsg or
            LynxonsRP.getPhrase("unable", team.GetName(t), "")
        notify(self, 1, 4, message)
        return false
    end

    if not force then
        if isnumber(TEAM.NeedToChangeFrom) and prevTeam ~= TEAM.NeedToChangeFrom then
            notify(self, 1,4, LynxonsRP.getPhrase("need_to_be_before", team.GetName(TEAM.NeedToChangeFrom), TEAM.name))
            return false
        elseif istable(TEAM.NeedToChangeFrom) and not table.HasValue(TEAM.NeedToChangeFrom, prevTeam) then
            local teamnames = ""
            for _, b in pairs(TEAM.NeedToChangeFrom) do
                teamnames = teamnames .. " or " .. team.GetName(b)
            end
            notify(self, 1, 8, LynxonsRP.getPhrase("need_to_be_before", string.sub(teamnames, 5), TEAM.name))
            return false
        end
        local max = TEAM.max
        local numPlayers = team.NumPlayers(t)
        if not ignoreMaxMembers and
        max ~= 0 and -- No limit
        (max >= 1 and numPlayers >= max or -- absolute maximum
        max < 1 and (numPlayers + 1) / player.GetCount() > max) then -- fractional limit (in percentages)
            notify(self, 1, 4, LynxonsRP.getPhrase("team_limit_reached", TEAM.name))
            return false
        end
    end

    if TEAM.PlayerChangeTeam then
        local val = TEAM.PlayerChangeTeam(self, prevTeam, t)
        if val ~= nil then
            return val
        end
    end

    local hookValue, reason = hook.Call("playerCanChangeTeam", nil, self, t, force)
    if hookValue == false then
        if reason then
            notify(self, 1, 4, reason)
        end
        return false
    end

    local isMayor = RPExtraTeams[prevTeam] and RPExtraTeams[prevTeam].mayor
    if isMayor and GetGlobalBool("LynxonsRP_LockDown") then
        LynxonsRP.unLockdown(self)
    end
    self:updateJob(TEAM.name)
    self:setSelfLynxonsRPVar("salary", TEAM.salary)
    notifyAll(0, 4, LynxonsRP.getPhrase("job_has_become", self:Nick(), TEAM.name))


    if self:getLynxonsRPVar("HasGunlicense") and GAMEMODE.Config.revokeLicenseOnJobChange then
        self:setLynxonsRPVar("HasGunlicense", nil)
    end
    if TEAM.hasLicense then
        self:setLynxonsRPVar("HasGunlicense", true)
    end

    self.LastJob = CurTime()

    if GAMEMODE.Config.removeclassitems then
        -- Must not be ipairs, LynxonsRPEntities might have missing keys when
        -- LynxonsRP.removeEntity is called.
        for _, v in pairs(LynxonsRPEntities) do
            if GAMEMODE.Config.preventClassItemRemoval[v.ent] then continue end
            if not v.allowed then continue end
            if istable(v.allowed) and (table.HasValue(v.allowed, t) or not table.HasValue(v.allowed, prevTeam)) then continue end
            for _, e in ipairs(ents.FindByClass(v.ent)) do
                if e.SID == self.SID then e:Remove() end
            end
        end

        if not GAMEMODE.Config.preventClassItemRemoval["spawned_shipment"] then
            for _, v in ipairs(ents.FindByClass("spawned_shipment")) do
                if v.allowed and istable(v.allowed) and table.HasValue(v.allowed, t) then continue end
                if v.SID == self.SID then v:Remove() end
            end
        end
    end

    if isMayor then
        for _, ent in ipairs(self.lawboards or {}) do
            if IsValid(ent) then
                ent:Remove()
            end
        end
        self.lawboards = {}
    end

    if isMayor and GAMEMODE.Config.shouldResetLaws then
        LynxonsRP.resetLaws()
    end

    local DoEffect = false

    self:SetTeam(t)
    hook.Call("OnPlayerChangedTeam", GAMEMODE, self, prevTeam, t)
    LynxonsRP.log(self:Nick() .. " (" .. self:SteamID() .. ") changed to " .. team.GetName(t), nil, Color(100, 0, 255))
    if self:InVehicle() then self:ExitVehicle() end
    if GAMEMODE.Config.norespawn and self:Alive() then
        if GAMEMODE.Config.keepPickedUp then
            for k, v in ipairs(RPExtraTeams[prevTeam].weapons) do
                self:StripWeapon(v)
            end
        else
            self:StripWeapons()
            self:RemoveAllAmmo()
        end

        DoEffect = true
        player_manager.SetPlayerClass(self, TEAM.playerClass or "player_LynxonsRP")
        self:applyPlayerClassVars(false)
        gamemode.Call("PlayerSetModel", self)
        gamemode.Call("PlayerLoadout", self)
    else
        if GAMEMODE.Config.instantjob then
            DoEffect = true

            self:StripWeapons()
            self:RemoveAllAmmo()
            self:Spawn()
        else
            self:KillSilent()
        end
    end

    if DoEffect then
        local vPoint = self:GetShootPos() + Vector(0,0,50)
        local effectdata = EffectData()
        effectdata:SetEntity(self)
        effectdata:SetStart(vPoint) -- Not sure if we need a start and origin (endpoint) for this effect, but whatever
        effectdata:SetOrigin(vPoint)
        effectdata:SetScale(1)
        util.Effect("entity_remove", effectdata)
    end

    umsg.Start("OnChangedTeam", self)
        umsg.Short(prevTeam)
        umsg.Short(t)
    umsg.End()
    return true
end

function meta:updateJob(job)
    self:setLynxonsRPVar("job", job)
    self.LastJob = CurTime()

    local timerid = self:SteamID64() .. "jobtimer"

    timer.Create(timerid, GAMEMODE.Config.paydelay, 0, function()
        if not IsValid(self) then
            timer.Remove(timerid)
            return
        end
        self:payDay()
    end)
end

function meta:teamUnBan(Team)
    self.bannedfrom = self.bannedfrom or {}

    local group = LynxonsRP.getDemoteGroup(Team)
    self.bannedfrom[group] = nil
end

function meta:teamBan(t, time)
    if not self.bannedfrom then self.bannedfrom = {} end
    t = t or self:Team()

    local group = LynxonsRP.getDemoteGroup(t)
    self.bannedfrom[group] = true

    local timerid = "teamban" .. self:UserID() .. "," .. group.value

    timer.Remove(timerid)

    if time == 0 then return end

    timer.Create(timerid, time or GAMEMODE.Config.demotetime, 1, function()
        if not IsValid(self) then return end
        self:teamUnBan(t)
    end)
end

function meta:teamBanTimeLeft(t)
    local group = LynxonsRP.getDemoteGroup(t or self:Team())
    return timer.TimeLeft("teamban" .. self:UserID() .. "," .. (group and group.value or ""))
end

function meta:changeAllowed(t)
    local group = LynxonsRP.getDemoteGroup(t)
    if self.bannedfrom and self.bannedfrom[group] then return false, self:teamBanTimeLeft(t) end

    return true
end

function GM:canChangeJob(ply, args)
    if ply:isArrested() then return false end
    if ply.LastJob and 10 - (CurTime() - ply.LastJob) >= 0 then return false, LynxonsRP.getPhrase("have_to_wait", math.ceil(10 - (CurTime() - ply.LastJob)), "/job") end
    if not ply:Alive() then return false end

    local len = string.len(args)

    if len < 3 then return false, LynxonsRP.getPhrase("unable", "/job", ">2") end
    if len > 25 then return false, LynxonsRP.getPhrase("unable", "/job", "<26") end

    return true
end

--[[---------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------]]
local function ChangeJob(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end

    if not GAMEMODE.Config.customjobs then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("disabled", "/job", ""))
        return ""
    end

    local canChangeJob, message, replace = gamemode.Call("canChangeJob", ply, args)
    if canChangeJob == false then
        LynxonsRP.notify(ply, 1, 4, message or LynxonsRP.getPhrase("unable", "/job", ""))
        return ""
    end

    local job = replace or args
    LynxonsRP.notifyAll(2, 4, LynxonsRP.getPhrase("job_has_become", ply:Nick(), job))
    ply:updateJob(job)
    return ""
end
LynxonsRP.defineChatCommand("job", ChangeJob)

local function FinishDemote(vote, choice)
    local target = vote.target

    target.IsBeingDemoted = nil
    if choice == 1 then
        target:teamBan()
        if target:Alive() then
            local demoteTeam = hook.Call("demoteTeam", nil, target) or GAMEMODE.DefaultTeam
            target:changeTeam(demoteTeam, true)
            if target:isArrested() then
                target:arrest()
            end
        else
            target.demotedWhileDead = true
        end

        hook.Call("onPlayerDemoted", nil, vote.info.source, target, vote.info.reason)
        LynxonsRP.notifyAll(0, 4, LynxonsRP.getPhrase("demoted", target:Nick()))
    else
        LynxonsRP.notifyAll(1, 4, LynxonsRP.getPhrase("demoted_not", target:Nick()))
    end
end

local function Demote(ply, args)
    if #args == 0 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", "/demote", ""))
        return ""
    end
    if #args == 1 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("vote_specify_reason"))
        return ""
    end
    local reason = table.concat(args, ' ', 2)

    if string.len(reason) > 99 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", "/demote", "<100"))
        return ""
    end
    local p = LynxonsRP.findPlayer(args[1])
    if p == ply then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("cant_demote_self"))
        return ""
    end

    local canDemote, message = hook.Call("canDemote", GAMEMODE, ply, p, reason)
    if canDemote == false then
        LynxonsRP.notify(ply, 1, 4, message or LynxonsRP.getPhrase("unable", "/demote", ""))
        return ""
    end

    if not p then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", args and args[1]))
        return ""
    end

    if CurTime() - ply.LastVoteCop < 80 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("have_to_wait", math.ceil(80 - (CurTime() - ply:GetTable().LastVoteCop)), "/demote"))
        return ""
    end

    local Team = p:Team()
    if not RPExtraTeams[Team] or RPExtraTeams[Team].candemote == false then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", "/demote", ""))
    else
        LynxonsRP.talkToPerson(p, team.GetColor(ply:Team()), LynxonsRP.getPhrase("demote") .. " " .. ply:Nick(), Color(255, 0, 0, 255), LynxonsRP.getPhrase("i_want_to_demote_you", reason), p)

        local voteInfo = LynxonsRP.createVote(p:Nick() .. ":\n" .. LynxonsRP.getPhrase("demote_vote_text", reason), LynxonsRP.getPhrase("demote_vote"), p, 20, FinishDemote, {
            [p] = true,
            [ply] = true
        }, function(vote)
            if not IsValid(vote.target) then return end
            vote.target.IsBeingDemoted = nil
        end, {
            source = ply,
            reason = reason
        })

        if voteInfo then
            -- Vote has started
            LynxonsRP.notifyAll(0, 4, LynxonsRP.getPhrase("demote_vote_started", ply:Nick(), p:Nick()))
            LynxonsRP.log(LynxonsRP.getPhrase("demote_vote_started", string.format("%s(%s)[%s]", ply:Nick(), ply:SteamID(), team.GetName(ply:Team())), string.format("%s(%s)[%s] for %s", p:Nick(), p:SteamID(), team.GetName(p:Team()), reason)), Color(255, 128, 255, 255))
            p.IsBeingDemoted = true
        end
        ply.LastVoteCop = CurTime()
    end
    return ""
end
LynxonsRP.defineChatCommand("demote", Demote)

local function ExecSwitchJob(answer, ent, ply, target)
    if not IsValid(ply) or not IsValid(target) then return end

    ply.RequestedJobSwitch = nil
    if not tobool(answer) then return end
    local Pteam = ply:Team()
    local Tteam = target:Team()

    if not ply:changeTeam(Tteam, nil, nil, true) then return end
    if not target:changeTeam(Pteam, nil, nil, true) then
        ply:changeTeam(Pteam, true) -- revert job change
        return
    end
    LynxonsRP.notify(ply, 2, 4, LynxonsRP.getPhrase("job_switch"))
    LynxonsRP.notify(target, 2, 4, LynxonsRP.getPhrase("job_switch"))
end

local function SwitchJob(ply) --Idea by Godness.
    if not GAMEMODE.Config.allowjobswitch then return "" end

    if ply.RequestedJobSwitch then return end

    local eyetrace = ply:GetEyeTrace()
    local ent = eyetrace.Entity

    if not IsValid(ent) or not ent:IsPlayer() then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", LynxonsRP.getPhrase("switch_jobs"), ""))
        return ""
    end

    local team1 = RPExtraTeams[ply:Team()]
    local team2 = RPExtraTeams[ent:Team()]

    if not team1 or not team2 then return "" end
    if team1 == team2 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", LynxonsRP.getPhrase("switch_jobs"), ""))
        return ""
    end
    if team1.customCheck and not team1.customCheck(ent) or team2.customCheck and not team2.customCheck(ply) then
        -- notify only the player trying to switch
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", LynxonsRP.getPhrase("switch_jobs"), ""))
        return ""
    end

    ply.RequestedJobSwitch = true
    LynxonsRP.createQuestion(LynxonsRP.getPhrase("job_switch_question", ply:Nick()), "switchjob" .. tostring(ply:EntIndex()), ent, 30, ExecSwitchJob, ply, ent)
    LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("job_switch_requested"))

    return ""
end
LynxonsRP.defineChatCommand("switchjob", SwitchJob)
LynxonsRP.defineChatCommand("switchjobs", SwitchJob)
LynxonsRP.defineChatCommand("jobswitch", SwitchJob)


local function DoTeamBan(ply, args)
    local ent = args[1]
    local Team = args[2]

    if not Team then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return
    end

    local target = LynxonsRP.findPlayer(ent)
    if not target or not IsValid(target) then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", ent or ""))
        return
    end

    local found = false
    for k, v in pairs(RPExtraTeams) do
        if string.lower(v.name) == string.lower(Team) or string.lower(v.command) == string.lower(Team) or k == tonumber(Team or -1) then
            Team = k
            found = true
            break
        end
    end

    if not found then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", Team or ""))
        return
    end

    local time = tonumber(args[3] or 0)

    target:teamBan(tonumber(Team), time)

    local nick
    if ply:EntIndex() == 0 then
        nick = "Console"
    else
        nick = ply:Nick()
    end
    LynxonsRP.notifyAll(0, 5, LynxonsRP.getPhrase("x_teambanned_y_for_z", nick, target:Nick(), team.GetName(tonumber(Team)), time / 60))
end
LynxonsRP.definePrivilegedChatCommand("teamban", "LynxonsRP_AdminCommands", DoTeamBan)

local function DoTeamUnBan(ply, args)
    if #args < 2 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return
    end

    local ent = args[1]
    local Team = args[2]

    local target = LynxonsRP.findPlayer(ent)
    if not target then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", ent or ""))
        return
    end

    local found = false
    for k, v in pairs(RPExtraTeams) do
        if string.lower(v.name) == string.lower(Team) or string.lower(v.command) == string.lower(Team) then
            Team = k
            found = true
            break
        end
        if k == tonumber(Team or -1) then
            found = true
            break
        end
    end

    if not found then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", Team or ""))
        return
    end

    target:teamUnBan(tonumber(Team))

    local nick
    if ply:EntIndex() == 0 then
        nick = "Console"
    else
        nick = ply:Nick()
    end
    LynxonsRP.notifyAll(0, 5, LynxonsRP.getPhrase("x_teamunbanned_y", nick, target:Nick(), team.GetName(tonumber(Team))))
end
LynxonsRP.definePrivilegedChatCommand("teamunban", "LynxonsRP_AdminCommands", DoTeamUnBan)
