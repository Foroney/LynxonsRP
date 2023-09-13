local meta = FindMetaTable("Entity")
local pmeta = FindMetaTable("Player")

--[[---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------]]

function meta:doorIndex()
    return self:CreatedByMap() and self:MapCreationID() or nil
end

function LynxonsRP.doorToEntIndex(num)
    local ent = ents.GetMapCreatedEntity(num)

    return IsValid(ent) and ent:EntIndex() or nil
end

function LynxonsRP.doorIndexToEnt(num)
    return ents.GetMapCreatedEntity(num) or NULL
end

function meta:isLocked()
    local save = self:GetSaveTable()
    return save and ((self:isDoor() and save.m_bLocked) or (self:IsVehicle() and save.VehicleLocked))
end

function meta:keysLock()
    self:Fire("lock", "", 0)
    if isfunction(self.Lock) then self:Lock(true) end -- SCars
    if IsValid(self.EntOwner) and self.EntOwner ~= self then return self.EntOwner:keysLock() end -- SCars

    hook.Call("onKeysLocked", nil, self)
end

function meta:keysUnLock()
    self:Fire("unlock", "", 0)
    if isfunction(self.UnLock) then self:UnLock(true) end -- SCars
    if IsValid(self.EntOwner) and self.EntOwner ~= self then return self.EntOwner:keysUnLock() end -- SCars

    hook.Call("onKeysUnlocked", nil, self)
end

function meta:keysOwn(ply)
    if self:isKeysAllowedToOwn(ply) then
        self:addKeysDoorOwner(ply)
        return
    end

    local Owner = self:CPPIGetOwner()

    -- Increase vehicle count
    if self:IsVehicle() then
        if IsValid(ply) then
            ply.Vehicles = ply.Vehicles or 0
            ply.Vehicles = ply.Vehicles + 1

            self.SID = ply.SID
        end

        -- Decrease vehicle count of the original owner
        if IsValid(Owner) and Owner ~= ply then
            Owner.Vehicles = Owner.Vehicles or 1
            Owner.Vehicles = Owner.Vehicles - 1
        end
    end

    if self:IsVehicle() then
        self:CPPISetOwner(ply)
    end

    if not self:isKeysOwned() and not self:isKeysOwnedBy(ply) then
        local doorData = self:getDoorData()
        doorData.owner = ply:UserID()
        LynxonsRP.updateDoorData(self, "owner")
    end

    ply.OwnedNumz = ply.OwnedNumz or 0
    if ply.OwnedNumz == 0 and GAMEMODE.Config.propertytax then
        timer.Create(ply:SteamID64() .. "propertytax", 270, 0, function() ply.doPropertyTax(ply) end)
    end

    ply.OwnedNumz = ply.OwnedNumz + 1

    ply.Ownedz[self:EntIndex()] = self
end

function meta:keysUnOwn(ply)
    if not ply then
        ply = self:getDoorOwner()

        if not IsValid(ply) then return end
    end

    if self:isMasterOwner(ply) then
        local doorData = self:getDoorData()
        self:removeAllKeysExtraOwners()
        self:setKeysTitle(nil)
        doorData.owner = nil
        LynxonsRP.updateDoorData(self, "owner")
    else
        self:removeKeysDoorOwner(ply)
    end

    ply.Ownedz[self:EntIndex()] = nil
    ply.OwnedNumz = math.Clamp((ply.OwnedNumz or 1) - 1, 0, math.huge)
end

function pmeta:keysUnOwnAll()
    for entIndex, ent in pairs(self.Ownedz or {}) do
        if not IsValid(ent) or not ent:isKeysOwnable() then self.Ownedz[entIndex] = nil continue end
        if ent:isMasterOwner(self) then
            ent:Fire("unlock", "", 0.6)
        end
        ent:keysUnOwn(self)
    end

    for _, ply in ipairs(player.GetAll()) do
        if ply == self then continue end

        for _, ent in pairs(ply.Ownedz or {}) do
            if IsValid(ent) and ent:isKeysAllowedToOwn(self) then
                ent:removeKeysAllowedToOwn(self)
            end
        end
    end

    self.OwnedNumz = 0
end

local function taxesUnOwnAll(ply, taxables)
    for _, ent in pairs(taxables) do
        if ent:isMasterOwner(ply) then
            ent:Fire("unlock", "", 0.6)
        end

        ent:keysUnOwn(ply)
    end
end

function pmeta:doPropertyTax()
    if not GAMEMODE.Config.propertytax then return end
    if self:isCP() and GAMEMODE.Config.cit_propertytax then return end

    local taxables = {}

    for entIndex, ent in pairs(self.Ownedz or {}) do
        if not IsValid(ent) or not ent:isKeysOwnable() then self.Ownedz[entIndex] = nil continue end
        local isAllowed = hook.Call("canTaxEntity", nil, self, ent)
        if isAllowed == false then continue end

        table.insert(taxables, ent)
    end

    -- co-owned doors
    for _, ply in ipairs(player.GetAll()) do
        if ply == self then continue end

        for _, ent in pairs(ply.Ownedz or {}) do
            if not IsValid(ent) or not ent:isKeysOwnedBy(self) then continue end

            local isAllowed = hook.Call("canTaxEntity", nil, self, ent)
            if isAllowed == false then continue end

            table.insert(taxables, ent)
        end
    end

    local numowned = #taxables

    if numowned <= 0 then return end

    local price = 10
    local tax = price * numowned + math.random(-5, 5)

    local shouldTax, taxOverride = hook.Call("canPropertyTax", nil, self, tax)

    if shouldTax == false then return end

    tax = taxOverride or tax
    if tax == 0 then return end

    local canAfford = self:canAfford(tax)

    if canAfford then
        self:addMoney(-tax)
        LynxonsRP.notify(self, 0, 5, LynxonsRP.getPhrase("property_tax", LynxonsRP.formatMoney(tax)))
    else
        taxesUnOwnAll(self, taxables)
        LynxonsRP.notify(self, 1, 8, LynxonsRP.getPhrase("property_tax_cant_afford"))
    end

    hook.Call("onPropertyTax", nil, self, tax, canAfford)
end

function pmeta:initiateTax()
    local taxtime = GAMEMODE.Config.wallettaxtime
    local uid = self:SteamID64() -- so we can destroy the timer if the player leaves
    timer.Create("rp_tax_" .. uid, taxtime or 600, 0, function()
        if not IsValid(self) then
            timer.Remove("rp_tax_" .. uid)

            return
        end

        if not GAMEMODE.Config.wallettax then
            return -- Don't remove the hook in case it's turned on afterwards.
        end

        local money = self:getLynxonsRPVar("money")
        local mintax = GAMEMODE.Config.wallettaxmin / 100
        local maxtax = GAMEMODE.Config.wallettaxmax / 100 -- convert to decimals for percentage calculations
        local startMoney = GAMEMODE.Config.startingmoney


        -- Variate the taxes between twice the starting money ($1000 by default) and 200 - 2 times the starting money (100.000 by default)
        local tax = (money - (startMoney * 2)) / (startMoney * 198)
        tax = math.Min(maxtax, mintax + (maxtax - mintax) * tax)

        local taxAmount = tax * money

        local shouldTax, amount = hook.Call("canTax", GAMEMODE, self, taxAmount)

        if shouldTax == false then return end

        taxAmount = amount or taxAmount
        taxAmount = math.Max(0, taxAmount)

        self:addMoney(-taxAmount)
        LynxonsRP.notify(self, 3, 7, LynxonsRP.getPhrase("taxday", math.Round(taxAmount / money * 100, 3)))

        hook.Call("onPaidTax", LynxonsRP.hooks, self, tax, money)
    end)
end

function GM:canTax(ply)
    -- Don't tax players if they have less than twice the starting amount
    if ply:getLynxonsRPVar("money") < (GAMEMODE.Config.startingmoney * 2) then return false end
end

--[[---------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------]]
local function SetDoorOwnable(ply)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or (not ent:isDoor() and not ent:IsVehicle()) or ply:GetPos():DistToSqr(ent:GetPos()) > 40000 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return
    end

    if IsValid(ent:getDoorOwner()) then
        ent:keysUnOwn(ent:getDoorOwner())
    end
    ent:setKeysNonOwnable(not ent:getKeysNonOwnable())
    ent:removeAllKeysExtraOwners()
    ent:removeAllKeysAllowedToOwn()
    ent:removeAllKeysDoorTeams()
    ent:setDoorGroup(nil)
    ent:setKeysTitle(nil)

    -- Save it for future map loads
    LynxonsRP.storeDoorData(ent)
    LynxonsRP.storeDoorGroup(ent, nil)
    LynxonsRP.storeTeamDoorOwnability(ent)

    return ""
end
LynxonsRP.definePrivilegedChatCommand("toggleownable", "LynxonsRP_ChangeDoorSettings", SetDoorOwnable)

local function SetDoorGroupOwnable(ply, arg)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or (not ent:isDoor() and not ent:IsVehicle()) or ply:GetPos():DistToSqr(ent:GetPos()) > 40000 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return
    end

    if not RPExtraTeamDoors[arg] and arg ~= "" then LynxonsRP.notify(ply, 1, 10, LynxonsRP.getPhrase("door_group_doesnt_exist")) return "" end

    ent:keysUnOwn()


    ent:removeAllKeysDoorTeams()
    local group = arg ~= "" and arg or nil
    ent:setDoorGroup(group)

    -- Save it for future map loads
    LynxonsRP.storeDoorGroup(ent, group)
    LynxonsRP.storeTeamDoorOwnability(ent)


    LynxonsRP.notify(ply, 0, 8, LynxonsRP.getPhrase("door_group_set"))
    return ""
end
LynxonsRP.definePrivilegedChatCommand("togglegroupownable", "LynxonsRP_ChangeDoorSettings", SetDoorGroupOwnable)

local function SetDoorTeamOwnable(ply, arg)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or (not ent:isDoor() and not ent:IsVehicle()) or ply:GetPos():DistToSqr(ent:GetPos()) > 40000 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return ""
    end

    arg = tonumber(arg)
    if not arg then LynxonsRP.notify(ply, 1, 10, LynxonsRP.getPhrase("job_doesnt_exist")) return "" end
    if not RPExtraTeams[arg] and arg ~= nil then LynxonsRP.notify(ply, 1, 10, LynxonsRP.getPhrase("job_doesnt_exist")) return "" end
    if IsValid(ent:getDoorOwner()) then
        ent:keysUnOwn(ent:getDoorOwner())
    end

    ent:setDoorGroup(nil)
    LynxonsRP.storeDoorGroup(ent, nil)

    local doorTeams = ent:getKeysDoorTeams()
    if not doorTeams or not doorTeams[arg] then
        ent:addKeysDoorTeam(arg)
    else
        ent:removeKeysDoorTeam(arg)
    end

    LynxonsRP.notify(ply, 0, 8, LynxonsRP.getPhrase("door_group_set"))
    LynxonsRP.storeTeamDoorOwnability(ent)

    ent:keysUnOwn()
    return ""
end
LynxonsRP.definePrivilegedChatCommand("toggleteamownable", "LynxonsRP_ChangeDoorSettings", SetDoorTeamOwnable)

local function OwnDoor(ply)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or not ent:isKeysOwnable() or ply:GetPos():DistToSqr(ent:GetPos()) >= 40000 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return ""
    end

    local Owner = ent:CPPIGetOwner()

    if ply:isArrested() then
        LynxonsRP.notify(ply, 1, 5, LynxonsRP.getPhrase("door_unown_arrested"))
        return ""
    end

    if ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or not fn.Null(ent:getKeysDoorTeams() or {}) then
        LynxonsRP.notify(ply, 1, 5, LynxonsRP.getPhrase("door_unownable"))
        return ""
    end

    if ent:isKeysOwnedBy(ply) then
        local bAllowed, strReason = hook.Call("playerSell" .. (ent:IsVehicle() and "Vehicle" or "Door"), GAMEMODE, ply, ent)

        if bAllowed == false then
            if strReason and strReason ~= "" then
                LynxonsRP.notify(ply, 1, 4, strReason)
            end

            return ""
        end

        if ent:isMasterOwner(ply) then
            ent:removeAllKeysExtraOwners()
            ent:removeAllKeysAllowedToOwn()
            ent:Fire("unlock", "", 0)
        end

        ent:keysUnOwn(ply)
        ent:setKeysTitle(nil)
        local GiveMoneyBack = math.floor((hook.Call("get" .. (ent:IsVehicle() and "Vehicle" or "Door") .. "Cost", GAMEMODE, ply, ent) * 0.666) + 0.5)
        hook.Call("playerKeysSold", GAMEMODE, ply, ent, GiveMoneyBack)
        ply:addMoney(GiveMoneyBack)
        local bSuppress = hook.Call("hideSellDoorMessage", GAMEMODE, ply, ent)
        if not bSuppress then
            LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("door_sold", LynxonsRP.formatMoney(GiveMoneyBack)))
        end

    else
        if ent:isKeysOwned() and not ent:isKeysAllowedToOwn(ply) then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("door_already_owned"))
            return ""
        end

        local iCost = hook.Call("get" .. (ent:IsVehicle() and "Vehicle" or "Door") .. "Cost", GAMEMODE, ply, ent)
        if not ply:canAfford(iCost) then
            LynxonsRP.notify(ply, 1, 4, ent:IsVehicle() and LynxonsRP.getPhrase("vehicle_cannot_afford") or LynxonsRP.getPhrase("door_cannot_afford"))
            return ""
        end

        local bAllowed, strReason, bSuppress = hook.Call("playerBuy" .. (ent:IsVehicle() and "Vehicle" or "Door"), GAMEMODE, ply, ent)
        if bAllowed == false then
            if strReason and strReason ~= "" then
                LynxonsRP.notify(ply, 1, 4, strReason)
            end

            return ""
        end

        local bVehicle = ent:IsVehicle()

        if bVehicle and (ply.Vehicles or 0) >= GAMEMODE.Config.maxvehicles and Owner ~= ply then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("limit", LynxonsRP.getPhrase("vehicle")))
            return ""
        end

        if not bVehicle and (ply.OwnedNumz or 0) >= GAMEMODE.Config.maxdoors then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("limit", LynxonsRP.getPhrase("door")))
            return ""
        end

        ply:addMoney(-iCost)
        if not bSuppress then
            LynxonsRP.notify(ply, 0, 4, bVehicle and LynxonsRP.getPhrase("vehicle_bought", LynxonsRP.formatMoney(iCost), "") or LynxonsRP.getPhrase("door_bought", LynxonsRP.formatMoney(iCost), ""))
        end

        ent:keysOwn(ply)
        hook.Call("playerBought" .. (bVehicle and "Vehicle" or "Door"), GAMEMODE, ply, ent, iCost)
    end

    return ""
end
LynxonsRP.defineChatCommand("toggleown", OwnDoor)

local function UnOwnAll(ply, cmd, args)
    local amount = 0
    local cost = 0

    local unownables = {}
    for entIndex, ent in pairs(ply.Ownedz or {}) do
        if not IsValid(ent) or not ent:isKeysOwnable() then ply.Ownedz[entIndex] = nil continue end
        table.insert(unownables, ent)
    end

    for _, otherPly in ipairs(player.GetAll()) do
        if ply == otherPly then continue end

        for _, ent in pairs(otherPly.Ownedz or {}) do
            if IsValid(ent) and ent:isKeysOwnedBy(ply) then
                table.insert(unownables, ent)
            end
        end
    end

    for entIndex, ent in pairs(unownables) do
        local bAllowed, _strReason = hook.Call("playerSell" .. (ent:IsVehicle() and "Vehicle" or "Door"), GAMEMODE, ply, ent)

        if bAllowed == false then continue end

        if ent:isMasterOwner(ply) then
            ent:Fire("unlock", "", 0)
        end

        ent:keysUnOwn(ply)
        amount = amount + 1

        local GiveMoneyBack = math.floor((hook.Call("get" .. (ent:IsVehicle() and "Vehicle" or "Door") .. "Cost", GAMEMODE, ply, ent) * 0.666) + 0.5)
        hook.Call("playerKeysSold", GAMEMODE, ply, ent, GiveMoneyBack)
        cost = cost + GiveMoneyBack
    end

    if amount == 0 then LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("no_doors_owned")) return "" end

    ply:addMoney(math.floor(cost))

    LynxonsRP.notify(ply, 2, 4, LynxonsRP.getPhrase("sold_x_doors", amount, LynxonsRP.formatMoney(math.floor(cost))))
    return ""
end
LynxonsRP.defineChatCommand("unownalldoors", UnOwnAll)

local function SetDoorTitle(ply, args)
    local trace = ply:GetEyeTrace()

    local ent = trace.Entity
    if not IsValid(ent) or not ent:isKeysOwnable() or ply:GetPos():DistToSqr(ent:GetPos()) >= 12100 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return ""
    end

    if ent:isKeysOwnedBy(ply) then
        ent:setKeysTitle(args)
        return ""
    end

    local function onCAMIResult(allowed)
        if not allowed then
            LynxonsRP.notify(ply, 1, 6, LynxonsRP.getPhrase("no_privilege"))
            return
        end

        local hasTeams = not fn.Null(ent:getKeysDoorTeams() or {})
        if ent:isKeysOwned() or ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or hasTeams then
            ent:setKeysTitle(args)
        end

        if ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or hasTeams then
            LynxonsRP.storeDoorData(trace.Entity)
        end
    end

    CAMI.PlayerHasAccess(ply, "LynxonsRP_ChangeDoorSettings", onCAMIResult)

    return ""
end
LynxonsRP.defineChatCommand("title", SetDoorTitle)

local function RemoveDoorOwner(ply, args)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or not ent:isKeysOwnable() or ply:GetPos():DistToSqr(ent:GetPos()) >= 12100 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return ""
    end

    local target = LynxonsRP.findPlayer(args)

    if ent:getKeysNonOwnable() then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("door_rem_owners_unownable"))
        return ""
    end

    if not target then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(args)))
        return ""
    end

    if not ent:isKeysOwnedBy(ply) then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("do_not_own_ent"))
        return ""
    end


    local canDo = hook.Call("onAllowedToOwnRemoved", nil, ply, ent, target)
    if canDo == false then return "" end

    if ent:isKeysAllowedToOwn(target) then
        ent:removeKeysAllowedToOwn(target)
    end

    if ent:isKeysOwnedBy(target) then
        ent:removeKeysDoorOwner(target)
    end

    return ""
end
LynxonsRP.defineChatCommand("removeowner", RemoveDoorOwner)
LynxonsRP.defineChatCommand("ro", RemoveDoorOwner)

local function AddDoorOwner(ply, args)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if not IsValid(ent) or not ent:isKeysOwnable() or ply:GetPos():DistToSqr(ent:GetPos()) >= 12100 then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("must_be_looking_at", LynxonsRP.getPhrase("door_or_vehicle")))
        return ""
    end

    local target = LynxonsRP.findPlayer(args)

    if ent:getKeysNonOwnable() then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("door_add_owners_unownable"))
        return ""
    end

    if not target then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("could_not_find", tostring(args)))
        return ""
    end

    if not ent:isKeysOwnedBy(ply) then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("do_not_own_ent"))
        return ""
    end

    if ent:isKeysOwnedBy(target) or ent:isKeysAllowedToOwn(target) then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("rp_addowner_already_owns_door", target:Nick()))
        return ""
    end

    local canDo = hook.Call("onAllowedToOwnAdded", nil, ply, ent, target)
    if canDo == false then return "" end

    ent:addKeysAllowedToOwn(target)


    return ""
end
LynxonsRP.defineChatCommand("addowner", AddDoorOwner)
LynxonsRP.defineChatCommand("ao", AddDoorOwner)
