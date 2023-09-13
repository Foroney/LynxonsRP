local PANEL = {}

AccessorFunc(PANEL, "borderColor", "BorderColor")

local white = color_white
local black = color_black
local gray = Color(140, 140, 140, 255)
local darkgray = Color(50, 50, 50, 255)

--[[---------------------------------------------------------------------------
Generic item
---------------------------------------------------------------------------]]
function PANEL:Init()
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)

    self:SetCursor("hand")

    self:SetFont("F4MenuFont01")
    self:SetTextColor(white)
    self:SetTall(60)
    self:DockPadding(0, 0, 10, 5)

    self.model = self.model or vgui.Create("ModelImage", self)
    self.model:SetSize(60, 60)
    self.model:SetPos(0, 0)

    self.txtRight = self.txtRight or vgui.Create("DLabel", self)
    self.txtRight:SetFont("F4MenuFont01")
    self.txtRight:Dock(RIGHT)
    self.txtRight:SetTextColor(white)
end

function PANEL:Paint(w, h)
    local disabled = self:GetDisabled()
    local x, y = self.Depressed and 2 or 0, self.Depressed and 2 or 0
    w, h = self.Depressed and w - 4 or w, self.Depressed and h - 4 or h

    draw.RoundedBox(4, x, y, w, h, disabled and darkgray or black) -- background

    draw.RoundedBoxEx(4, h, h - 10 + y, w - h + x, 10,
        self.LynxonsRPItem and self.LynxonsRPItem.buttonColor or not disabled and (self:GetBorderColor() or black) or darkgray,
        false, false, false, true) -- the colored bar

    draw.RoundedBoxEx(4, x, y, h, h, disabled and darkgray or gray, true, false, false, false) -- gray box for the model
end

function PANEL:SetModel(mdl, skin)
    self.model:SetModel(mdl, skin, "000000000")
end

function PANEL:SetTextRight(text)
    self.txtRight:SetText(text)
    self.txtRight:SizeToContents()
    self.txtRight:Dock(RIGHT)
end

-- For overriding
function PANEL:setLynxonsRPItem(item)
    self.LynxonsRPItem = item
end

function PANEL:Refresh()

end

-- SetDisabled. Disables the button and hides it when the config options are set right
-- rules: always hide if hideNonBuyable, only hide items that have nothing to do with your situation (like items for another job) with hideTeamUnbuyable
function PANEL:SetDisabled(b, isImportant)
    self.m_bDisabled = b
    if GAMEMODE.Config.hideNonBuyable or (isImportant and GAMEMODE.Config.hideTeamUnbuyable) and b then
        self:SetVisible(false)
    else
        self:SetVisible(true)
    end
end

derma.DefineControl("F4MenuItemButton", "", PANEL, "DButton")

--[[---------------------------------------------------------------------------
Job item
---------------------------------------------------------------------------]]
PANEL = {}

local function getMaxOfTeam(job)
    if not job.max or job.max == 0 then return "∞" end
    if job.max % 1 == 0 then return tostring(job.max) end

    return tostring(math.floor(job.max * player.GetCount()))
end

local function canGetJob(job)
    local ply = LocalPlayer()

    if isnumber(job.NeedToChangeFrom) and ply:Team() ~= job.NeedToChangeFrom then return false, true end
    if istable(job.NeedToChangeFrom) and not table.HasValue(job.NeedToChangeFrom, ply:Team()) then return false, true end
    if job.customCheck and not job.customCheck(ply) then return false, true end
    if ply:Team() == job.team then return false, true end
    local numPlayers = team.NumPlayers(job.team)
    if job.max ~= 0 and ((job.max % 1 == 0 and numPlayers >= job.max) or (job.max % 1 ~= 0 and (numPlayers + 1) / player.GetCount() > job.max)) then return false, false end
    if job.admin == 1 and not ply:IsAdmin() then return false, true end
    if job.admin > 1 and not ply:IsSuperAdmin() then return false, true end


    return true
end

function PANEL:setLynxonsRPItem(job)
    self.BaseClass.setLynxonsRPItem(self, job)

    local model = isfunction(job.PlayerSetModel) and job.PlayerSetModel(LocalPlayer()) or
                  istable(job.model) and job.model[1] or
                  job.model

    self:SetBorderColor(job.color)
    self:SetModel(model)
    self:SetText(job.label or job.name)
    self:SetTextRight(string.format("%s/%s", team.NumPlayers(job.team), getMaxOfTeam(job)))

    local canGet, important = canGetJob(job)
    self:SetDisabled(not canGet, important)
end

function PANEL:DoDoubleClick()
    if self:GetDisabled() then return end

    local job = self.LynxonsRPItem
    if (job.RequiresVote == nil and job.vote) or (job.RequiresVote ~= nil and job.RequiresVote(LocalPlayer(), job.team)) then
        RunConsoleCommand("LynxonsRP", "vote" .. job.command)
    else
        RunConsoleCommand("LynxonsRP", job.command)
    end

    timer.Simple(1, function() LynxonsRP.getF4MenuPanel():Refresh() end)
end

function PANEL:Refresh()
    self:SetTextRight(string.format("%s/%s", team.NumPlayers(self.LynxonsRPItem.team), getMaxOfTeam(self.LynxonsRPItem)))

    local canGet, important = canGetJob(self.LynxonsRPItem)
    self:SetDisabled(not canGet, important)
end

derma.DefineControl("F4MenuJobButton", "", PANEL, "F4MenuItemButton")

--[[---------------------------------------------------------------------------
custom entity button
---------------------------------------------------------------------------]]
PANEL = {}

function PANEL:setLynxonsRPItem(item)
    local cost = item.getPrice and item.getPrice(LocalPlayer(), item.price) or item.price

    self.BaseClass.setLynxonsRPItem(self, item)
    self:SetBorderColor(Color(140, 0, 0, 180))
    self:SetModel(item.model, item.skin)
    self:SetText(item.label or item.name)
    self:SetTextRight(LynxonsRP.formatMoney(cost))
end

function PANEL:updatePrice(price)
    if not price then return end

    self:SetTextRight(LynxonsRP.formatMoney(price))
end

derma.DefineControl("F4MenuEntityButton", "", PANEL, "F4MenuItemButton")

--[[---------------------------------------------------------------------------
Button for purchasing guns
---------------------------------------------------------------------------]]
PANEL = {}

function PANEL:setLynxonsRPItem(item)
    local cost = item.getPrice and item.getPrice(LocalPlayer(), item.pricesep) or item.pricesep

    self.BaseClass.setLynxonsRPItem(self, item)
    self:SetBorderColor(Color(140, 0, 0, 180))
    self:SetModel(item.model)
    self:SetText(item.label or item.name)
    self:SetTextRight(LynxonsRP.formatMoney(cost))

    self.DoClick = fn.Partial(RunConsoleCommand, "LynxonsRP", "buy", self.LynxonsRPItem.name)
end

function PANEL:updatePrice(price)
    if not price then return end

    self:SetTextRight(LynxonsRP.formatMoney(price))
end

derma.DefineControl("F4MenuPistolButton", "", PANEL, "F4MenuItemButton")
