local f4Frame

--[[---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------]]
function LynxonsRP.openF4Menu()
    if IsValid(f4Frame) then
        f4Frame:Show()
        f4Frame:InvalidateLayout()
    else
        f4Frame = vgui.Create("F4MenuFrame")
        f4Frame:generateTabs()
    end
end

function LynxonsRP.closeF4Menu()
    if f4Frame then
        f4Frame:Hide()
    end
end

function LynxonsRP.toggleF4Menu()
    if not IsValid(f4Frame) or not f4Frame:IsVisible() then
        LynxonsRP.openF4Menu()
    else
        LynxonsRP.closeF4Menu()
    end
end

function LynxonsRP.getF4MenuPanel()
    return f4Frame
end

function LynxonsRP.addF4MenuTab(name, panel, order)
    if not f4Frame then LynxonsRP.error("LynxonsRP.addF4MenuTab called at the wrong time. Please call in the F4MenuTabs hook.", 2) end

    return f4Frame:createTab(name, panel, order)
end

function LynxonsRP.removeF4MenuTab(name)
    if not f4Frame then LynxonsRP.error("LynxonsRP.removeF4MenuTab called at the wrong time. Please call in the F4MenuTabs hook.", 2) end

    f4Frame:removeTab(name)
end

function LynxonsRP.switchTabOrder(tab1, tab2)
    if not f4Frame then LynxonsRP.error("LynxonsRP.switchTabOrder called at the wrong time. Please call in the F4MenuTabs hook.", 2) end

    f4Frame:switchTabOrder(tab1, tab2)
end


--[[---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------]]
function LynxonsRP.hooks.F4MenuTabs()
    LynxonsRP.addF4MenuTab(LynxonsRP.getPhrase("jobs"), vgui.Create("F4MenuJobs"))
    LynxonsRP.addF4MenuTab(LynxonsRP.getPhrase("F4entities"), vgui.Create("F4MenuEntities"))

    local shipments = fn.Filter(fn.Compose{fn.Not, fn.Curry(fn.GetValue, 2)("noship")}, CustomShipments)
    if not table.IsEmpty(shipments) then
        LynxonsRP.addF4MenuTab(LynxonsRP.getPhrase("Shipments"), vgui.Create("F4MenuShipments"))
    end

    local guns = fn.Filter(fn.Curry(fn.GetValue, 2)("separate"), CustomShipments)
    if not table.IsEmpty(guns) then
        LynxonsRP.addF4MenuTab(LynxonsRP.getPhrase("F4guns"), vgui.Create("F4MenuGuns"))
    end

    if not table.IsEmpty(GAMEMODE.AmmoTypes) then
        LynxonsRP.addF4MenuTab(LynxonsRP.getPhrase("F4ammo"), vgui.Create("F4MenuAmmo"))
    end

    if not table.IsEmpty(CustomVehicles) then
        LynxonsRP.addF4MenuTab(LynxonsRP.getPhrase("F4vehicles"), vgui.Create("F4MenuVehicles"))
    end
end

hook.Add("LynxonsRPVarChanged", "RefreshF4Menu", function(ply, varname)
    if ply ~= LocalPlayer() or varname ~= "money" or not IsValid(f4Frame) or not f4Frame:IsVisible() then return end

    f4Frame:InvalidateLayout()
end)

--[[---------------------------------------------------------------------------
Fonts
---------------------------------------------------------------------------]]
-- font is not found otherwise
surface.CreateFont("Roboto Light", {
        size = 19,
        weight = 300,
        antialias = true,
        shadow = false,
        font = "Roboto Light",
        extended = true,
    })

surface.CreateFont("F4MenuFont01", {
        size = 23,
        weight = 400,
        antialias = true,
        shadow = false,
        font = "Roboto Light",
        extended = true,
    })

surface.CreateFont("F4MenuFont02", {
        size = 30,
        weight = 800,
        antialias = true,
        shadow = false,
        font = "Roboto Light",
        extended = true,
    })
