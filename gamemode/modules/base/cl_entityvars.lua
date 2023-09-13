local LynxonsRPVars = {}

--[[---------------------------------------------------------------------------
Interface
---------------------------------------------------------------------------]]
local pmeta = FindMetaTable("Player")
-- This function is made local to optimise getLynxonsRPVar, which is called often
-- enough to warrant optimizing. See https://github.com/FPtje/LynxonsRP/pull/3212
local get_user_id = pmeta.UserID
function pmeta:getLynxonsRPVar(var, fallback)
    local vars = LynxonsRPVars[get_user_id(self)]
    if vars == nil then return fallback end

    local results = vars[var]
    if results == nil then return fallback end

    return results
end

--[[---------------------------------------------------------------------------
Retrieve the information of a player var
---------------------------------------------------------------------------]]
local function RetrievePlayerVar(userID, var, value)
    local ply = Player(userID)
    LynxonsRPVars[userID] = LynxonsRPVars[userID] or {}

    hook.Call("LynxonsRPVarChanged", nil, ply, var, LynxonsRPVars[userID][var], value)
    LynxonsRPVars[userID][var] = value

    -- Backwards compatibility
    if IsValid(ply) then
        ply.LynxonsRPVars = LynxonsRPVars[userID]
    end
end

--[[---------------------------------------------------------------------------
Retrieve a player var.
Read the usermessage and attempt to set the LynxonsRP var
---------------------------------------------------------------------------]]
local function doRetrieve()
    local userID = net.ReadUInt(16)
    local var, value = LynxonsRP.readNetLynxonsRPVar()

    RetrievePlayerVar(userID, var, value)
end
net.Receive("LynxonsRP_PlayerVar", doRetrieve)

--[[---------------------------------------------------------------------------
Retrieve the message to remove a LynxonsRPVar
---------------------------------------------------------------------------]]
local function doRetrieveRemoval()
    local userID = net.ReadUInt(16)
    local vars = LynxonsRPVars[userID] or {}
    local var = LynxonsRP.readNetLynxonsRPVarRemoval()
    local ply = Player(userID)

    hook.Call("LynxonsRPVarChanged", nil, ply, var, vars[var], nil)

    vars[var] = nil
end
net.Receive("LynxonsRP_PlayerVarRemoval", doRetrieveRemoval)

--[[---------------------------------------------------------------------------
Initialize the LynxonsRPVars at the start of the game
---------------------------------------------------------------------------]]
local function InitializeLynxonsRPVars(len)
    local plyCount = net.ReadUInt(8)

    for i = 1, plyCount, 1 do
        local userID = net.ReadUInt(16)
        local varCount = net.ReadUInt(LynxonsRP.LynxonsRP_ID_BITS + 2)

        for j = 1, varCount, 1 do
            local var, value = LynxonsRP.readNetLynxonsRPVar()
            RetrievePlayerVar(userID, var, value)
        end
    end
end
net.Receive("LynxonsRP_InitializeVars", InitializeLynxonsRPVars)
timer.Simple(0, fp{RunConsoleCommand, "_sendLynxonsRPvars"})

net.Receive("LynxonsRP_LynxonsRPVarDisconnect", function(len)
    local userID = net.ReadUInt(16)
    LynxonsRPVars[userID] = nil
end)

--[[---------------------------------------------------------------------------
Request the LynxonsRPVars when they haven't arrived
---------------------------------------------------------------------------]]
timer.Create("LynxonsRPCheckifitcamethrough", 15, 0, function()
    for _, v in ipairs(player.GetAll()) do
        if v:getLynxonsRPVar("rpname") then continue end

        RunConsoleCommand("_sendLynxonsRPvars")
        return
    end

    timer.Remove("LynxonsRPCheckifitcamethrough")
end)
