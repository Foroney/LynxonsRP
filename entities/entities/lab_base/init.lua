AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:initVars()

    self:SetModel(self.model)
    LynxonsRP.ValidatedPhysicsInit(self, SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
    end

    self.sparking = false
    self.damage = 100
    self:Setprice(math.Clamp(self.initialPrice, (GAMEMODE.Config.pricemin ~= 0 and GAMEMODE.Config.pricemin) or self.initialPrice, (GAMEMODE.Config.pricecap ~= 0 and GAMEMODE.Config.pricecap) or self.initialPrice))
end

function ENT:OnTakeDamage(dmg)
    self:TakePhysicsDamage(dmg)

    self.damage = self.damage - dmg:GetDamage()
    if self.damage <= 0 and not self.Destructed then
        self.Destructed = true
        self:Destruct()
        self:Remove()
    end
end

function ENT:Destruct()
    local vPoint = self:GetPos()

    util.BlastDamage(self, self, vPoint, self.blastRadius, self.blastDamage)
    util.ScreenShake(vPoint, 512, 255, 1.5, 200)

    local effectdata = EffectData()
    effectdata:SetStart(vPoint)
    effectdata:SetOrigin(vPoint)
    effectdata:SetScale(1)
    util.Effect(self:WaterLevel() > 1 and "WaterSurfaceExplosion" or "Explosion", effectdata)
    util.Decal("Scorch", vPoint, vPoint - Vector(0, 0, 25), self)
end

function ENT:SalePrice(activator)
    local owner = self:Getowning_ent()

    if activator == owner then
        if self.allowed and istable(self.allowed) and table.HasValue(self.allowed, activator:Team()) then
            return math.ceil(self:Getprice() * 0.8)
        else
            return math.ceil(self:Getprice() * 0.9)
        end
    else
        return self:Getprice()
    end
end

ENT.Once = false
function ENT:Use(activator, caller)
    -- The lab cannot be used by non-players (e.g. wire user)
    -- The player must be known for the lab to work.
    if not activator:IsPlayer() then return end

    if self.Once then return end

    local owner = self:Getowning_ent()

    if not IsValid(owner) then
        LynxonsRP.notify(activator, 1, 3, LynxonsRP.getPhrase("disabled", self.labPhrase, LynxonsRP.getPhrase("disconnected_player")))
        return
    end

    local cost = self:SalePrice(activator)

    if not activator:canAfford(cost) then
        LynxonsRP.notify(activator, 1, 3, LynxonsRP.getPhrase("cant_afford", self.itemPhrase))
        return
    end

    local diff = cost - self:SalePrice(owner)
    if not self.noIncome and diff < 0 and not owner:canAfford(math.abs(diff)) then
        LynxonsRP.notify(activator, 1, 3, LynxonsRP.getPhrase("owner_poor", self.labPhrase))
        return
    end

    if not self:canUse(activator) then return end

    local canUse, reason = hook.Call("canLynxonsRPUse", nil, activator, self, caller)
    if canUse == false then
      if reason then LynxonsRP.notify(activator, 1, 4, reason) end
      return
    end

    self.Once = true
    self.sparking = true

    activator:addMoney(-cost)
    LynxonsRP.notify(activator, 0, 3, LynxonsRP.getPhrase("you_bought", self.itemPhrase, LynxonsRP.formatMoney(cost)))

    if activator ~= owner and not self.noIncome then
        if diff == 0 then
            LynxonsRP.notify(owner, 0, 3, LynxonsRP.getPhrase("you_received_x", LynxonsRP.formatMoney(0) .. " " .. LynxonsRP.getPhrase("profit"), self.itemPhrase))
        else
            owner:addMoney(diff)
            local word = LynxonsRP.getPhrase("profit")
            if diff < 0 then word = LynxonsRP.getPhrase("loss") end
            LynxonsRP.notify(owner, 0, 3, LynxonsRP.getPhrase("you_received_x", LynxonsRP.formatMoney(math.abs(diff)) .. " " .. word, self.itemPhrase))
        end
    end

    timer.Create(self:EntIndex() .. self.itemPhrase, 1, 1, function()
        if not IsValid(self) then return end
        if IsValid(activator) then
            self:createItem(activator)
        end
        self.Once = false
        self.sparking = false
    end)
end

function ENT:canUse(owner, activator)
    return true
end

function ENT:createItem(activator)
    -- Implement this function
end

function ENT:Think()
    if self.sparking then
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetMagnitude(1)
        effectdata:SetScale(1)
        effectdata:SetRadius(2)
        util.Effect("Sparks", effectdata)
    end
end

function ENT:OnRemove()
    timer.Remove(self:EntIndex() .. self.itemPhrase)
end
