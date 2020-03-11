
local addonName, AltMythicList = ...;

local debug = AltMythicList.config.debug

function AltMythicList:BuildMainFrame()
    local main_frame = CreateFrame("frame", "AltMythicListFrame", UIParent);

    AltMythicList.main_frame = main_frame;
	main_frame:SetFrameStrata("MEDIUM");
	main_frame.background = main_frame:CreateTexture(nil, "BACKGROUND");
	main_frame.background:SetAllPoints();
	main_frame.background:SetDrawLayer("ARTWORK", 1);
    main_frame.background:SetColorTexture(0, 0, 0, 1);

	main_frame:ClearAllPoints()
	main_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)

	main_frame:RegisterEvent("ADDON_LOADED");
    main_frame:RegisterEvent("PLAYER_LOGIN");

	-- Show Frame
    main_frame:Hide();
end

function AltMythicList:GetNormalizedCharClass(class)
    return self.classTable[class]
end

function AltMythicList:GetCharColor(class)
    local normalizedClass = self:GetNormalizedCharClass(class)

    local color = RAID_CLASS_COLORS[normalizedClass:upper()]
    if color ~= nil then
        return color
    end

    color = RAID_CLASS_COLORS[normalizedClass]
    if color ~= nil then
        return color
    end

    return {
        ["r"] = 255,
        ["g"] = 255,
        ["b"] = 255
    }
end

--[[
    Frame functions
]] --

local topPanelHeight = 30
local spacing = 5
local padding = 5

function AltMythicList:GetFontSize()
    return self.addon:GetFontSize()
end

function AltMythicList:GetInstanceWidth()
    return self.addon:GetInstanceWidth()
end

function AltMythicList:CalculateWidth()
    return (self:getDungeonCount() + 1) * self:GetInstanceWidth();
end

function AltMythicList:CalculateHeight()
    local altHeight = (self:getAltCount() + 1) * self:CalculatePlayerFrameHeight()
    return altHeight
end

function AltMythicList:CalculateYOffset(i)
    return -(i-1) * (self:CalculatePlayerFrameHeight()  + spacing - padding)
end

function AltMythicList:CalculatePlayerFrameHeight(i)
    return (self:GetFontSize() + padding * 2)
end

function AltMythicList:UpdateData(data)
    local frame = self.main_frame
    local altsContainer = frame.altsContainer

    frame:SetSize(self:CalculateWidth(), self:CalculateHeight());
    frame.background:SetAllPoints();

    for _, altContainer in pairs(altsContainer.alts) do
        local altFrame = altContainer.frame
        local alt = altContainer.alt.guid

        alt = data[alt]
        altFrame.altName:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", self:GetFontSize())
        altFrame.altName:GetFontString():SetWidth(self:GetInstanceWidth())

        if altFrame ~= nil and altFrame.dungeons ~= nil then
            for dungeonIndex, dungeonFrame in pairs(altFrame.dungeons) do
                if alt.dungeons ~= nil and alt.dungeons[dungeonIndex] ~= nil then
                    dungeonFrame:SetText(self:GetDungeonKeyLabel(alt.dungeons[dungeonIndex]))
                    dungeonFrame:SetSize(self:GetInstanceWidth(), self:GetFontSize() + padding * 2)
                    dungeonFrame:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", self:GetFontSize())
                    dungeonFrame:GetFontString():SetWidth(self:GetInstanceWidth())
                end
            end
        end
    end
end

function AltMythicList:GetTitle()
    if debug then
        return addonName .. ' / ' .. UnitGUID('player')
    end
    return addonName
end

function AltMythicList:SetupFrame()
    local frame = self.main_frame

    frame:SetSize(self:CalculateWidth(), self:CalculateHeight());
    frame.background:SetAllPoints();

	if frame.topPanel == nil then
		frame.topPanel = CreateFrame("Frame", "AltMythicListTopPanel", frame);
		frame.topPanelTex = frame.topPanel:CreateTexture(nil, "BACKGROUND");
		frame.topPanelTex:SetAllPoints();
		frame.topPanelTex:SetDrawLayer("ARTWORK", -5);
		frame.topPanelTex:SetColorTexture(0, 0, 0, 1);

		frame.topPanelString = frame.topPanel:CreateFontString("Font");
		frame.topPanelString:SetFont("Fonts\\FRIZQT__.TTF", 20)
		frame.topPanelString:SetTextColor(1, 1, 1, 1);
		frame.topPanelString:SetJustifyH("CENTER")
		frame.topPanelString:SetJustifyV("CENTER")
		frame.topPanelString:SetWidth(frame:GetWidth())
		frame.topPanelString:SetHeight(20)
		frame.topPanelString:SetText(self:GetTitle());
		frame.topPanelString:ClearAllPoints();
		frame.topPanelString:SetPoint("CENTER", frame.topPanel, "CENTER", 0, 0);
		frame.topPanelString:Show();

	end
	frame.topPanel:ClearAllPoints();
	frame.topPanel:SetSize(frame:GetWidth(), topPanelHeight);
	frame.topPanel:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);
	frame.topPanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0);

    frame:SetMovable(true)
    frame.topPanel:EnableMouse(true);
	frame.topPanel:RegisterForDrag("LeftButton");
	frame.topPanel:SetScript("OnDragStart", function(self,button)
		frame:SetMovable(true);
        frame:StartMoving();
    end);
	frame.topPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing();
		frame:SetMovable(false);
    end);

    AltMythicList:MakeBorder(frame, 5);
    local instanceContainer = self:MakeInstanceRow(frame)
    AltMythicList:MakeAltsContainer(frame, instanceContainer)

	-- Close button
	frame.closeButton = CreateFrame("Button", "CloseButton", frame.topPanel, "UIPanelCloseButton");
    frame.closeButton:SetSize(32, 32);
    frame.closeButton:ClearAllPoints()
	frame.closeButton:SetPoint("TOPRIGHT", frame.topPanel, "TOPRIGHT");
	frame.closeButton:SetScript("OnClick", function() self:HideInterface(); end);
end

function AltMythicList:MakeInstanceRow(frame)
    local instanceContainer = CreateFrame("BUTTON", nil, frame)

    instanceContainer.background = instanceContainer:CreateTexture(nil, "BACKGROUND");
    instanceContainer.background:SetAllPoints();
    instanceContainer.background:SetDrawLayer("ARTWORK", 1);
    instanceContainer.background:SetColorTexture(255, 255, 255, 0.2);

    instanceContainer:SetSize(frame:GetWidth(), self:GetFontSize() + padding * 2);
    instanceContainer:ClearAllPoints()
    instanceContainer:SetPoint("TOP", frame);

    instanceContainer:Show();

    local i = 1
    for index, dungeon in pairs(self.dungeons) do

        local dungeonFrame = CreateFrame("BUTTON", nil, instanceContainer)
        dungeonFrame:SetText(dungeon.shortName)
	    dungeonFrame:SetNormalFontObject("GameFontHighlightSmall")

        dungeonFrame:ClearAllPoints()
        dungeonFrame:SetSize(self:GetInstanceWidth(), self:GetFontSize() + padding * 2)
        dungeonFrame:SetPoint("LEFT", instanceContainer, "LEFT", (i) * self:GetInstanceWidth(), 0);

        local dungeonFrameFont = dungeonFrame:GetFontString()
        dungeonFrameFont:SetFont("Fonts\\FRIZQT__.TTF", self:GetFontSize())
        dungeonFrameFont:SetJustifyH("CENTER");
        dungeonFrameFont:SetJustifyV("CENTER");
        dungeonFrameFont:SetWidth(self:GetInstanceWidth())
        dungeonFrameFont:SetHeight(self:GetFontSize())
        i = i + 1
    end

    return instanceContainer
end

function AltMythicList:MakeDungeonFrame(dungeon, index, altFrame)
    local dungeonFrame = CreateFrame("BUTTON", nil, altFrame);
    altFrame.dungeons[dungeon.keystone_instance] = dungeonFrame
    dungeonFrame.background = dungeonFrame:CreateTexture(nil, "BACKGROUND");
    dungeonFrame.background:SetAllPoints();
    dungeonFrame.background:SetDrawLayer("ARTWORK", 1);

    if index % 2 ~= 0 then
        dungeonFrame.background:SetColorTexture(122, 122, 0, 0.1);
    else
        dungeonFrame.background:SetColorTexture(122, 0, 0, 0.1);
    end

    dungeonFrame:SetSize(self:GetInstanceWidth(), self:GetFontSize() + padding*2)
    dungeonFrame:SetText(self:GetDungeonKeyLabel(dungeon))
    dungeonFrame:SetNormalFontObject("GameFontHighlightSmall")
    dungeonFrame:ClearAllPoints()
    dungeonFrame:SetPoint("LEFT", altFrame, "LEFT", index * self:GetInstanceWidth(), 0);
    dungeonFrame:SetPushedTextOffset(0, 0);

    local instanceFont = dungeonFrame:GetFontString()
    instanceFont:SetFont("Fonts\\FRIZQT__.TTF", self:GetFontSize())
    instanceFont:SetJustifyH("CENTER");
    instanceFont:SetJustifyV("CENTER");
    instanceFont:SetWidth(self:GetInstanceWidth())
    instanceFont:SetHeight(self:GetFontSize())
    dungeonFrame:Show();

    return dungeonFrame
end

function AltMythicList:MakeAltFrame(alt, altIndex, altsContainer, previousAltFrame)

    local altFrame = CreateFrame("BUTTON", nil, altsContainer)
    altsContainer.alts[altIndex] = altsContainer.alts[altIndex] or {}
    altsContainer.alts[altIndex].frame = altFrame
    altsContainer.alts[altIndex].alt = alt

    altFrame.background = altFrame:CreateTexture(nil, "BACKGROUND");
    altFrame.background:SetAllPoints();
    altFrame.background:SetDrawLayer("ARTWORK", 1);

    if altIndex % 2 ~= 0 then
        altFrame.background:SetColorTexture(0, 0, 0, 1);
    else
        altFrame.background:SetColorTexture(255, 255, 255, 0.1);
    end

    altFrame:ClearAllPoints()
    altFrame:SetSize(self.main_frame:GetWidth(), self:CalculatePlayerFrameHeight())
    if previousAltFrame == nil then
        altFrame:SetPoint("TOPLEFT", altsContainer);
    else
        altFrame:SetPoint("TOPLEFT", previousAltFrame, "BOTTOMLEFT");
    end

    local altName = CreateFrame("BUTTON", nil, altFrame)
    altFrame.altName = altName
    altName:SetSize(self:GetInstanceWidth(), self:GetFontSize())
    altName:SetText(alt.name)
    altName:SetNormalFontObject("GameFontHighlightSmall")
    altName:ClearAllPoints()
    altName:SetPoint("LEFT", altFrame, "LEFT", 0, -padding/2);
    altName:SetPushedTextOffset(0, 0);
    local altNameFont = altName:GetFontString()
    local color = self:GetCharColor(alt.class)
    altNameFont:SetFont("Fonts\\FRIZQT__.TTF", self:GetFontSize())
    altNameFont:SetJustifyH("CENTER");
    altNameFont:SetJustifyV("CENTER");
    altNameFont:SetWidth(self:GetInstanceWidth())
    altNameFont:SetHeight(self:GetFontSize())
    altNameFont:SetTextColor(color.r, color.g, color.b, 1);
    altName:Show()


    altFrame.dungeons = altFrame.dungeons or {}
    local i = 1
    for _, d in pairs(self.dungeons) do
        if alt.dungeons ~= nil and alt.dungeons[d.keystone_instance] ~= nil then
            local dungeon = alt.dungeons[d.keystone_instance]
            dungeon.keystone_instance = d.keystone_instance
            if dungeon ~= nil then
                self:MakeDungeonFrame(dungeon, i, altFrame)
            end
        end
        i = i + 1
    end


    return altFrame;
end

function AltMythicList:MakeAltsContainer(frame, relative_to)
    local altsContainer = CreateFrame("BUTTON", nil, frame)
    frame.altsContainer = altsContainer
    altsContainer.alts = {}
    altsContainer:SetSize(frame:GetWidth(), frame:GetHeight());
    altsContainer:ClearAllPoints()
    altsContainer:SetPoint("TOP", relative_to, "BOTTOM");
    altsContainer:Show();

    local altIndex = 1
    local previousAltFrame = nil
    for _, alt in pairs(self:GetAlts()) do

        local altFrame = self:MakeAltFrame(alt, altIndex, altsContainer, previousAltFrame)

        previousAltFrame = altFrame

        altIndex = altIndex + 1
    end

end

function AltMythicList:MakeBorderPart(frame, x, y, xoff, yoff, part)
	if part == nil then
		part = frame:CreateTexture(nil);
	end
	part:SetTexture(0, 0, 0, 1);
	part:ClearAllPoints();
	part:SetPoint("TOPLEFT", frame, "TOPLEFT", xoff, yoff);
	part:SetSize(x, y);
	part:SetDrawLayer("ARTWORK", 7);
	return part;
end

function AltMythicList:MakeBorder(frame, size)
	if size == 0 then
		return;
	end
	frame.borderTop = self:MakeBorderPart(frame, frame:GetWidth(), size, 0, 0, frame.borderTop); -- top
	frame.borderLeft = self:MakeBorderPart(frame, size, frame:GetHeight(), 0, 0, frame.borderLeft); -- left
	frame.borderBottom = self:MakeBorderPart(frame, frame:GetWidth(), size, 0, -frame:GetHeight() + size, frame.borderBottom); -- bottom
	frame.borderRight = self:MakeBorderPart(frame, size, frame:GetHeight(), frame:GetWidth() - size, 0, frame.borderRight); -- right
end

