local ElkExperience = LibStub("AceAddon-3.0"):NewAddon("ElkExperience", "AceEvent-3.0", "AceConsole-3.0")

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local string_format = string.format

local DBdefaults = {
	profile = {
		minimap = {
			hide = false,
		},
	},
}

local timeTotal    = 0           -- timestamp for char creation (relative to playtime)
local timeLevel    = 0           -- timestamp for last levelup (relative to playtime)
local timeSession  = time()      -- timestamp for session start

local xpLastGain      = 0        -- last xp gain
local xpLevelInitial  = nil      -- xp in current level at session start
local xpLevelCurrent  = 0        -- current xp
local xpSession       = 0        -- total xp earned this session
local xpAccumulated   = 0        -- xp earned this session before current level

local tooltipAnchorFrame = nil

local function do_OnEnter(frame)
	tooltipAnchorFrame = frame
--~ 	GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetOwner(frame, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
	ElkExperience:UpdateTooltip()
end

local function do_OnLeave(frame)
	tooltipAnchorFrame = nil
	if GameTooltip:IsOwned(frame) then
		GameTooltip:Hide()
	end
end

local function do_OnClick(frame, button)
	if button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory("ElkExperience")
	else
		if IsControlKeyDown() then
			ElkExperience:ResetSession()
			ElkExperience:UpdateText()
			ElkExperience:UpdateTooltip()
		elseif IsShiftKeyDown() then
			local activeWindow = ChatEdit_GetActiveWindow()
			if activeWindow then
				local xpLevelMax = UnitXPMax("player")
				local text = string_format("XP: %d/%d (%.1f%%)", xpLevelCurrent, xpLevelMax, xpLevelCurrent / xpLevelMax * 100)
				local xpRested = GetXPExhaustion() or 0
				if xpRested > 0 then
					text = text..string_format(" - rested: %d (%.1f%%)", xpRested, xpRested / xpLevelMax * 100)
				end
				activeWindow:Insert(text)
			end
		else
		end
	end
end

function ElkExperience:OnInitialize()
	self.dbo = LDB:NewDataObject("ElkExperience", {
			type = "data source",
			text = "",
			icon = [[Interface\Icons\INV_Scroll_03]],
			OnEnter = do_OnEnter,
			OnLeave = do_OnLeave,
			OnClick = do_OnClick,
		})

	self.db = LibStub("AceDB-3.0"):New("ElkExperienceDB", DBdefaults, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	RequestTimePlayed();
	LDBIcon:Register("ElkExperience", self.dbo, self.db.profile.minimap)
end

function ElkExperience:OnEnable()
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("TIME_PLAYED_MSG")
	
	self:ResetSession()
	self:UpdateText()
end

function ElkExperience:RefreshConfig()
	-- minimap icon
	LDBIcon:Refresh("ElkExperience", self.db.profile.minimap)
	
	-- LDB text
	self:UpdateText()
	
	-- tooltip
	self:UpdateTooltip()
end

function ElkExperience:PLAYER_LEVEL_UP()
	xpAccumulated = xpAccumulated + UnitXPMax("player") - xpLevelInitial
	xpLevelInitial = 0
	timeLevel = time()
	
	self:UpdateText()
	self:UpdateTooltip()
end

function ElkExperience:PLAYER_XP_UPDATE()
	local xpNew = UnitXP("player")
	xpLastGain = math.max(0, xpNew - xpLevelCurrent)
	xpLevelCurrent = xpNew
	xpSession = xpLevelCurrent - xpLevelInitial + xpAccumulated
	
	self:UpdateText()
	self:UpdateTooltip()
end

function ElkExperience:TIME_PLAYED_MSG(event, arg1, arg2)
	timeTotal = time() - arg1
	timeLevel = time() - arg2
end

function ElkExperience:ResetSession()
	timeSession  = time()
	xpLastGain = 0
	xpLevelInitial = UnitXP("player")
	xpLevelCurrent = xpLevelInitial
	xpSession = 0
	xpAccumulated = 0
end

function ElkExperience:UpdateText()
	if IsXPUserDisabled() then
		self.dbo.text = "disabled"
	elseif UnitLevel("player") == MAX_PLAYER_LEVEL then
		self.dbo.text = "max"
	else
		self.dbo.text = UnitXPMax("player") - xpLevelCurrent
	end
end

function ElkExperience:UpdateTooltip()
	if not (tooltipAnchorFrame and GameTooltip:IsOwned(tooltipAnchorFrame)) then
		return
	end

	local timeAbsTotal = time() - timeTotal
	local timeAbsLevel = time() - timeLevel
	local timeAbsSession = time() - timeSession
	local xpLevelMax = UnitXPMax("player")
	local xpLevelLeft = xpLevelMax - xpLevelCurrent
	local xpRested = GetXPExhaustion() or 0
	local xpphLevel = xpLevelCurrent / timeAbsLevel * 3600
	local xpphSession = xpSession / timeAbsSession * 3600

	GameTooltip:ClearLines()
	GameTooltip:AddLine(      "|cfffed100Elk|cffffffffExperience")
	GameTooltip:AddLine(      " ")
	GameTooltip:AddDoubleLine("Total time played:",                                             SecondsToTime(timeAbsTotal, false, false, 4), 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Time this level:",                                               SecondsToTime(timeAbsLevel, false, false, 4), 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Time this session:",                                             SecondsToTime(timeAbsSession, false, false, 4), 1,1,0, 1,1,1)
	GameTooltip:AddLine(      " ")
	GameTooltip:AddDoubleLine("Level:",                                                         UnitLevel("player"), 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Total XP this level:",                                           xpLevelMax, 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Gained:",                                                        string_format("%d (%.1f%%)", xpLevelCurrent, xpLevelCurrent / xpLevelMax * 100), 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Remaining:",                                                     string_format("%d (%.1f%%)", xpLevelLeft, xpLevelLeft / xpLevelMax * 100), 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Total XP this session:",                                         xpSession, 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Rest XP:",                                                       string_format("%d (%.1f%%)", xpRested, xpRested / xpLevelMax * 100), 1,1,0, 1,1,1)
	GameTooltip:AddLine(      " ")
	GameTooltip:AddDoubleLine("XP/hour this level:",                                            string_format("%.1f", xpphLevel), 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("XP/hour this session:",                                          string_format("%.1f", xpphSession), 1,1,0, 1,1,1)
	GameTooltip:AddLine(      " ")
	GameTooltip:AddDoubleLine("Time to level for this level:",                                  xpLevelCurrent > 0 and SecondsToTime(xpLevelLeft * timeAbsLevel / xpLevelCurrent, false, false, 4) or "inf.", 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine("Time to level for this session:",                                xpSession > 0 and SecondsToTime(xpLevelLeft * timeAbsSession / xpSession, false, false, 4) or "inf.", 1,1,0, 1,1,1)
	GameTooltip:AddDoubleLine(string_format("Mobs to kill till level (at %d XP):", xpLastGain), xpLastGain > 0 and math.ceil(xpLevelLeft / xpLastGain) or "inf.", 1,1,0, 1,1,1)
	
	GameTooltip:Show()
end