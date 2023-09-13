-- Modification loader.
-- Dependencies:
--     - fn
--     - simplerr

--[[---------------------------------------------------------------------------
Disabled defaults
---------------------------------------------------------------------------]]
LynxonsRP.disabledDefaults = {}
LynxonsRP.disabledDefaults["modules"] = {
    ["chatsounds"]       = false,
    ["events"]           = false,
    ["fpp"]              = false,
    ["hud"]              = false,
    ["playerscale"]      = false,
}

LynxonsRP.disabledDefaults["agendas"]          = {}
LynxonsRP.disabledDefaults["ammo"]             = {}
LynxonsRP.disabledDefaults["demotegroups"]     = {}
LynxonsRP.disabledDefaults["doorgroups"]       = {}
LynxonsRP.disabledDefaults["entities"]         = {}
LynxonsRP.disabledDefaults["food"]             = {}
LynxonsRP.disabledDefaults["groupchat"]        = {}
LynxonsRP.disabledDefaults["jobs"]             = {}
LynxonsRP.disabledDefaults["shipments"]        = {}
LynxonsRP.disabledDefaults["vehicles"]         = {}
LynxonsRP.disabledDefaults["workarounds"]      = {}

-- The client cannot use simplerr.runLuaFile because of restrictions in GMod.
local doInclude = CLIENT and include or fc{simplerr.wrapError, simplerr.wrapLog, simplerr.runFile}

if file.Exists("LynxonsRP_config/disabled_defaults.lua", "LUA") then
    if SERVER then AddCSLuaFile("LynxonsRP_config/disabled_defaults.lua") end
    doInclude("LynxonsRP_config/disabled_defaults.lua")
end

--[[---------------------------------------------------------------------------
Config
---------------------------------------------------------------------------]]
local configFiles = {
    "LynxonsRP_config/settings.lua",
    "LynxonsRP_config/licenseweapons.lua",
}

for _, File in pairs(configFiles) do
    if not file.Exists(File, "LUA") then continue end

    if SERVER then AddCSLuaFile(File) end
    doInclude(File)
end
if SERVER and file.Exists("LynxonsRP_config/mysql.lua", "LUA") then doInclude("LynxonsRP_config/mysql.lua") end

--[[---------------------------------------------------------------------------
Modules
---------------------------------------------------------------------------]]
local function loadModules()
    local fol = "LynxonsRP_modules/"

    local _, folders = file.Find(fol .. "*", "LUA")

    for _, folder in SortedPairs(folders, true) do
        if folder == "." or folder == ".." or GAMEMODE.Config.DisabledCustomModules[folder] then continue end
        -- Sound but incomplete way of detecting the error of putting addons in the LynxonsRPmod folder
        if file.Exists(fol .. folder .. "/addon.txt", "LUA") or file.Exists(fol .. folder .. "/addon.json", "LUA") then
            LynxonsRP.errorNoHalt("Addon detected in the LynxonsRP_modules folder.", 2, {
                "This addon is not supposed to be in the LynxonsRP_modules folder.",
                "It is supposed to be in garrysmod/addons/ instead.",
                "Whether a mod is to be installed in LynxonsRP_modules or addons is the author's decision.",
                "Please read the readme of the addons you're installing next time."
            },
            "<LynxonsRPmod addon>/lua/LynxonsRP_modules/" .. folder, -1)
            continue
        end

        for _, File in SortedPairs(file.Find(fol .. folder .. "/sh_*.lua", "LUA"), true) do
            if SERVER then
                AddCSLuaFile(fol .. folder .. "/" .. File)
            end

            if File == "sh_interface.lua" then continue end
            doInclude(fol .. folder .. "/" .. File)
        end

        if SERVER then
            for _, File in SortedPairs(file.Find(fol .. folder .. "/sv_*.lua", "LUA"), true) do
                if File == "sv_interface.lua" then continue end
                doInclude(fol .. folder .. "/" .. File)
            end
        end

        for _, File in SortedPairs(file.Find(fol .. folder .. "/cl_*.lua", "LUA"), true) do
            if File == "cl_interface.lua" then continue end

            if SERVER then
                AddCSLuaFile(fol .. folder .. "/" .. File)
            else
                doInclude(fol .. folder .. "/" .. File)
            end
        end
    end
end

local function loadLanguages()
    local fol = "LynxonsRP_language/"

    local files, _ = file.Find(fol .. "*", "LUA")
    for _, File in pairs(files) do
        if SERVER then AddCSLuaFile(fol .. File) end
        doInclude(fol .. File)
    end
end

local customFiles = {
    "LynxonsRP_customthings/jobs.lua",
    "LynxonsRP_customthings/shipments.lua",
    "LynxonsRP_customthings/entities.lua",
    "LynxonsRP_customthings/vehicles.lua",
    "LynxonsRP_customthings/food.lua",
    "LynxonsRP_customthings/ammo.lua",
    "LynxonsRP_customthings/groupchats.lua",
    "LynxonsRP_customthings/categories.lua",
    "LynxonsRP_customthings/agendas.lua", -- has to be run after jobs.lua
    "LynxonsRP_customthings/doorgroups.lua", -- has to be run after jobs.lua
    "LynxonsRP_customthings/demotegroups.lua", -- has to be run after jobs.lua
}
local function loadCustomLynxonsRPItems()
    for _, File in pairs(customFiles) do
        if not file.Exists(File, "LUA") then continue end
        if File == "LynxonsRP_customthings/food.lua" and LynxonsRP.disabledDefaults["modules"]["hungermod"] then continue end

        if SERVER then AddCSLuaFile(File) end
        doInclude(File)
    end
end


function GM:LynxonsRPFinishedLoading()
    -- GAMEMODE gets set after the last statement in the gamemode files is run. That is not the case in this hook
    GAMEMODE = GAMEMODE or GM

    loadLanguages()
    loadModules()
    loadCustomLynxonsRPItems()
    hook.Call("loadCustomLynxonsRPItems", self)
    hook.Call("postLoadCustomLynxonsRPItems", self)
end
