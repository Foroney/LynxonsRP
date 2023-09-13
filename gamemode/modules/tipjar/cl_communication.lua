local updateModel, getModelValue, onModelUpdate =
    LynxonsRP.tipJarUIModel.updateModel,
    LynxonsRP.tipJarUIModel.getModelValue,
    LynxonsRP.tipJarUIModel.onModelUpdate

onModelUpdate("lastTipAmount", function(amount)
    if amount <= 0 then return end

    local tipjar = getModelValue("tipjar")

    if not IsValid(tipjar) then return end

    net.Start("LynxonsRP_TipJarDonate")
        net.WriteEntity(tipjar)
        net.WriteUInt(amount, 32)
    net.SendToServer()
end)

net.Receive("LynxonsRP_TipJarUI", fc{LynxonsRP.tipJarUI, net.ReadEntity})

net.Receive("LynxonsRP_TipJarDonate", function()
    local tipjar = net.ReadEntity()
    local ply    = net.ReadEntity()
    local amount = net.ReadUInt(32)

    if not IsValid(tipjar) then return end
    if not IsValid(ply) then return end

    tipjar:Donated(ply, amount)
    updateModel("donatedUpdate")
end)

onModelUpdate("amount", function(amount, old)
    local tipjar = getModelValue("tipjar")

    if not IsValid(tipjar) then return end

    tipjar:UpdateActiveDonation(LocalPlayer(), amount)

    if amount == old then return end

    net.Start("LynxonsRP_TipJarUpdate")
        net.WriteEntity(tipjar)
        net.WriteUInt(amount, 32)
    net.SendToServer()
end)

net.Receive("LynxonsRP_TipJarUpdate", function(len)
    local tipjar = net.ReadEntity()

    if not IsValid(tipjar) then return end

    local bitsRead = 16

    while bitsRead < len do
        tipjar:UpdateActiveDonation(net.ReadEntity(), net.ReadUInt(32))

        -- I thought there was a function for this?
        bitsRead = bitsRead + 16 + 32
    end
end)

onModelUpdate("frameVisible", function(visible)
    local localply = LocalPlayer()
    local tipjar   = getModelValue("tipjar")
    local amount   = getModelValue("amount")

    if not IsValid(localply) then return end
    if not IsValid(tipjar) then return end

    if visible then
        tipjar:ClearActiveDonations()
        tipjar:UpdateActiveDonation(localply, amount)

        net.Start("LynxonsRP_TipJarUpdate")
            net.WriteEntity(tipjar)
            net.WriteUInt(amount, 32)
        net.SendToServer()

    else
        net.Start("LynxonsRP_TipJarExit")
            net.WriteEntity(tipjar)
        net.SendToServer()

        tipjar:ExitActiveDonation(localply)
    end
end)

net.Receive("LynxonsRP_TipJarExit", function()
    local tipjar = net.ReadEntity()
    local ply = net.ReadEntity()

    if not IsValid(tipjar) then return end
    if not IsValid(ply) then return end

    tipjar:ExitActiveDonation(ply)
end)

net.Receive("LynxonsRP_TipJarDonatedList", function()
    local tipjar = net.ReadEntity()
    local count = net.ReadUInt(8)

    if not IsValid(tipjar) then return end

    tipjar:ClearDonations()

    for i = 1, count do
        tipjar:AddDonation(net.ReadString(), net.ReadUInt(32))
    end

    updateModel("donatedUpdate")
end)


local function onUpdateActiveDonation(_, tipjar)
    if not IsValid(tipjar) or tipjar ~= getModelValue("tipjar") then return end

    updateModel("activeDonationUpdate")
end

LynxonsRP.hooks.tipjarUpdateActiveDonation = onUpdateActiveDonation
LynxonsRP.hooks.tipjarExitActiveDonation   = onUpdateActiveDonation
LynxonsRP.hooks.tipjarClearActiveDonation  = onUpdateActiveDonation
