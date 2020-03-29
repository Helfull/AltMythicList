
local addonName, AltMythicList = ...;

_G["AltMythicList"] = AltMythicList;

local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
AltMythicList.addon = addon

function addon:OnInitialize()
    local defaults = {
        global = {
            options = {
                fontSize = 15,
                instanceWidth = 100
            }
        }
    }

    AltMythicList.db = LibStub("AceDB-3.0"):New("AltMythicListDB", defaults, true)
    AltMythicList:BuildMainFrame()

    local dungeonCount = 0
    for _, d in ipairs(AltMythicList.dungeons) do
        dungeonCount = dungeonCount + 1
    end
    AltMythicList.dungeonCount = dungeonCount

    addon:RegisterChatCommand("alts", "OnCommand")

    addon:RegisterEvent("PLAYER_LOGIN", "OnLogin")
    addon:SetupConfig()
end

function addon:OnEnable()
    AltMythicList.addon_loaded = true
    AltMythicList:RequestData()
    local isFemale = UnitSex("player") == 3
    local classTable = {}
    FillLocalizedClassList(classTable, isFemale)
    AltMythicList.classTable = table_invert(classTable)
end

function addon:OnDisable()
    -- Called when the addon is disabled
end

function addon:SetupConfig()
    local options = {
        name = 'addon',
        handler = addon,
        type = 'group',
        args = {
            fontSize = {
                type = 'range',
                name = 'Fontsize',
                desc = 'Font size for the list',
                set = 'SetFontSize',
                get = 'GetFontSize',
            },
            instanceWidth = {
                type = 'range',
                name = 'instanceWidth',
                min = 10,
                max = 1000,
                desc = 'The width of each instance column',
                set = 'SetInstanceWidth',
                get = 'GetInstanceWidth',
            }
        }
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)

    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
end

function addon:OnLogin()
    AltMythicList:GatherData()
    AltMythicList:SetupFrame()
end

function addon:OnCommand(input)
	if input == "purge" then
        AltMythicList:HideInterface();
        AltMythicList:PurgeDB();
    elseif input == "config" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        AltMythicList:ShowInterface();
    end
end

function AltMythicList:RequestData()
    C_MythicPlus.RequestCurrentAffixes();
	C_MythicPlus.RequestMapInfo();
    C_MythicPlus.RequestRewards();
    for k, d in pairs(self.dungeons) do
        C_ChallengeMode.RequestLeaders(d.keystone_instance);
    end
end

function AltMythicList:ShowInterface()
    local data = self:GatherData()
    self:UpdateData(data)
	self.main_frame:Show();
end

function AltMythicList:HideInterface()
	self.main_frame:Hide();
end

function AltMythicList:getDungeonCount()
    return self.dungeonCount or 0
end

function AltMythicList:getAltCount()
    return self:GetDB().altCount or 0
end

function AltMythicList:GatherData()

    if not self.addon_loaded then
        return
    end

    local db = self:GetDB()
    db.alts = db.alts or {}
    db.altCount = db.altCount or 0

    local altGuid = UnitGUID('player')

    if altGuid == nil then return end

    local altName = UnitName('player')

    local _, altClass = UnitClass('player');

    local player = {
        ["guid"] = altGuid,
        ["name"] = altName,
        ["class"] = altClass,
        ["dungeons"] = {}
    }

    player.dungeons = self:GatherDungeonData(player)

    if not self:CharExists(altGuid) then
        db.altCount = db.altCount + 1
        db.alts[altGuid] = player
    else
        db.alts[altGuid] = player
    end

    return db.alts
end

function AltMythicList:GetDungeonKeyLabel(dungeon)
    return dungeon.seasonBest.intime
end

function AltMythicList:IsMaxLevel()
    return UnitLevel('player') == 120
end

function AltMythicList:GatherDungeonData(player)

    if not self:IsMaxLevel() then return end

    local dungeons = player.dungeons or {}
    for _, d in ipairs(self.dungeons) do

        local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(d.keystone_instance)
        local intimeInfoSeason, overtimeInfoSeason = C_MythicPlus.GetSeasonBestForMap(d.keystone_instance)

        dungeons[d.keystone_instance] = {
            ["seasonBest"] = {
                ["intime"] = self:MakeLevelString(intimeInfoSeason, timeLimit),
                ["overtime"] = self:MakeLevelString(overtimeInfoSeason, timeLimit)
            }
        }
    end

    return dungeons
end

function AltMythicList:MakeEmptyDungeon()
    return {
        ["seasonBest"] = {
            ["intime"] = "na",
            ["overtime"] = "na"
        }
    }
end

function AltMythicList:MakeLevelString(timeInfo, timeLimit)
    if timeInfo == nil then
        return "0"
    end

    return timeInfo.level .. self:GetCompletionLevelFromTime(timeLimit, timeInfo.durationSec);
end

function AltMythicList:CharExists(charGuid)
    for k, v in pairs(self:GetAlts()) do
		if k == charGuid then
			return true;
		end
    end
    return false
end

function AltMythicList:GetCompletionLevelFromTime(maxTime, elapsedTime)

  local timeLeft = (maxTime * 0.6) - elapsedTime
  if timeLeft > 0 then
    return '+++'
  end

  local timeLeft = (maxTime * 0.8) - elapsedTime
  if timeLeft < 0 then
    return '++'
  end

  if elapsedTime < maxTime then
    return '+'
  end

  return '-'

end

--[[ Options getter and setter ]] --
function addon:SetFontSize(info, value)
    AltMythicList.db.global.options.fontSize = value
end

function addon:GetFontSize(info)
    return AltMythicList.db.global.options.fontSize
end

function addon:SetInstanceWidth(info, value)
    AltMythicList.db.global.options.instanceWidth = value
end

function addon:GetInstanceWidth(info)
    return AltMythicList.db.global.options.instanceWidth
end


-- [[ Database ]] --

function AltMythicList:GetDB()
    return self.db.global
end

function AltMythicList:GetAlts()
    return self:GetDB().alts
end

function AltMythicList:PurgeDB()
    self.db.global = {}
end


-- [[ Helper ]] --

function table_invert(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

function dump(t, offset)
    if offset == nil then offset = '' end

    if type(t) == 'table' then
        for k, v in pairs(t) do
            print(offset..k)
            dump(v, offset .. ' ')
        end
    else
        print(offset..t)
    end
end

