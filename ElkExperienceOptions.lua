local panel = CreateFrame("FRAME", "ElkExperiencePanel", InterfaceOptionsFramePanelContainer)
panel.name = "ElkExperience"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ElkExperience")

local subtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtext:SetHeight(32)
subtext:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtext:SetPoint("RIGHT", -32, 0)
subtext:SetJustifyH("LEFT")
subtext:SetJustifyV("TOP")
subtext:SetText("These are only some minimal settings for the moment. Some more will most likely follow in later versions.")

-- -----
-- LDBIcon
-- -----
local LDBIcon_Box = CreateFrame("FRAME", "ElkExperiencePanel_LDBIcon_Box", panel, "OptionsBoxTemplate")
LDBIcon_Box:SetHeight(36)
LDBIcon_Box:SetWidth(186)
LDBIcon_Box:SetPoint("TOPLEFT", 16, -96)
LDBIcon_Box:SetBackdropBorderColor(0.4, 0.4, 0.4);
LDBIcon_Box:SetBackdropColor(0.15, 0.15, 0.15);
_G["ElkExperiencePanel_LDBIcon_BoxTitle"]:SetText("MiniMap Icon");

local LDBIcon_Show = CreateFrame("CHECKBUTTON", "ElkExperiencePanel_LDBIcon_Show", panel, "InterfaceOptionsSmallCheckButtonTemplate")
LDBIcon_Show:SetPoint("TOPLEFT", LDBIcon_Box, "TOPLEFT", 8, -6)
_G["ElkExperiencePanel_LDBIcon_ShowText"]:SetText("Show")
LDBIcon_Show.setFunc = function(v)
	LibStub("AceAddon-3.0"):GetAddon("ElkExperience").db.profile.minimap.hide = (v ~= "1")
	LibStub("LibDBIcon-1.0"):Refresh("ElkExperience")
end

-- -----
-- other stuff
-- -----
panel.refresh = function()
	LDBIcon_Show:SetChecked(not LibStub("AceAddon-3.0"):GetAddon("ElkExperience").db.profile.minimap.hide)
end

InterfaceOptions_AddCategory(panel)
