local function MakeLetter(ply, args, type)
    if not GAMEMODE.Config.letters then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("disabled", "/write / /type", ""))
        return ""
    end

    if ply.maxletters and ply.maxletters >= GAMEMODE.Config.maxletters then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("limit", "letter"))
        return ""
    end

    if CurTime() - ply:GetTable().LastLetterMade < 3 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("have_to_wait", math.ceil(3 - (CurTime() - ply:GetTable().LastLetterMade)), "/write / /type"))
        return ""
    end

    ply:GetTable().LastLetterMade = CurTime()

    -- Instruct the player's letter window to open

    local ftext = string.gsub(args, "//", "\n")
    ftext = string.gsub(ftext, "\\n", "\n") .. "\n\n" .. LynxonsRP.getPhrase("signed_yours") .. "\n" .. ply:Nick()
    local length = string.len(ftext)

    local numParts = math.floor(length / 39) + 1

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 85
    trace.filter = ply

    local tr = util.TraceLine(trace)

    local letter = ents.Create("letter")
    letter:SetModel("models/props_c17/paper01.mdl")
    letter:SetPos(tr.HitPos)
    letter:Setowning_ent(ply)
    letter.nodupe = true
    letter:Spawn()

    letter:GetTable().Letter = true
    letter.type = type
    letter.numPts = numParts

    LynxonsRP.placeEntity(letter, tr, ply)

    local startpos = 1
    local endpos = 39
    letter.Parts = {}

    for k = 1, numParts, 1 do
        table.insert(letter.Parts, string.sub(ftext, startpos, endpos))
        startpos = startpos + 39
        endpos = endpos + 39
    end

    letter.SID = ply.SID

    LynxonsRP.printMessageAll(2, LynxonsRP.getPhrase("created_x", ply:Nick(), "mail"))
    if not ply.maxletters then
        ply.maxletters = 0
    end
    ply.maxletters = ply.maxletters + 1
    timer.Simple(600, function() if IsValid(letter) then letter:Remove() end end)
end

local function WriteLetter(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end
    MakeLetter(ply, args, 1)
    return ""
end
LynxonsRP.defineChatCommand("write", WriteLetter)

local function TypeLetter(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end
    MakeLetter(ply, args, 2)
    return ""
end
LynxonsRP.defineChatCommand("type", TypeLetter)

local function RemoveLetters(ply)
    for k, v in ipairs(ents.FindByClass("letter")) do
        if v.SID == ply.SID then v:Remove() end
    end
    LynxonsRP.notify(ply, 4, 4, LynxonsRP.getPhrase("cleaned_up", "mails"))
    return ""
end
LynxonsRP.defineChatCommand("removeletters", RemoveLetters)
