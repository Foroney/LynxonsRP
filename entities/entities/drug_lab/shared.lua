ENT.Base = "lab_base"
ENT.PrintName = "Drug Lab"

function ENT:initVars()
    self.model = "models/props_lab/crematorcase.mdl"
    self.initialPrice = GAMEMODE.Config.druglabdrugcost
    self.labPhrase = LynxonsRP.getPhrase("drug_lab")
    self.itemPhrase = LynxonsRP.getPhrase("drugs")
    self.noIncome = true
    self.camMul = -39
end
