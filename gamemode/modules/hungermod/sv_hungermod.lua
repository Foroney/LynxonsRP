local function HMPlayerSpawn(ply)
    ply:setSelfLynxonsRPVar("Energy", 100)
end
hook.Add("PlayerSpawn", "HMPlayerSpawn", HMPlayerSpawn)

local function HMThink()
    for _, v in ipairs(player.GetAll()) do
        if not v:Alive() then continue end
        v:hungerUpdate()
    end
end
timer.Create("HMThink", 10, 0, HMThink)

local function HMPlayerInitialSpawn(ply)
    ply:newHungerData()
end
hook.Add("PlayerInitialSpawn", "HMPlayerInitialSpawn", HMPlayerInitialSpawn)


local function BuyFood(ply, args)
    if args == "" then
        LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
        return ""
    end

    for _, v in pairs(FoodItems) do
        if string.lower(args) ~= string.lower(v.name) then continue end

        if (v.requiresCook == nil or v.requiresCook == true) and not ply:isCook() then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("unable", "/buyfood", LynxonsRP.getPhrase("cooks_only")))
            return ""
        end

        if v.customCheck and not v.customCheck(ply) then
            if v.customCheckMessage then
                LynxonsRP.notify(ply, 1, 4, v.customCheckMessage)
            end
            return ""
        end

        local foodTable = {
            cmd = "buyfood",
            max = GAMEMODE.Config.maxfooditems
        }

        if ply:customEntityLimitReached(foodTable) then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("limit", GAMEMODE.Config.chatCommandPrefix .. "buyfood"))

            return ""
        end

        ply:addCustomEntity(foodTable)

        local cost = v.price

        if not ply:canAfford(cost) then
            LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("cant_afford", LynxonsRP.getPhrase("food")))
            return ""
        end
        ply:addMoney(-cost)
        LynxonsRP.notify(ply, 0, 4, LynxonsRP.getPhrase("you_bought", v.name, LynxonsRP.formatMoney(cost), ""))

        local trace = {}
        trace.start = ply:EyePos()
        trace.endpos = trace.start + ply:GetAimVector() * 85
        trace.filter = ply

        local tr = util.TraceLine(trace)

        local SpawnedFood = ents.Create("spawned_food")
        SpawnedFood.LynxonsRPItem = foodTable
        SpawnedFood:Setowning_ent(ply)
        SpawnedFood:SetPos(tr.HitPos)
        SpawnedFood.onlyremover = true
        SpawnedFood.SID = ply.SID
        SpawnedFood:SetModel(v.model)

        -- for backwards compatibility
        SpawnedFood.FoodName = v.name
        SpawnedFood.FoodEnergy = v.energy
        SpawnedFood.FoodPrice = v.price

        SpawnedFood.foodItem = v
        SpawnedFood:Spawn()

        LynxonsRP.placeEntity(SpawnedFood, tr, ply)

        hook.Call("playerBoughtFood", nil, ply, v, SpawnedFood, cost)
        return ""
    end
    LynxonsRP.notify(ply, 1, 4, LynxonsRP.getPhrase("invalid_x", LynxonsRP.getPhrase("arguments"), ""))
    return ""
end
LynxonsRP.defineChatCommand("buyfood", BuyFood)
