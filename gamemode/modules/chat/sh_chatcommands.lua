local plyMeta = FindMetaTable("Player")
LynxonsRP.chatCommands = LynxonsRP.chatCommands or {}

local validChatCommand = {
    command = isstring,
    description = isstring,
    condition = fn.FOr{fn.Curry(fn.Eq, 2)(nil), isfunction},
    delay = isnumber,
    tableArgs = fn.FOr{fn.Curry(fn.Eq, 2)(nil), isbool},
}

local checkChatCommand = function(tbl)
    for k in pairs(validChatCommand) do
        if not validChatCommand[k](tbl[k]) then
            return false, k
        end
    end
    return true
end

function LynxonsRP.declareChatCommand(tbl)
    local valid, element = checkChatCommand(tbl)
    if not valid then
        LynxonsRP.error("Incorrect chat command! " .. element .. " is invalid!", 2)
    end

    tbl.command = string.lower(tbl.command)
    LynxonsRP.chatCommands[tbl.command] = LynxonsRP.chatCommands[tbl.command] or tbl
    for k, v in pairs(tbl) do
        LynxonsRP.chatCommands[tbl.command][k] = v
    end
end

function LynxonsRP.removeChatCommand(command)
    LynxonsRP.chatCommands[string.lower(command)] = nil
end

function LynxonsRP.chatCommandAlias(command, ...)
    local name
    for k, v in pairs{...} do
        name = string.lower(v)

        LynxonsRP.chatCommands[name] = {command = name}
        setmetatable(LynxonsRP.chatCommands[name], {
            __index = LynxonsRP.chatCommands[command]
        })
    end
end

function LynxonsRP.getChatCommand(command)
    return LynxonsRP.chatCommands[string.lower(command)]
end

function LynxonsRP.getChatCommands()
    return LynxonsRP.chatCommands
end

function LynxonsRP.getSortedChatCommands()
    local tbl = fn.Compose{table.ClearKeys, table.Copy, LynxonsRP.getChatCommands}()
    table.SortByMember(tbl, "command", true)

    return tbl
end

-- chat commands that have been defined, but not declared
LynxonsRP.getIncompleteChatCommands = fn.Curry(fn.Filter, 3)(fn.Compose{fn.Not, checkChatCommand})(LynxonsRP.chatCommands)

--[[---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------]]
LynxonsRP.declareChatCommand{
    command = "pm",
    description = "Send a private message to someone.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "w",
    description = "Say something in whisper voice.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "y",
    description = "Yell something out loud.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "me",
    description = "Chat roleplay to say you're doing things that you can't show otherwise.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "/",
    description = "Global server chat.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "a",
    description = "Global server chat.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "ooc",
    description = "Global server chat.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "broadcast",
    description = "Broadcast something as a mayor.",
    delay = 1.5,
    condition = plyMeta.isMayor
}

LynxonsRP.declareChatCommand{
    command = "channel",
    description = "Tune into a radio channel.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "radio",
    description = "Say something through the radio.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "g",
    description = "Group chat.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "credits",
    description = "Send the LynxonsRP credits to someone.",
    delay = 1.5
}
