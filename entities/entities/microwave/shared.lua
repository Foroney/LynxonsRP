ENT.Base = "lab_base"
ENT.PrintName = "Microwave"

function ENT:initVars()
    self.model = "models/props/cs_office/microwave.mdl"
    self.initialPrice = GAMEMODE.Config.microwavefoodcost
    self.labPhrase = LynxonsRP.getPhrase("microwave")
    self.itemPhrase = LynxonsRP.getPhrase("food")
end
