
local PANEL = {}

function PANEL:Init()
	self.m_iVal = 1
end

function PANEL:SetValue(value)
	self.m_iVal = value

	self:OnChange(value)
end

function PANEL:GetValue()
	return self.m_iVal
end

function PANEL:Paint(_, h)
	draw.RoundedBox(2, 0, 0, h, h, Color(0, 0, 0, 200))
	draw.RoundedBox(2, 1, 1, h - 2, h - 2, color_white)

	if (self:GetValue() < 0) then
		surface.SetDrawColor(Color(189, 118, 118, 255))

		surface.DrawLine(3, 3, h - 3, h - 3)
		surface.DrawLine(4, 3, h - 3, h - 4)
		surface.DrawLine(3, 4, h - 4, h - 3)

		surface.DrawLine(h - 4, 3, 2, h - 3)
		surface.DrawLine(h - 5, 3, 2, h - 4)
		surface.DrawLine(h - 4, 4, 3, h - 3)
	elseif (self:GetValue() == 0) then
		draw.RoundedBox(2, 3, 3, h - 6, h - 6, Color(0, 0, 0, 210))
	end
end

function PANEL:OnChange()
end

function PANEL:OnMousePressed()
	if (self:GetValue() ~= -1) then
		self:SetValue(-1)
	else
		self:SetValue(1)
	end
	self:Paint()
end

vgui.Register("WCheckBox", PANEL, "DPanel");