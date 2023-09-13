util.AddNetworkString("LynxonsRP_UpdateDoorData")
util.AddNetworkString("LynxonsRP_RemoveDoorData")
util.AddNetworkString("LynxonsRP_RemoveDoorVar")
util.AddNetworkString("LynxonsRP_AllDoorData")

--[[---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------]]
local eMeta = FindMetaTable("Entity")
function eMeta:getDoorData()
    if not self:isKeysOwnable() then return {} end

    self.DoorData = self.DoorData or {}
    return self.DoorData
end

function eMeta:setKeysNonOwnable(ownable)
    self:getDoorData().nonOwnable = ownable or nil
    LynxonsRP.updateDoorData(self, "nonOwnable")
end

function eMeta:setKeysTitle(title)
    self:getDoorData().title = title ~= "" and title or nil
    LynxonsRP.updateDoorData(self, "title")
end

function eMeta:setDoorGroup(group)
    self:getDoorData().groupOwn = group
    LynxonsRP.updateDoorData(self, "groupOwn")
end

function eMeta:addKeysDoorTeam(t)
    local doorData = self:getDoorData()
    doorData.teamOwn = doorData.teamOwn or {}
    doorData.teamOwn[t] = true

    LynxonsRP.updateDoorData(self, "teamOwn")
end

function eMeta:removeKeysDoorTeam(t)
    local doorData = self:getDoorData()
    doorData.teamOwn = doorData.teamOwn or {}
    doorData.teamOwn[t] = nil

    if fn.Null(doorData.teamOwn) then
        doorData.teamOwn = nil
    end

    LynxonsRP.updateDoorData(self, "teamOwn")
end

function eMeta:removeAllKeysDoorTeams()
    local doorData = self:getDoorData()
    doorData.teamOwn = nil

    LynxonsRP.updateDoorData(self, "teamOwn")
end

function eMeta:addKeysAllowedToOwn(ply)
    local doorData = self:getDoorData()
    doorData.allowedToOwn = doorData.allowedToOwn or {}
    doorData.allowedToOwn[ply:UserID()] = true

    LynxonsRP.updateDoorData(self, "allowedToOwn")
end

function eMeta:removeKeysAllowedToOwn(ply)
    local doorData = self:getDoorData()
    doorData.allowedToOwn = doorData.allowedToOwn or {}
    doorData.allowedToOwn[ply:UserID()] = nil

    if fn.Null(doorData.allowedToOwn) then
        doorData.allowedToOwn = nil
    end

    LynxonsRP.updateDoorData(self, "allowedToOwn")
end

function eMeta:removeAllKeysAllowedToOwn()
    local doorData = self:getDoorData()
    doorData.allowedToOwn = nil

    LynxonsRP.updateDoorData(self, "allowedToOwn")
end

function eMeta:addKeysDoorOwner(ply)
    local doorData = self:getDoorData()
    doorData.extraOwners = doorData.extraOwners or {}
    doorData.extraOwners[ply:UserID()] = true

    LynxonsRP.updateDoorData(self, "extraOwners")

    self:removeKeysAllowedToOwn(ply)
end

function eMeta:removeKeysDoorOwner(ply)
    local doorData = self:getDoorData()
    doorData.extraOwners = doorData.extraOwners or {}
    doorData.extraOwners[ply:UserID()] = nil

    if fn.Null(doorData.extraOwners) then
        doorData.extraOwners = nil
    end

    LynxonsRP.updateDoorData(self, "extraOwners")
end

function eMeta:removeAllKeysExtraOwners()
    local doorData = self:getDoorData()
    doorData.extraOwners = nil

    LynxonsRP.updateDoorData(self, "extraOwners")
end

function eMeta:removeDoorData()
    net.Start("LynxonsRP_RemoveDoorData")
        net.WriteUInt(self:EntIndex(), 32)
    net.Send(player.GetAll())
end

--[[---------------------------------------------------------------------------
Networking
---------------------------------------------------------------------------]]

local plyMeta = FindMetaTable("Player")
function plyMeta:sendDoorData()
    if self:EntIndex() == 0 then return end

    local res = {}
    for _, v in ipairs(ents.GetAll()) do
        if not v:getDoorData() or table.IsEmpty(v:getDoorData()) then continue end

        res[v:EntIndex()] = v:getDoorData()
    end

    net.Start("LynxonsRP_AllDoorData")
        net.WriteUInt(table.Count(res), 16)

        for ix, vars in pairs(res) do
            net.WriteUInt(ix, 16)

            net.WriteUInt(table.Count(vars), 8)

            for varName, value in pairs(vars) do
                LynxonsRP.writeNetDoorVar(varName, value)
            end
        end
    net.Send(self)
end
concommand.Add("_sendAllDoorData", fn.Id) -- Backwards compatibility

hook.Add("PlayerInitialSpawn", "LynxonsRP_DoorData", plyMeta.sendDoorData)

function LynxonsRP.updateDoorData(door, member)
    if not IsValid(door) or not door:getDoorData() then error("Calling updateDoorData on a door that has no data!") end

    local value = door:getDoorData()[member]

    if value == nil then
        local doorvar = LynxonsRP.getDoorVarsByName()[member]
        net.Start("LynxonsRP_RemoveDoorVar")
            net.WriteUInt(door:EntIndex(), 16)
            if not doorvar then
                net.WriteUInt(0, 8)
                net.WriteString(member)
            else
                net.WriteUInt(doorvar.id, 8)
            end
        net.Broadcast()

        return
    end

    net.Start("LynxonsRP_UpdateDoorData")
        net.WriteUInt(door:EntIndex(), 32)
        LynxonsRP.writeNetDoorVar(member, value)
    net.Broadcast()
end
