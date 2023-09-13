ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "letter"
ENT.Author = "Pcwizdan"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity",1,"owning_ent")
    self:NetworkVar("Entity",2,"signed")
end

LynxonsRP.declareChatCommand{
    command = "write",
    description = "Write a letter.",
    delay = 5
}

LynxonsRP.declareChatCommand{
    command = "type",
    description = "Type a letter.",
    delay = 5
}

LynxonsRP.declareChatCommand{
    command = "removeletters",
    description = "Remove all of your letters.",
    delay = 5
}
