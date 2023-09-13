AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    LynxonsRP.ValidatedPhysicsInit(self, SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:OnTakeDamage(dmg)
    self:Remove()
end

function ENT:Use(activator, caller)
    local canUse, reason = hook.Call("canLynxonsRPUse", nil, activator, self, caller)
    if canUse == false then
        if reason then LynxonsRP.notify(activator, 1, 4, reason) end
        return
    end

    local override = self.foodItem.onEaten and self.foodItem.onEaten(self, activator, self.foodItem)

    if override then
        self:Remove()
        return
    end

    hook.Call("playerAteFood", nil, activator, self.foodItem, self)

    activator:setSelfLynxonsRPVar("Energy", math.Clamp((activator:getLynxonsRPVar("Energy") or 100) + (self.FoodEnergy or 1), 0, 100))
    umsg.Start("AteFoodIcon", activator)
    umsg.End()

    self:Remove()
    activator:EmitSound(self.EatSound, 100, 100)
end

LynxonsRP.hookStub{
    name = "playerAteFood",
    description = "When a player eats food.",
    parameters = {
        {
            name = "ply",
            description = "The player who ate food.",
            type = "Player"
        },
        {
            name = "food",
            description = "Food table.",
            type = "table"
        },
        {
            name = "spawnedfood",
            description = "Entity of spawned food.",
            type = "Entity"
        },
    },
    returns = {
    },
}
