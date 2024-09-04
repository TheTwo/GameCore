local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require('I18N')

local SEClimbTowerStarRewardState = require('SEClimbTowerStarRewardState')
local SEClimbTowerDailyRewardState = require('SEClimbTowerDailyRewardState')
local MAX_HEIGHT = 800

---@class SEClimbTowerModule : BaseModule
local SEClimbTowerModule = class('SEClimbTowerModule', BaseModule)

local ATTR_DISP_POWER = 100

function SEClimbTowerModule:OnRegister()
    self._troopUnlockCondition = {}
	self:InitTroopUnlockCondition()
end

function SEClimbTowerModule:OnRemove()
    -- 重载此函数
end

function SEClimbTowerModule:InitTroopUnlockCondition()
	for _, section in ConfigRefer.ClimbTowerSection:ipairs() do
		if (section:OpenPresetIndex() > 1) then
			self._troopUnlockCondition[section:OpenPresetIndex()] = section:Id()
		end
	end
end

function SEClimbTowerModule:GetTroopUnlockSection(index)
	return self._troopUnlockCondition[index]
end

function SEClimbTowerModule:IsChapterUnlock(chapterId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local unlock = player.PlayerWrapper2.ClimbTower.ChapterUnlock[chapterId]
    return unlock or false
end

function SEClimbTowerModule:GetChaperStars(chapterId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local achievedStars = player.PlayerWrapper2.ClimbTower.ChapterStarNum[chapterId] or 0
    
    local allSections = self:GetAllSectionsInChapter(chapterId)
    local totalStars = #allSections * 3

    return achievedStars, totalStars
end

---@param chapterId number 章节配置id
---@param section number 关卡序号（从1开始）
---@return cell ClimbTowerSectionConfigCell
function SEClimbTowerModule:GetSectionConfigCell(chapterId, section)
    for _, v in ConfigRefer.ClimbTowerSection:ipairs() do
        if v:ChapterId() == chapterId and v:Section() == section then
            return v
        end
    end

    g_Logger.Error('没找到章节%s关卡%s对应的配置', chapterId, section)
end

---@param chapterId number 章节配置id
---@param section number 关卡序号（从1开始）
function SEClimbTowerModule:GetSectionStars(chapterId, section)
    ---@type ClimbTowerSectionConfigCell
    local sectionConfigCell = self:GetSectionConfigCell(chapterId, section)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local achievedStars = player.PlayerWrapper2.ClimbTower.SectionId2StarNum[sectionConfigCell:Id()]
    if not achievedStars then
        return 0, 3
    end

    return achievedStars, 3
end

---@param chapterId number 章节配置id
---@param section number 关卡序号（从1开始）
function SEClimbTowerModule:IsSectionUnlock(chapterId, section)
    -- 新章节解锁，第一关一定是解锁的
    if section == 1 and self:IsChapterUnlock(chapterId) then
        return true
    end

    -- 前一关卡通关了，下一关解锁
    local previousSectionStars, _ = self:GetSectionStars(chapterId, section - 1)
    return previousSectionStars > 0
end

---@param sectionConfigCellId number
function SEClimbTowerModule:IsSectionHasStars(sectionConfigCellId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local starNum = player.PlayerWrapper2.ClimbTower.SectionId2StarNum[sectionConfigCellId] or 0
    return starNum > 0
end

---@param sectionConfigCellId number
function SEClimbTowerModule:IsSectionComplete(sectionConfigCellId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local starNum = player.PlayerWrapper2.ClimbTower.SectionId2StarNum[sectionConfigCellId] or 0
    return starNum == 3
end

---@param chapterId number 章节配置id
---@param section number 关卡序号（从1开始）
---@param index number 星级索引（从1开始）
---@return StarUnlockEvent
function SEClimbTowerModule:GetSectionStarEventStruct(chapterId, section, index)
    ---@type ClimbTowerSectionConfigCell
    local sectionConfigCell = self:GetSectionConfigCell(chapterId, section)
    return sectionConfigCell:StarEvent(index)
end

---@param sectionConfigCellId number
---@param index number 星级索引（从1开始）
---@return boolean
function SEClimbTowerModule:IsSectionStarAchieved(sectionConfigCellId, index)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local starMask = player.PlayerWrapper2.ClimbTower.SectionId2StarMask[sectionConfigCellId]
    if not starMask or not starMask.GetStar then
        return false
    end

    local serverIndex = index - 1
    local isAchieved = starMask.GetStar[serverIndex] or false
    return isAchieved
end

function SEClimbTowerModule:GetAllSectionsInChapter(chapterId)
    local list = {}
    for _, cell in ConfigRefer.ClimbTowerSection:ipairs() do
        if cell:ChapterId() == chapterId then
            table.insert(list, cell)
        end
    end
    return list
end

---@param chapterId number 章节配置id
---@param index number 宝箱序号（从1开始）
---@return state SEClimbTowerStarRewardState
function SEClimbTowerModule:GetStarRewardBoxState(chapterId, index)
    local achievedStarNum, _ = self:GetChaperStars(chapterId)
    local starRewardConfigCell = self:GetStarRewardConfigCell(chapterId, index)
    local needStarNum = starRewardConfigCell:StarNum()
    if achievedStarNum < needStarNum then
        return SEClimbTowerStarRewardState.NotReach
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    local chapterRewardHistory = player.PlayerWrapper2.ClimbTower.ChapterAllStarNumRewardHistorys[chapterId]
    if not chapterRewardHistory then
        return SEClimbTowerStarRewardState.CanCliam
    end

    local hasCliamed = false
    for i, v in ipairs(chapterRewardHistory.Index) do
        local claimedIndex = v + 1
        if index == claimedIndex then
            hasCliamed = true
        end
    end

    if hasCliamed then
        return SEClimbTowerStarRewardState.HasCliamed
    end
        
    return SEClimbTowerStarRewardState.CanCliam
end

---@param chapterId number 章节配置id
---@param index number 宝箱序号（从1开始）
---@return cell ClimbTowerChapterStarRewardConfigCell
function SEClimbTowerModule:GetStarRewardConfigCell(chapterId, index)
    local chapterConfigCell = ConfigRefer.ClimbTowerChapter:Find(chapterId)
    local starRewardId = chapterConfigCell:StartReward(index)
    local cell = ConfigRefer.ClimbTowerChapterStarReward:Find(starRewardId)
    return cell
end

---@param title string 标题
---@param itemGroupId id ItemGroup配置Id
---@param trans CS.UnityEngine.Transform
function SEClimbTowerModule:ShowRewardTips(title, itemGroupId, trans)
    local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
    local rewardLists = {{titleText = I18N.Get(title)}}
    for _, item in ipairs(items) do
        rewardLists[#rewardLists + 1] = {itemId = item.configCell:Id(), itemCount = item.count}
    end
    local giftTipsParam = 
    {
        listInfo = rewardLists, 
        clickTrans = trans
    }
    g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, giftTipsParam)
end

---@param starEvent StarUnlockEvent
function SEClimbTowerModule:GetStartEventDesc(starEvent)
    local param = starEvent:DesPrm()
    if string.IsNullOrEmpty(param) then
        return I18N.Get(starEvent:Des())
    end

    return I18N.GetWithParams(starEvent:Des(), param)
end

---@param self SEClimbTowerModule
function SEClimbTowerModule:GetUsableHeroListInAllTeams()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	local list = {}
	for _, preset in ipairs(player.PlayerWrapper2.ClimbTower.Presets) do
		for _, heroInfo in ipairs(preset.Heros) do
			if (heroInfo.Info.ConfigId > 0 and heroInfo.Info.CurHpPrecent > 0) then
				list[#list + 1] = heroInfo.Info.ConfigId
			end
		end
	end
	return list
end

--- 获取爬塔编队战力
---@param self SEClimbTowerModule
---@return number
function SEClimbTowerModule:GetTroopPower()
	local player = ModuleRefer.PlayerModule:GetPlayer()
	local preset = player.PlayerWrapper2.ClimbTower.Presets[1]
	if (not preset) then return 0 end
	local power = 0
	for _, heroInfo in ipairs(preset.Heros) do
		local heroId = heroInfo.Info.ConfigId
		local petId = heroInfo.Info.PetInfos and heroInfo.Info.PetInfos[0] and heroInfo.Info.PetInfos[0].CompId or 0
		if (heroId and heroId > 0) then
			power = power + ModuleRefer.HeroModule:GetHeroAttrDisplayValue(heroId, ATTR_DISP_POWER)
		end
		if (petId and petId > 0) then
			power = power + ModuleRefer.PetModule:GetPetAttrDisplayValue(petId, ATTR_DISP_POWER)
		end
	end
	return power
end

---@return SEClimbTowerDailyRewardState
function SEClimbTowerModule:GetDailyRewardState()
    -- SystemEntry没解锁的时候不显示
    local dailyRewardSysEntryId = ConfigRefer.ClimbTowerConst:DailyRewardSystemID()
    local isDailyRewardUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(dailyRewardSysEntryId)
    if not isDailyRewardUnlock then
        return SEClimbTowerDailyRewardState.Hide
    end

    -- 取不到配置的时候不显示
    local rewardItemGroup = self:GetDailyRewardItemGroup()
    if not rewardItemGroup then
        return SEClimbTowerDailyRewardState.Hide
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if player.PlayerWrapper2.ClimbTower.IsDailyReward then
        return SEClimbTowerDailyRewardState.HasCliamed
    end

    return SEClimbTowerDailyRewardState.CanCliam
end

---@return number
function SEClimbTowerModule:GetDailyRewardItemGroup()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curSectionId = player.PlayerWrapper2.ClimbTower.CurSectionId
    local sectionConfigCell = ConfigRefer.ClimbTowerSection:Find(curSectionId)
    if sectionConfigCell then
        return sectionConfigCell:DailyReward()
    end

    -- 取不到则不显示
    return nil
end

return SEClimbTowerModule
