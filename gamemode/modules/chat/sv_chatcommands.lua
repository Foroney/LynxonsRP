--[[---------------------------------------------------------
Talking
 ---------------------------------------------------------]]
local function PM(ply, args)
    local namepos = string.find(args, " ")
    if not namepos then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end

    local name = string.sub(args, 1, namepos - 1)
    local msg = string.sub(args, namepos + 1)

    if msg == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end

    local target = LynxonsRP.findPlayer(name)
    if target == ply then return "" end

    if target then
        local col = team.GetColor(ply:Team())
        local pname = ply:Nick()
        local col2 = color_white
        LynxonsRP.talkToPerson(target, col, "(PM) " .. pname, col2, msg, ply)
        LynxonsRP.talkToPerson(ply, col, "(PM) " .. pname, col2, msg, ply)
    else
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(name)))
    end

    return ""
end
LynxonsRP.defineChatCommand("pm", PM, 1.5)

local function Whisper(ply, args)
    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return ""
        end
        LynxonsRP.talkToRange(ply, "(" .. LynxonsRP.getPhrase("whisper") .. ") " .. ply:Nick(), text, GAMEMODE.Config.whisperDistance)
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("w", Whisper, 1.5)

local function Yell(ply, args)
    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return ""
        end
        LynxonsRP.talkToRange(ply, "(" .. LynxonsRP.getPhrase("yell") .. ") " .. ply:Nick(), text, GAMEMODE.Config.yellDistance)
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("y", Yell, 1.5)

local function Me(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return ""
        end
        if GAMEMODE.Config.alltalk then
            local col = team.GetColor(ply:Team())
            local name = ply:Nick()
            for _, target in ipairs(player.GetAll()) do
                LynxonsRP.talkToPerson(target, col, name .. " " .. text)
            end
        else
            LynxonsRP.talkToRange(ply, ply:Nick() .. " " .. text, "", GAMEMODE.Config.meDistance)
        end
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("me", Me, 1.5)

local function OOC(ply, args)
    if not GAMEMODE.Config.ooc then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("disabled", LynxonsRP.getPhrase("ooc"), ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return ""
        end
        local col = team.GetColor(ply:Team())
        local col2 = color_white
        if not ply:Alive() then
            col2 = Color(255, 200, 200, 255)
            col = col2
        end

        local phrase = LynxonsRP.getPhrase("ooc")
        local name = ply:Nick()
        for _, v in ipairs(player.GetAll()) do
            LynxonsRP.talkToPerson(v, col, "(" .. phrase .. ") " .. name, col2, text, ply)
        end
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("/", OOC, true, 1.5)
LynxonsRP.defineChatCommand("a", OOC, true, 1.5)
LynxonsRP.defineChatCommand("ooc", OOC, true, 1.5)

local function MayorBroadcast(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end
    local Team = ply:Team()
    if not RPExtraTeams[Team] or not RPExtraTeams[Team].mayor then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("incorrect_job", LynxonsRP.getPhrase("broadcast")))
        return ""
    end
    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return
        end

        local col = team.GetColor(ply:Team())
        local col2 = Color(170, 0, 0, 255)
        local phrase = LynxonsRP.getPhrase("broadcast")
        local name = ply:Nick()
        for _, v in ipairs(player.GetAll()) do
            LynxonsRP.talkToPerson(v, col, phrase .. " " .. name, col2, text, ply)
        end
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("broadcast", MayorBroadcast, 1.5)

local function SetRadioChannel(ply,args)
    local channel = LynxonsRP.toInt(args)
    if channel == nil or channel < 0 or channel > 100 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), "0<" .. LynxonsRP.getPhrase("channel") .. "<100"))
        return ""
    end
    LynxonsRP.notify(ply, 2, 4, LynxonsRP.getPhrase("channel_set_to_x", args))
    ply.RadioChannel = channel
    return ""
end
LynxonsRP.defineChatCommand("channel", SetRadioChannel)

local function SayThroughRadio(ply,args)
    if not ply.RadioChannel then ply.RadioChannel = 1 end
    local radioChannel = ply.RadioChannel
    if not args or args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end
    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return
        end
        local col = Color(180, 180, 180, 255)
        local phrase = LynxonsRP.getPhrase("radio_x", radioChannel)
        for _, v in ipairs(player.GetAll()) do
            if v.RadioChannel == radioChannel then
                LynxonsRP.talkToPerson(v, col, phrase, col, text, ply)
            end
        end
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("radio", SayThroughRadio, 1.5)

local function GroupMsg(ply, args)
    local DoSay = function(text)
        if text == "" then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
            return
        end

        local col = team.GetColor(ply:Team())

        local groupChats = {}
        for _, func in pairs(GAMEMODE.LynxonsRPGroupChats) do
            -- not the group of the player
            if not func(ply) then continue end

            table.insert(groupChats, func)
        end

        if table.IsEmpty(groupChats) then return "" end

        local phrase = LynxonsRP.getPhrase("group")
        local name = ply:Nick()
        local color = color_white
        for _, target in ipairs(player.GetAll()) do
            -- The target is in any of the group chats
            for _, func in ipairs(groupChats) do
                if not func(target, ply) then continue end

                LynxonsRP.talkToPerson(target, col, phrase .. " " .. name, color, text, ply)
                break
            end
        end
    end
    return args, DoSay
end
LynxonsRP.defineChatCommand("g", GroupMsg, 0)

-- here's the new easter egg. Easier to find, more subtle, doesn't only credit FPtje and unib5
-- WARNING: DO NOT EDIT THIS
-- You can edit LynxonsRP but you HAVE to credit the original authors!
-- You even have to credit all the previous authors when you rename the gamemode.
-- local CreditsWait = true
local function GetLynxonsRPAuthors(ply, args)
    local target = LynxonsRP.findPlayer(args) -- Only send to one player. Prevents spamming
    target = IsValid(target) and target or ply

    if target ~= ply then
        if ply.CreditsWait then LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("wait_with_that")) return "" end
        ply.CreditsWait = true
        timer.Simple(60, function() if IsValid(ply) then ply.CreditsWait = nil end end) -- so people don't spam it
    end

    local rf = RecipientFilter()
    rf:AddPlayer(target)
    if ply ~= target then
        rf:AddPlayer(ply)
    end

    umsg.Start("LynxonsRP_Credits", rf)
    umsg.End()

    return ""
end
LynxonsRP.defineChatCommand("credits", GetLynxonsRPAuthors, 50)
