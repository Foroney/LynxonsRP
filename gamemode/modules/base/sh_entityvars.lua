local maxId = 0
local LynxonsRPVars = {}
local LynxonsRPVarById = {}

-- the amount of bits assigned to the value that determines which LynxonsRPVar we're sending/receiving
local LynxonsRP_ID_BITS = 8
local UNKNOWN_LynxonsRPVAR = 255 -- Should be equal to 2^LynxonsRP_ID_BITS - 1
LynxonsRP.LynxonsRP_ID_BITS = LynxonsRP_ID_BITS

function LynxonsRP.registerLynxonsRPVar(name, writeFn, readFn)
    maxId = maxId + 1

    -- UNKNOWN_LynxonsRPVAR is reserved for unknown values
    if maxId >= UNKNOWN_LynxonsRPVAR then LynxonsRP.error(string.format("Too many LynxonsRPVar registrations! LynxonsRPVar '%s' triggered this error", name), 2) end

    LynxonsRPVars[name] = {id = maxId, name = name, writeFn = writeFn, readFn = readFn}
    LynxonsRPVarById[maxId] = LynxonsRPVars[name]
end

-- Unknown values have unknown types and unknown identifiers, so this is sent inefficiently
local function writeUnknown(name, value)
    net.WriteUInt(UNKNOWN_LynxonsRPVAR, 8)
    net.WriteString(name)
    net.WriteType(value)
end

-- Read the value of a LynxonsRPVar that was not registered
local function readUnknown()
    return net.ReadString(), net.ReadType(net.ReadUInt(8))
end

local warningsShown = {}
local function warnRegistration(name)
    if warningsShown[name] then return end
    warningsShown[name] = true

    LynxonsRP.errorNoHalt(string.format([[Warning! LynxonsRPVar '%s' wasn't registered!
        Please contact the author of the LynxonsRP Addon to fix this.
        Until this is fixed you don't need to worry about anything. Everything will keep working.
        It's just that registering LynxonsRPVars would make LynxonsRP faster.]], name), 4)
end

function LynxonsRP.writeNetLynxonsRPVar(name, value)
    local LynxonsRPVar = LynxonsRPVars[name]
    if not LynxonsRPVar then
        warnRegistration(name)

        return writeUnknown(name, value)
    end

    net.WriteUInt(LynxonsRPVar.id, LynxonsRP_ID_BITS)
    return LynxonsRPVar.writeFn(value)
end

function LynxonsRP.writeNetLynxonsRPVarRemoval(name)
    local LynxonsRPVar = LynxonsRPVars[name]
    if not LynxonsRPVar then
        warnRegistration(name)

        net.WriteUInt(UNKNOWN_LynxonsRPVAR, 8)
        net.WriteString(name)
        return
    end

    net.WriteUInt(LynxonsRPVar.id, LynxonsRP_ID_BITS)
end

function LynxonsRP.readNetLynxonsRPVar()
    local LynxonsRPVarId = net.ReadUInt(LynxonsRP_ID_BITS)
    local LynxonsRPVar = LynxonsRPVarById[LynxonsRPVarId]

    if LynxonsRPVarId == UNKNOWN_LynxonsRPVAR then
        local name, value = readUnknown()

        return name, value
    end

    local val = LynxonsRPVar.readFn(value)

    return LynxonsRPVar.name, val
end

function LynxonsRP.readNetLynxonsRPVarRemoval()
    local id = net.ReadUInt(LynxonsRP_ID_BITS)
    return id == 255 and net.ReadString() or LynxonsRPVarById[id].name
end

-- The money is a double because it accepts higher values than Int and UInt, which are undefined for >32 bits
LynxonsRP.registerLynxonsRPVar("money",         net.WriteDouble, net.ReadDouble)
LynxonsRP.registerLynxonsRPVar("salary",        fp{fn.Flip(net.WriteInt), 32}, fp{net.ReadInt, 32})
LynxonsRP.registerLynxonsRPVar("rpname",        net.WriteString, net.ReadString)
LynxonsRP.registerLynxonsRPVar("job",           net.WriteString, net.ReadString)
LynxonsRP.registerLynxonsRPVar("HasGunlicense", net.WriteBit, fc{tobool, net.ReadBit})
LynxonsRP.registerLynxonsRPVar("Arrested",      net.WriteBit, fc{tobool, net.ReadBit})
LynxonsRP.registerLynxonsRPVar("wanted",        net.WriteBit, fc{tobool, net.ReadBit})
LynxonsRP.registerLynxonsRPVar("wantedReason",  net.WriteString, net.ReadString)
LynxonsRP.registerLynxonsRPVar("agenda",        net.WriteString, net.ReadString)

--[[---------------------------------------------------------------------------
RP name override
---------------------------------------------------------------------------]]
local pmeta = FindMetaTable("Player")
pmeta.SteamName = pmeta.SteamName or pmeta.Name
function pmeta:Name()
    if not self:IsValid() then LynxonsRP.error("Attempt to call Name/Nick/GetName on a non-existing player!", SERVER and 1 or 2) end
    return GAMEMODE.Config.allowrpnames and self:getLynxonsRPVar("rpname")
        or self:SteamName()
end
pmeta.GetName = pmeta.Name
pmeta.Nick = pmeta.Name
