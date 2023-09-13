ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Shipment"
ENT.Author = "philxyz"
ENT.Spawnable = false
ENT.IsSpawnedShipment = true

function ENT:SetupDataTables()
    self:NetworkVar("Int",0,"contents")
    self:NetworkVar("Int",1,"count")
    self:NetworkVar("Float", 0, "gunspawn")
    self:NetworkVar("Entity", 0, "owning_ent")
    self:NetworkVar("Entity", 1, "gunModel")
end

LynxonsRP.declareChatCommand{
    command = "splitshipment",
    description = "Split the shipment you're looking at.",
    delay = 1.5
}

LynxonsRP.declareChatCommand{
    command = "makeshipment",
    description = "Create a shipment from a dropped weapon.",
    delay = 1.5
}
