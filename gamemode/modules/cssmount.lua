if IsMounted("cstrike") and util.IsValidModel("models/props/cs_assault/money.mdl") then return end
local texts = {
    "Counter Strike Source не настроен!",
}

hook.Add("PlayerInitialSpawn", "CSSCheck", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        for _, text in pairs(texts) do
            LynxonsRP.talkToPerson(ply, Color(255, 0, 0,255), text)
        end
    end)
end)
