util.AddNetworkString("LynxonsRP_TipJarUI")
util.AddNetworkString("LynxonsRP_TipJarDonate")
util.AddNetworkString("LynxonsRP_TipJarUpdate")
util.AddNetworkString("LynxonsRP_TipJarExit")
util.AddNetworkString("LynxonsRP_TipJarDonatedList")


net.Receive("LynxonsRP_TipJarDonate", function(_, ply)
    local tipjar = net.ReadEntity()
    local amount = net.ReadUInt(32)

    if not IsValid(tipjar) then return end
    if not tipjar.IsTipjar then return end

    local owner = tipjar:Getowning_ent()
    if not IsValid(owner) then return end
    if owner == ply then return end

    ply.LynxonsRPLastTip = ply.LynxonsRPLastTip or -1

    if ply.LynxonsRPLastTip > CurTime() - 0.1 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("wait_with_that"))
        return
    end

    if not ply:canAfford(amount) then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("cant_afford", amount))
        return
    end

    if tipjar:GetPos():DistToSqr(ply:GetPos()) > 100 * 100 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("distance_too_big"))
        return
    end

    LynxonsRP.payPlayer(ply, owner, amount)

    tipjar:AddDonation(ply:Nick(), amount)

    tipjar:EmitSound("ambient/alarms/warningbell1.wav")

    local strAmount = LynxonsRP.formatMoney(amount)

    LynxonsRP.notify(ply,   3, 4, LynxonsRP.getPhrase("you_donated", strAmount,  owner:Nick()))
    LynxonsRP.notify(owner, 3, 4, LynxonsRP.getPhrase("has_donated", ply:Nick(), strAmount))

    net.Start("LynxonsRP_TipJarDonate")
        net.WriteEntity(tipjar)
        net.WriteEntity(ply)
        net.WriteUInt(amount, 32)
    net.Broadcast()

    ply.LynxonsRPLastTip = CurTime()
end)

net.Receive("LynxonsRP_TipJarUpdate", function(_, ply)
    local tipjar = net.ReadEntity()
    local amount = net.ReadUInt(32)

    if not IsValid(tipjar) then return end
    if not tipjar.IsTipjar then return end

    -- Larger margin of distance, to prevent false positives
    if tipjar:GetPos():DistToSqr(ply:GetPos()) > 150 * 150 then
        return
    end

    tipjar:UpdateActiveDonation(ply, amount)
end)

-- Send a tipjar's donation data to a single player
local function sendJarData(tipjar, ply)
    if not table.IsEmpty(tipjar.activeDonations) then
        net.Start("LynxonsRP_TipJarUpdate")
            net.WriteEntity(tipjar)

            for p, amnt in pairs(tipjar.activeDonations) do
                net.WriteEntity(p)
                net.WriteUInt(amnt, 32)
            end
        net.Send(ply)
    end

    if not table.IsEmpty(tipjar.madeDonations) then
        net.Start("LynxonsRP_TipJarDonatedList")
            net.WriteEntity(tipjar)
            net.WriteUInt(#tipjar.madeDonations, 8)

            for _, donation in ipairs(tipjar.madeDonations) do
                net.WriteString(donation.name)
                net.WriteUInt(donation.amount, 32)
            end
        net.Send(ply)
    end
end

function LynxonsRP.hooks:tipjarUpdateActiveDonation(tipjar, ply, amount, old)
    -- Player is new to this jar, send all data
    if not old then
        sendJarData(tipjar, ply)
    end

    -- Tell the rest of the player's active donation
    local updateTargets = RecipientFilter()

    for p, _ in pairs(tipjar.activeDonations) do
        updateTargets:AddPlayer(p)
    end

    updateTargets:RemovePlayer(ply)

    net.Start("LynxonsRP_TipJarUpdate")
        net.WriteEntity(tipjar)
        net.WriteEntity(ply)
        net.WriteUInt(amount, 32)
    net.Send(updateTargets)
end

net.Receive("LynxonsRP_TipJarExit", function(_, ply)
    local tipjar = net.ReadEntity()

    if not IsValid(tipjar) then return end
    if not tipjar.IsTipjar then return end

    tipjar:ExitActiveDonation(ply)
end)

function LynxonsRP.hooks:tipjarExitActiveDonation(tipjar, ply, old)
    local updateTargets = RecipientFilter()

    for p, _ in pairs(tipjar.activeDonations) do
        updateTargets:AddPlayer(p)
    end

    net.Start("LynxonsRP_TipJarExit")
        net.WriteEntity(tipjar)
        net.WriteEntity(ply)
    net.Send(updateTargets)
end
