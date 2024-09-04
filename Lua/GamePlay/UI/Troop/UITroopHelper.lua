local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local DoNotShowAgainHelper = require("DoNotShowAgainHelper")
local GuideUtils = require("GuideUtils")
local HUDTroopUtils = require("HUDTroopUtils")
local TimerUtility = require("TimerUtility")
local NumberFormatter = require("NumberFormatter")
local FormationUtility = require("FormationUtility")

---@class UITroopHelper
local UITroopHelper = class('UITroopHelper')

local ATTR_DISP_POWER = 100
local ATTR_DISP_SPEED = 39
local ATTR_DISP_SIEGE = 56

local MAX_HERO_COUNT = 3

---@param heroList number[] @HeroConfigId
---@return number, string @power, name
function UITroopHelper.CalcTroopPower(heroList,petList, isPVP)
	if heroList == nil then return 0, string.Empty end

    local power = 0
	local dispConf = ConfigRefer.AttrDisplay:Find(ATTR_DISP_POWER)
	for i = 1, MAX_HERO_COUNT do
		local heroId = heroList[i]
		if (heroId and heroId > 0) then
			power = power + ModuleRefer.HeroModule:GetHeroAttrDisplayValue(heroId, ATTR_DISP_POWER)
			if petList then
				local petId = petList[i]
				if (petId and petId > 0) then
					power = power + ModuleRefer.PetModule:GetPetAttrDisplayValue(petId, ATTR_DISP_POWER)
				end
			else
				local petId = ModuleRefer.HeroModule:GetHeroLinkPet(heroId, isPVP)
				if (petId and petId > 0) then
					power = power + ModuleRefer.PetModule:GetPetAttrDisplayValue(petId, ATTR_DISP_POWER)
				end
			end
		end
	end

	return power, I18N.Get(dispConf:DisplayAttr())
end

---@param preset wds.TroopPreset
function UITroopHelper.GetPresetHerosAndPets(preset)
	local heroList = {}
	local petList = {}

    local maxIndex = FormationUtility.GetMaxIndex(preset.Heroes)
	for i = 1, maxIndex do
		local hero = preset.Heroes[i]
		if hero then
			heroList[i] = hero.HeroCfgID

			if hero.PetCompId > 0 then
				petList[i] = hero.PetCompId
			end
		end
	end

	return heroList, petList
end

---@param heroList number[] @HeroConfigId
---@return number, string @speed, name
function UITroopHelper.CalcTroopSpeed(heroList)
    local speed = 0
	local dispConf = ConfigRefer.AttrDisplay:Find(ATTR_DISP_SPEED)
	for i = 1, MAX_HERO_COUNT do
		local heroId = heroList[i]
		if (heroId > 0) then
			local value = ModuleRefer.HeroModule:GetHeroAttrDisplayValue(heroId, ATTR_DISP_SPEED)
			if (value > speed) then
				speed = value
			end
		end
	end
	return speed, I18N.Get(dispConf:DisplayAttr())
end

---@param heroList number[] @HeroConfigId
---@return number, string @Siege, name
function UITroopHelper.CalcTroopSiege(heroList)
    local siege = 0
	local dispConf = ConfigRefer.AttrDisplay:Find(ATTR_DISP_SIEGE)
	for i = 1, MAX_HERO_COUNT do
		local heroId = heroList[i]
		if (heroId > 0) then
			siege = siege + ModuleRefer.HeroModule:GetHeroAttrDisplayValue(heroId, ATTR_DISP_SIEGE)
			local petId = ModuleRefer.HeroModule:GetHeroLinkPet(heroId)
			if (petId and petId > 0) then
				siege = siege + ModuleRefer.PetModule:GetPetAttrDisplayValue(petId, ATTR_DISP_SIEGE)
			end
		end
	end
	return siege, I18N.Get(dispConf:DisplayAttr())
end

---@param heroIds number[] @HeroConfigId
function UITroopHelper.SortHeroList(heroIds)
	if not heroIds or #heroIds == 0 then return nil end

	local heroList2 = {}
	for i = 1, #heroIds do
		local heroId = heroIds[i]
		if (heroId and heroId > 0) then
			local heroCfg = ConfigRefer.Heroes:Find(heroId)
			if heroCfg then
				table.insert(heroList2, {
					id = heroId,
					order = heroCfg:FormationOrder()
				})
			end
		end
	end
	table.sort(heroList2, function(a, b)
		return a.order < b.order
	end)
	local heroList3 = {}
	for i = 1, #heroList2 do
		heroList3[i] = heroList2[i].id
	end

	return heroList3
end

---@return string
function UITroopHelper.GetTiesStrByTiesId(id)
	local tiesCfg = ConfigRefer.TagTies:Find(id)
    local attrGroup = ConfigRefer.AttrGroup:Find(tiesCfg:TiesAddons(1))
	local values = {}
	local keys = {}
    for i = 1, attrGroup:AttrListLength() do
        local attrId = attrGroup:AttrList(i):TypeId()
        local value = attrGroup:AttrList(i):Value() / 10000
        values[attrId] = value
		table.insert(keys, attrId)
    end
	local valueStr = NumberFormatter.Percent(values[keys[1]])
    return I18N.GetWithParams(tiesCfg:Value(), valueStr .. "%")
end

function UITroopHelper.GetTiesValueByTiesId(id)
	local tiesCfg = ConfigRefer.TagTies:Find(id)
	local attrGroup = ConfigRefer.AttrGroup:Find(tiesCfg:TiesAddons(1))
	local values = {}
	local keys = {}
	for i = 1, attrGroup:AttrListLength() do
		local attrId = attrGroup:AttrList(i):TypeId()
		local value = attrGroup:AttrList(i):Value() / 10000
		values[attrId] = value
		table.insert(keys, attrId)
	end
	return values[keys[1]]
end

function UITroopHelper.PopupRecoveryHpConfirm(index, value, withBag, clickTrans)
	value = math.floor(value)
	---@type CommonConfirmPopupMediatorParameter
	local data = {}
	data.title = I18N.Get("pet_fountain_level_up_tips_name")
	data.content = I18N.GetWithParams("popup_foodtohp_desc", value)
	data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.Toggle

	data.onConfirm = function()
		ModuleRefer.TroopModule:RecoverTroopPresetHp(index - 1, withBag, clickTrans)
		value = ("%d"):format(math.floor(value))
		ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("toast_foodtohp_01", value))
		return true
	end

	data.toggleDescribe = I18N.Get("alliance_battle_confirm2")

	data.toggleClick = function(_, check)
        if check then
            DoNotShowAgainHelper.SetDoNotShowAgain("RecoverTroopPresetHp")
            return true
        else
            DoNotShowAgainHelper.RemoveDoNotShowAgain("RecoverTroopPresetHp")
            return false
        end
    end

	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

---@param foodValue number
---@param manager TroopEditManager
function UITroopHelper.PopupFoodNotEnoughConfirm(foodValue, manager)
	---@type CommonConfirmPopupMediatorParameter
	local data = {}
	data.title = I18N.Get("pet_fountain_level_up_tips_name")
	data.content = I18N.GetWithParams("popup_gotocook", foodValue)
	data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
	data.confirmLabel = I18N.Get("btn_gotocook")
	data.onConfirm = function()
		if manager then
			TimerUtility.DelayExecute(function()
				manager:SaveTroop(function(success, allowContinue)
					if success or allowContinue then
						GuideUtils.GotoByGuide(1053)
					end
				end)
			end, 0.5)
		else
			GuideUtils.GotoByGuide(1053)
		end
		return true
	end

	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

function UITroopHelper.PopupBagNotEnoughConfirm(index, transform)
	---@type CommonConfirmPopupMediatorParameter
	local data = {}
	data.title = I18N.Get("pet_fountain_level_up_tips_name")
	data.content = I18N.Get("popup_replenish_immediately")
	data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
	data.onConfirm = function()
		if HUDTroopUtils.IsPresetInHome(index) and not HUDTroopUtils.IsPresetInHomeSe(index) then
			ModuleRefer.TroopModule:RecoverTroopPresetHp(index - 1, true, transform)
		else
			TimerUtility.DelayExecute(function()
				UITroopHelper.PopupTroopNotInHomeConfirm(index)
			end, 0.5)
		end
		return true
	end

	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

function UITroopHelper.PopupTroopNotInHomeConfirm(index, overrideContent)
	---@type CommonConfirmPopupMediatorParameter
	local data = {}
	data.title = I18N.Get("pet_fountain_level_up_tips_name")
	data.content = overrideContent or I18N.Get("popup_recall")
	data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
	data.onConfirm = function()
		ModuleRefer.TroopModule:RecallTroopPreset(index)
		return true
	end

	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

function UITroopHelper.PopupTroopInRetreatAndRecoveryFailedConfirm()
	---@type CommonConfirmPopupMediatorParameter
	local data = {}
	data.title = I18N.Get("pet_fountain_level_up_tips_name")
	data.content = I18N.Get("popup_healfailed")
	data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm
	data.onConfirm = function()
		return true
	end

	g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
end

return UITroopHelper