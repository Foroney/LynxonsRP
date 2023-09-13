local function AddButtonToFrame(Frame)
    Frame:SetTall(Frame:GetTall() + 110)

    local button = vgui.Create("DButton", Frame)
    button:SetPos(10, Frame:GetTall() - 110)
    button:SetSize(180, 100)

    Frame.buttonCount = (Frame.buttonCount or 0) + 1
    Frame.lastButton = button
    return button
end

LynxonsRP.stub{
    name = "openKeysMenu",
    description = "Open the keys/F2 menu.",
    parameters = {},
    realm = "Client",
    returns = {},
    metatable = LynxonsRP
}

LynxonsRP.hookStub{
    name = "onKeysMenuOpened",
    description = "Called when the keys menu is opened.",
    parameters = {
        {
            name = "ent",
            description = "The door entity.",
            type = "Entity"
        },
        {
            name = "Frame",
            description = "The keys menu frame.",
            type = "Panel"
        }
    },
    returns = {
    },
    realm = "Client"
}

local KeyFrameVisible = false

local function openMenu(setDoorOwnerAccess, doorSettingsAccess)
    if KeyFrameVisible then return end
    local trace = LocalPlayer():GetEyeTrace()
    local ent = trace.Entity
    -- Don't open the menu if the entity is not ownable, the entity is too far away or the door settings are not loaded yet
    if not IsValid(ent) or not ent:isKeysOwnable() or trace.HitPos:DistToSqr(LocalPlayer():EyePos()) > 40000 then return end

    KeyFrameVisible = true
    local Frame = vgui.Create("DFrame")
    Frame:SetSize(200, 30) -- Base size
    Frame.btnMaxim:SetVisible(false)
    Frame.btnMinim:SetVisible(false)
    Frame:SetVisible(true)
    Frame:MakePopup()
    Frame:ParentToHUD()

    function Frame:Think()
        local tr = LocalPlayer():GetEyeTrace()
        local LAEnt = tr.Entity
        if not IsValid(LAEnt) or not LAEnt:isKeysOwnable() or tr.HitPos:DistToSqr(LocalPlayer():EyePos()) > 40000 then
            self:Close()
        end
        if not self.Dragging then return end
        local x = gui.MouseX() - self.Dragging[1]
        local y = gui.MouseY() - self.Dragging[2]
        x = math.Clamp(x, 0, ScrW() - self:GetWide())
        y = math.Clamp(y, 0, ScrH() - self:GetTall())
        self:SetPos(x, y)
    end

    local entType = LynxonsRP.getPhrase(ent:IsVehicle() and "vehicle" or "door")
    Frame:SetTitle(LynxonsRP.getPhrase("x_options", entType:gsub("^%a", string.upper)))

    function Frame:Close()
        KeyFrameVisible = false
        self:SetVisible(false)
        self:Remove()
    end

    -- All the buttons

    if ent:isKeysOwnedBy(LocalPlayer()) then
        local Owndoor = AddButtonToFrame(Frame)
        Owndoor:SetText(LynxonsRP.getPhrase("sell_x", entType))
        Owndoor.DoClick = function() RunConsoleCommand("LynxonsRP", "toggleown") Frame:Close() end

        local AddOwner = AddButtonToFrame(Frame)
        AddOwner:SetText(LynxonsRP.getPhrase("add_owner"))
        AddOwner.DoClick = function()
            local menu = DermaMenu()
            menu.found = false
            for _, v in pairs(LynxonsRP.nickSortedPlayers()) do
                if not ent:isKeysOwnedBy(v) and not ent:isKeysAllowedToOwn(v) then
                    local steamID = v:SteamID()
                    menu.found = true
                    menu:AddOption(v:Nick(), function() RunConsoleCommand("LynxonsRP", "ao", steamID) end)
                end
            end
            if not menu.found then
                menu:AddOption(LynxonsRP.getPhrase("noone_available"), function() end)
            end
            menu:Open()
        end

        local RemoveOwner = AddButtonToFrame(Frame)
        RemoveOwner:SetText(LynxonsRP.getPhrase("remove_owner"))
        RemoveOwner.DoClick = function()
            local menu = DermaMenu()
            for _, v in pairs(LynxonsRP.nickSortedPlayers()) do
                if (ent:isKeysOwnedBy(v) and not ent:isMasterOwner(v)) or ent:isKeysAllowedToOwn(v) then
                    local steamID = v:SteamID()
                    menu.found = true
                    menu:AddOption(v:Nick(), function() RunConsoleCommand("LynxonsRP", "ro", steamID) end)
                end
            end
            if not menu.found then
                menu:AddOption(LynxonsRP.getPhrase("noone_available"), function() end)
            end
            menu:Open()
        end
        if not ent:isMasterOwner(LocalPlayer()) then
            RemoveOwner:SetDisabled(true)
        end
    end

    if doorSettingsAccess then
        local DisableOwnage = AddButtonToFrame(Frame)
        DisableOwnage:SetText(LynxonsRP.getPhrase(ent:getKeysNonOwnable() and "allow_ownership" or "disallow_ownership"))
        DisableOwnage.DoClick = function() Frame:Close() RunConsoleCommand("LynxonsRP", "toggleownable") end
    end

    if doorSettingsAccess and (ent:isKeysOwned() or ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or hasTeams) or ent:isKeysOwnedBy(LocalPlayer()) then
        local DoorTitle = AddButtonToFrame(Frame)
        DoorTitle:SetText(LynxonsRP.getPhrase("set_x_title", entType))
        DoorTitle.DoClick = function()
            Derma_StringRequest(LynxonsRP.getPhrase("set_x_title", entType), LynxonsRP.getPhrase("set_x_title_long", entType), "", function(text)
                RunConsoleCommand("LynxonsRP", "title", text)
                if IsValid(Frame) then
                    Frame:Close()
                end
            end,
            function() end, LynxonsRP.getPhrase("ok"), LynxonsRP.getPhrase("cancel"))
        end
    end

    if not ent:isKeysOwned() and not ent:getKeysNonOwnable() and not ent:getKeysDoorGroup() and not ent:getKeysDoorTeams() or not ent:isKeysOwnedBy(LocalPlayer()) and ent:isKeysAllowedToOwn(LocalPlayer()) then
        local Owndoor = AddButtonToFrame(Frame)
        Owndoor:SetText(LynxonsRP.getPhrase("buy_x", entType))
        Owndoor.DoClick = function() RunConsoleCommand("LynxonsRP", "toggleown") Frame:Close() end
    end

    if doorSettingsAccess then
        local EditDoorGroups = AddButtonToFrame(Frame)
        EditDoorGroups:SetText(LynxonsRP.getPhrase("edit_door_group"))
        EditDoorGroups.DoClick = function()
            local menu = DermaMenu()
            local groups = menu:AddSubMenu(LynxonsRP.getPhrase("door_groups"))
            local teams = menu:AddSubMenu(LynxonsRP.getPhrase("jobs"))
            local add = teams:AddSubMenu(LynxonsRP.getPhrase("add"))
            local remove = teams:AddSubMenu(LynxonsRP.getPhrase("remove"))

            menu:AddOption(LynxonsRP.getPhrase("none"), function()
                RunConsoleCommand("LynxonsRP", "togglegroupownable")
                if IsValid(Frame) then Frame:Close() end
            end)

            for k in pairs(RPExtraTeamDoors) do
                groups:AddOption(k, function()
                    RunConsoleCommand("LynxonsRP", "togglegroupownable", k)
                    if IsValid(Frame) then Frame:Close() end
                end)
            end

            local doorTeams = ent:getKeysDoorTeams()
            for k, v in pairs(RPExtraTeams) do
                local which = (not doorTeams or not doorTeams[k]) and add or remove
                which:AddOption(v.name, function()
                    RunConsoleCommand("LynxonsRP", "toggleteamownable", k)
                    if IsValid(Frame) then Frame:Close() end
                end)
            end

            menu:Open()
        end
    end

    if Frame.buttonCount == 1 then
        Frame.lastButton:DoClick()
    elseif Frame.buttonCount == 0 or not Frame.buttonCount then
        Frame:Close()
        KeyFrameVisible = true
        timer.Simple(0.3, function() KeyFrameVisible = false end)
    end


    hook.Call("onKeysMenuOpened", nil, ent, Frame)

    Frame:Center()
    Frame:SetSkin(GAMEMODE.Config.LynxonsRPSkin)
end

function LynxonsRP.openKeysMenu(um)
    CAMI.PlayerHasAccess(LocalPlayer(), "LynxonsRP_SetDoorOwner", function(setDoorOwnerAccess)
        CAMI.PlayerHasAccess(LocalPlayer(), "LynxonsRP_ChangeDoorSettings", fp{openMenu, setDoorOwnerAccess})
    end)
end
usermessage.Hook("KeysMenu", LynxonsRP.openKeysMenu)
