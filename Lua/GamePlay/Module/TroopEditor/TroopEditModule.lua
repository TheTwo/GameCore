local BaseModule = require("BaseModule")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local ChooseHeroParamter = require("TroopPresetChooseHeroParameter")
local ChooseSoldierParamter = require("TroopPresetChooseSoldierParameter")
local ChoosePetsParamter = require("TroopPresetChoosePetParameter")
local QueuedTask = require("QueuedTask")
local EnumSoldierType = require("EnumSoldierType")
local AttackDistanceType = require("AttackDistanceType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")

---@class TroopPresetCache
---@field id number
---@field index number
---@field Heroes number[]
---@field soliderId number
---@field soliderCount number
---@field troopId number
---@field pets number[]
---@field hasChanged boolean
---@field troopStatus number @wds.TroopPresetStatus
---@field basicInfo wds.PresetTroopBasicInfo
---@field autoFill boolean

---@class TroopEditModule : BaseModule
---@field soldierCfgCache table<number,table<number,number>> @{SoldierTypeConfigCell:Id(),{SoldierConfigCell:Lv(),SoldierConfigCell:ID}}
---@field presetsCache TroopPresetCache[]
---@field presetsReadonlyCache TroopPresetCache[]
local TroopEditModule = class("TroopEditModule", BaseModule)

TroopEditModule.__cachedPetData = {}
TroopEditModule.__cachedHeroData = {}
TroopEditModule.__cachedSoldierData = {}
TroopEditModule.__savingData = false
TroopEditModule.__editUiOpen = false

function TroopEditModule:ctor()
end

function TroopEditModule:OnRegister()
    g_Game.ServiceManager:AddResponseCallback(
        ChooseHeroParamter:GetMsgId(),
        Delegate.GetOrCreate(self, self.OnPresetUpdated)
    )
    g_Game.ServiceManager:AddResponseCallback(
        ChooseSoldierParamter:GetMsgId(),
        Delegate.GetOrCreate(self, self.OnPresetUpdated)
    )
    g_Game.ServiceManager:AddResponseCallback(
        ChoosePetsParamter:GetMsgId(),
        Delegate.GetOrCreate(self, self.OnPresetUpdated)
    )
    g_Game.DatabaseManager:AddChanged(
        DBEntityPath.CastleBrief.TroopPresets.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:AddChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:AddChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetHeroCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:AddChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetPetCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:AddChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetSoldierCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
end

function TroopEditModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(
        ChooseHeroParamter:GetMsgId(),
        Delegate.GetOrCreate(self, self.OnPresetUpdated)
    )
    g_Game.ServiceManager:RemoveResponseCallback(
        ChooseSoldierParamter:GetMsgId(),
        Delegate.GetOrCreate(self, self.OnPresetUpdated)
    )
    g_Game.ServiceManager:RemoveResponseCallback(
        ChoosePetsParamter:GetMsgId(),
        Delegate.GetOrCreate(self, self.OnPresetUpdated)
    )
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.CastleBrief.TroopPresets.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetHeroCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetPetCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.CastleBrief.Castle.GlobalAttr.PresetSoldierCount.MsgPath,
        Delegate.GetOrCreate(self, self.UpdatePresetsCache)
    )
end

---@return wds.CastleBrief
function TroopEditModule:MyCastle()
    return ModuleRefer.PlayerModule:GetCastle()
end

-- function TroopEditModule:MinSoldierID()
--     return 1001 --ID of SoldierConfig.正式兵种-步兵-T1
-- end

---@class SoldierCfgCache
---@field battle table<number,table<number,number>> @{ AttackDistance,{SoldierConfigCell:Lv(),SoldierConfigCell:Id()}}
---@field engine table<number,number> @{SoldierConfigCell:Lv(),SoldierConfigCell:Id()}
---@field universal table<number,number> @{SoldierConfigCell:Id(),UniversalSoldierConfigCell:Id()}

---@return SoldierCfgCache
-- function TroopEditModule:GetSoldierConfigCache()
--     if not self.soldierCfgCache or table.nums(self.soldierCfgCache.battle) < 1 then
--         self.soldierCfgCache = {
--             battle = {},
--             engine = {},
--             universal = {}
--         }
--         local sti_battle = nil
--         local sti_engine = nil
--         for key, value in ConfigRefer.SoldierType:ipairs() do
--             if value:EnumType() == EnumSoldierType.Infantry then
--                 sti_battle = value:Id()
--             elseif value:EnumType() == EnumSoldierType.Engine then
--                 sti_engine = value:Id()
--             end
--         end
--         local minID = self:MinSoldierID()
--         for key, value in ConfigRefer.Soldier:ipairs() do
--             --过滤之前配置的临时数据
--             if value:Id() >= minID then
--                 local soldierType = value:Type()
--                 if soldierType == sti_battle then
--                     local attType = value:AttackDistance()
--                     if not self.soldierCfgCache.battle[attType] then
--                         self.soldierCfgCache.battle[attType] = {}
--                     end
--                     self.soldierCfgCache.battle[attType][value:Lv()] = value:Id()
--                 elseif soldierType == sti_engine then
--                     self.soldierCfgCache.engine[value:Lv()] = value:Id()
--                 end
--             end
--         end

--         for key, value in ConfigRefer.UniversalSoldier:ipairs() do
--             local transLen = value:TransferSoldierLength()
--             if transLen > 0 then
--                 for i = 1, transLen do
--                     local transID = value:TransferSoldier(i)
--                     self.soldierCfgCache.universal[transID] = value:Id()
--                 end
--             end
--         end
--     end
--     return self.soldierCfgCache
-- end

-- function TroopEditModule:GetBattleSoldierTypeByHero(heroIds)
--     if not heroIds or table.nums(heroIds) < 1 then
--         return -1
--     end
--     -- local heroModule = ModuleRefer.HeroModule
--     for key, id in pairs(heroIds) do
--         local heroCfg = ConfigRefer.Heroes:Find(id)
--         if heroCfg and heroCfg:AttackDistance() == AttackDistanceType.Short then
--             return AttackDistanceType.Short
--         end
--     end
--     return AttackDistanceType.Long
-- end

-- ---@return boolean,number,number @isBattle,level,AttackDistanceType
-- function TroopEditModule:GetSoldierInfo(soldierId)
--     local cfg = ConfigRefer.Soldier:Find(soldierId)
--     if cfg then
--         local typeId = cfg:Type()
--         local typeCfg = ConfigRefer.SoldierType:Find(typeId)
--         if typeCfg then
--             return typeCfg:EnumType() == EnumSoldierType.Infantry, cfg:Lv(), cfg:AttackDistance()
--         end
--     end
--     return false, 0, 0
-- end

-- ---@param preset TroopPresetCache
-- ---@return number,number @SoldierConfigCell:Id(),SoldierConfigCell:Lv()
-- function TroopEditModule:GetDefaultBattleSoldierId(preset)
--     -- 1-day版本写死
--     local conf = ConfigRefer.UniversalSoldier:Find(1)
--     if (not conf) then
--         return -1, -1
--     end

--     local battleType = self:GetBattleSoldierTypeByHero(preset.Heroes)
--     local typeIndex = 1
--     if (battleType == AttackDistanceType.Long) then
--         typeIndex = 2
--     end

--     local soldierCfg = ConfigRefer.Soldier:Find(conf:TransferSoldier(typeIndex))
--     if (not soldierCfg) then
--         return -1, -1
--     end

--     return soldierCfg:Id(), soldierCfg:Lv()
-- end

-- ---@param preset TroopPresetCache
-- ---@return number,number @SoldierConfigCell:Id(),SoldierConfigCell:Lv()
-- function TroopEditModule:GetDefaultEngineSoldierId(preset)
--     -- 1-day版本写死
--     local conf = ConfigRefer.UniversalSoldier:Find(1)
--     if (not conf) then
--         return -1, -1
--     end

--     local soldierCfg = ConfigRefer.Soldier:Find(conf:TransferSoldier(3))
--     if (not soldierCfg) then
--         return -1, -1
--     end

--     return soldierCfg:Id(), soldierCfg:Lv()
-- end

---@param preset wds.TroopPreset
---@param index number
---@param readonly boolean
---@return TroopPresetCache
function TroopEditModule.ConvertWdsPreset2CachedPreset(preset, index, readonly)
    ---@type TroopPresetCache
    local data = {
        id = preset.ID,
        index = 0,
        heroes = {},        
        soliderId = 0, --preset.SoldierID,
        soliderCount = 0, --preset.SoldierCount,
        troopId = preset.TroopId or 0,
        troopStatus = preset.Status,
        pets = {}, --preset.PetObjID,
        basicInfo = {}, --preset.BasicInfo,
        hasChanged = false,
		autoFill = preset.AutoFulfillSoldier,
    }

	if (not readonly) then

		-- 若有缓存的英雄信息由优先使用
		-- if (not TroopEditModule.__savingData and TroopEditModule.__editUiOpen and TroopEditModule.__cachedHeroData[index]) then
		-- 		--and not table.isNilOrZeroNums(TroopEditModule.__cachedHeroData[index])) then
		-- 	for key, value in pairs(TroopEditModule.__cachedHeroData[index]) do
		-- 		data.Heroes[key] = value
		-- 	end
		-- 	data.hasChanged = data.hasChanged or TroopEditModule.IsHeroDataChanged(index, preset.Heroes)
		-- else
		-- 	TroopEditModule.__cachedHeroData[index] = {}
		-- 	for key, value in pairs(preset.Heroes) do
		-- 		data.Heroes[key] = value
		-- 		TroopEditModule.__cachedHeroData[index][key] = value
		-- 	end
		-- end

		-- 若有缓存的宠物信息则优先使用
		-- if (not TroopEditModule.__savingData and TroopEditModule.__editUiOpen and TroopEditModule.__cachedPetData[index]) then
		-- 		--and not table.isNilOrZeroNums(TroopEditModule.__cachedPetData[index])) then
		-- 	for key, value in pairs(TroopEditModule.__cachedPetData[index]) do
		-- 		data.pets[key] = value
		-- 	end
		-- 	data.hasChanged = data.hasChanged or TroopEditModule.IsPetDataChanged(index, preset.PetObjID)
		-- else
		-- 	TroopEditModule.__cachedPetData[index] = {}
		-- 	for key, value in pairs(preset.PetObjID) do
		-- 		data.pets[key] = value
		-- 		TroopEditModule.__cachedPetData[index][key] = value
		-- 	end
		-- end

		-- 若有缓存的士兵信息由优先使用
		if (not TroopEditModule.__savingData and TroopEditModule.__editUiOpen and TroopEditModule.__cachedSoldierData[index]) then
				--and not table.isNilOrZeroNums(TroopEditModule.__cachedSoldierData[index])) then
			--data.soliderId = __cachedSoldierData[index].soldierId
			-- data.soliderId = preset.SoldierID
			-- data.soliderCount = TroopEditModule.__cachedSoldierData[index].soldierCount
			--g_Logger.Trace("*** 读取缓存士兵信息 %s, %s", data.soliderId, data.soliderCount)
			-- data.hasChanged = data.hasChanged or TroopEditModule.IsSoldierDataChanged(index, preset.SoldierID, preset.SoldierCount)
		else
			TroopEditModule.__cachedSoldierData[index] = {
				-- soldierId = preset.SoldierID,
				-- soldierCount = preset.SoldierCount,
			}
			-- data.soliderId = preset.SoldierID
			-- data.soliderCount = preset.SoldierCount
			--g_Logger.Trace("*** 读取更新士兵信息 %s, %s", data.soliderId, data.soliderCount)
		end

	else
		-- for key, value in pairs(preset.HeroObjID) do
		-- 	data.Heroes[key] = value
		-- end
		-- for key, value in pairs(preset.PetObjID) do
		-- 	data.pets[key] = value
		-- end
		-- data.soliderId = preset.SoldierID
		-- data.soliderCount = preset.SoldierCount
	end

	data.basicInfo.OriNum = preset.BasicInfo.OriNum
    data.basicInfo.Num = preset.BasicInfo.Num
    data.basicInfo.Slight = preset.BasicInfo.Slight
    data.basicInfo.Dead = preset.BasicInfo.Dead
    data.basicInfo.Moving = preset.BasicInfo.Moving
    data.basicInfo.Battling = preset.BasicInfo.Battling
    data.basicInfo.BackToCity = preset.BasicInfo.BackToCity
    data.basicInfo.MoveStopTime = preset.BasicInfo.MoveStopTime

    return data
end

function TroopEditModule:GetEmptyPresetCacheData()
    ---@type TroopPresetCache
    local emptyData = {}
    emptyData.id = 0
    emptyData.index = 0
    emptyData.Heroes = self:GetEmptyPresetHeroes()
    emptyData.troopId = 0
    emptyData.pets = {}
    emptyData.hasChanged = false
    emptyData.troopStatus = wds.TroopPresetStatus.TroopPresetIdle
    emptyData.autoFill = true    
    return emptyData
end

function TroopEditModule:UpdatePresetsCache()
    self.presetsCache = {}
    self.presetsReadonlyCache = {}
    local castle = self:MyCastle()
    local presets = castle.TroopPresets.Presets    
    local maxPresetCount = self:GetMaxPresetCount()
    if presets == nil or #presets < 1 then
        for i = 1, maxPresetCount do
            --Create Empty Cache
            ---@type TroopPresetCache
            local emptyData = self:GetEmptyPresetCacheData()
            emptyData.index = i
            self.presetsCache[i] = emptyData
            emptyData = self:GetEmptyPresetCacheData()
            emptyData.index = i
            self.presetsReadonlyCache[i] = emptyData
        end
    else
        local presetCount = #presets
        for i = 1, math.max(presetCount, maxPresetCount) do
			-- 清除战斗中的部队缓存
			-- local p = presets[i]
			-- if (p and p.BasicInfo.Battling) then
			-- 	TroopEditModule.__cachedHeroData[i] = {}
			-- 	TroopEditModule.__cachedPetData[i] = {}
			-- 	TroopEditModule.__cachedSoldierData[i] = {}
			-- end

            local cacheData, readonlyData
            if i <= presetCount then
                cacheData = TroopEditModule.ConvertWdsPreset2CachedPreset(presets[i], i)
                readonlyData = TroopEditModule.ConvertWdsPreset2CachedPreset(presets[i], i, true)
            else
                cacheData = self:GetEmptyPresetCacheData()
                readonlyData = self:GetEmptyPresetCacheData()
            end
            cacheData.index = i
            self.presetsCache[i] = cacheData
            readonlyData.index = i
            self.presetsReadonlyCache[i] = readonlyData
        end
    end

    -- 更新红点
    ModuleRefer.SlgModule:RefreshEntranceRedDotStatus()

    g_Game.EventManager:TriggerEvent(EventConst.SLGTROOP_PRESET_CHANGED)
end

---@return TroopPresetCache[]
function TroopEditModule:GetPresets()
    if not self.presetsCache then
        self:UpdatePresetsCache()
    end
    return self.presetsCache
end

---@return TroopPresetCache
function TroopEditModule:GetPreset(index)
    if not self.presetsCache then
        self:UpdatePresetsCache()
    end
    return self.presetsCache[index]
end

function TroopEditModule:GetReadonlyPreset(index)
	return self.presetsReadonlyCache[index]
end

---@return number,number @unlock preset count,max preset count
function TroopEditModule:GetMaxPresetCount()
    local castle = self:MyCastle()
    local unlockCount = 1
    if castle then
        unlockCount = castle.Castle.GlobalAttr.PresetCount
        if unlockCount < 1 then
            unlockCount = 3 --Test Value
        end
    end
    --TODO: 为了解决编队超过3个的问题，暂时写死
    local max = 3 -- ConfigRefer.ConstMain:TroopPresetMaxCount()
    return math.min(unlockCount, max), max
end

function TroopEditModule:GetMaxPresetHeroCount()
    local castle = self:MyCastle()
    local unlockCount = 1
    if castle then
        unlockCount = castle.Castle.GlobalAttr.PresetHeroCount
        if unlockCount < 1 then
            unlockCount = 3 --Test Value
        end
    end
    local max = ConfigRefer.ConstMain:TroopPresetMaxHeroCount()
    return math.min(unlockCount, max), max
end

-- -@param heroCount number
-- function TroopEditModule:GetMaxPresetPetCount(heroCount)
--     -- local castle = self:MyCastle()
--     -- local unlockCount = 1
--     -- if castle then
--     --     unlockCount = castle.Castle.GlobalAttr.PresetPetCount
--     --     if unlockCount < 1 then
--     --         unlockCount = 6 --Test Value
--     --     end
--     -- end
--     -- local max = ConfigRefer.ConstMain:TroopPresetMaxPetCount()
--     -- return math.min(unlockCount, max), max

-- 	-- 新方法按英雄计算, 每个英雄带2个宠物位
-- 	if (not heroCount or heroCount <= 0) then return 0 end
-- 	return heroCount * 2
-- end

function TroopEditModule:GetEmptyPresetHeroes()
    local heroCount = self:GetMaxPresetHeroCount()
    local defaultHeroes = {}
    for i = 1, heroCount do
        defaultHeroes[i] = 0
    end
    return defaultHeroes
end

-- function TroopEditModule:GetEmptyPresetPets()
--     local petCount = 0 --self:GetMaxPresetPetCount()
--     local defaultPets = {}
--     for i = 1, petCount do
--         defaultPets[i] = 0
--     end
--     return defaultPets
-- end

local SoldierCapacityBaseAttElementID = 62

-- ---@param heroIds number[]
-- function TroopEditModule:CalcMaxSoldierCount(heroIds)
--     if not heroIds then
--         return 0
--     end
--     local maxCount = 0
--     local heroModule = ModuleRefer.HeroModule
--     for index, cfgId in ipairs(heroIds) do
--         local data = heroModule:GetHeroByCfgId(cfgId)
--         if data then
--             local attr = heroModule:GetHeroBaseAttribute(cfgId, data.dbData.Level)
--             local attrItem = attr:Get(SoldierCapacityBaseAttElementID)
--             maxCount = maxCount + ((attrItem ~= nil) and attrItem.value or 0)
--         end
--     end

--     local castle = self:MyCastle()
--     if castle then
--         maxCount = maxCount + castle.Castle.GlobalAttr.PresetSoldierCount
--     end

--     return maxCount
-- end
---@param preset TroopPresetCache
---@return boolean
function TroopEditModule:IsPresetSaveable(preset)
    return (preset and preset.hasChanged)
end
---@param preset TroopPresetCache
function TroopEditModule:HasHero(preset)
    local hasHero = false
    if preset.Heroes then
        for key, value in pairs(preset.Heroes) do
            if value and value > 0 then
                hasHero = true
                break
            end
        end
    end
    return hasHero
end

---@param index number @Start from 1
---@param heroIds number[] @heroIds[1] is Leader and must not nil
function TroopEditModule:SetupTroopPresetHeros(index, heroIds, lockable, callBack)
    local param = ChooseHeroParamter.new()
    param.args.QueueIdx = math.max(0, index - 1)
    param.args.HeroIds:AddRange(heroIds)
    param:Send(lockable, {onResponse = callBack})
end

-- ---@param index number @Start from 1
-- ---@param soldierId number @SoldierConfigCell:Id()
-- ---@param count number @Soldier Count
-- function TroopEditModule:SetupTroopPresetSoldiers(index, soldierId, count, lockable, callBack)
--     local param = ChooseSoldierParamter.new()
--     param.args.QueueIdx = math.max(0, index - 1)
--     param.args.SoldierID = soldierId
--     param.args.SoldierNum = count
--     param:Send(lockable, {onResponse = callBack})
-- end

function TroopEditModule:SetupTroopPresetPets(index, pets, lockable, callBack)
    ---@field public QueueIdx number
    ---@field public PetIds number[] | RepeatedField
    local param = ChoosePetsParamter.new()
    param.args.QueueIdx = math.max(0, index - 1)
    if pets and #pets > 0 then
        param.args.PetIds:AddRange(pets)
    end
    param:Send(lockable, {onResponse = callBack})
end

function TroopEditModule:OnPresetUpdated(result, rsp, data)
    if result then
        if data.userdata.onResponse then
            pcall(data.userdata.onResponse)
        end
    end
end

-- ---@param presetData TroopPresetCache
-- function TroopEditModule:ApplyPreset(presetData, lockable, callBack)
--     if not presetData or not presetData.hasChanged or presetData.index < 1 then
--         return
--     end

--     local readonlyData = self.presetsReadonlyCache[presetData.index]
--     if (not readonlyData) then
--         g_Logger.Error("错误: 编队缓存数据不一致! index: %s", presetData.index)
--         return
--     end

--     local saveData = function()
-- 		ModuleRefer.TroopEditModule.SetSavingData(true)
-- 		ModuleRefer.TroopEditModule.ClearAllCachedPetData()
-- 		ModuleRefer.TroopEditModule.ClearAllCachedHeroData()
-- 		ModuleRefer.TroopEditModule.ClearAllCachedSoldierData()

-- 		local taskSequence = QueuedTask.new()

--         taskSequence:WaitResponse(
--             ChooseHeroParamter.GetMsgId(),
--             5,
--             function()
--                 self:SetupTroopPresetHeros(presetData.index, presetData.Heroes, lockable)
--             end
--         )
--         -- :WaitResponse(
--         --     ChooseSoldierParamter.GetMsgId(),
--         --     5,
--         --     function()
--         --         self:SetupTroopPresetSoldiers(presetData.index, presetData.soliderId, presetData.soliderCount, lockable)
--         --     end
--         -- )

--         taskSequence:WaitResponse(
--             ChoosePetsParamter.GetMsgId(),
--             5,
--             function()
--                 self:SetupTroopPresetPets(presetData.index, presetData.pets, lockable)
--             end
--         )

--         taskSequence:DoAction(
--             function()
-- 				ModuleRefer.TroopEditModule.SetSavingData(false)
--                 if callBack then
--                     callBack()
--                 end
--             end
--         ):Start()
--     end

--     local checkHero = function()
--         if not self:HasHero(presetData) then
--             ---@type CommonConfirmPopupMediatorParameter
--             local dialogParam = {}
--             dialogParam.styleBitMask =
--                 CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
--             dialogParam.title = I18N.Get("citizen_check_in_hint_title")
--             local content = I18N.GetWithParams("formation-deleteformation")
--             dialogParam.content = I18N.Get(content)
--             dialogParam.onConfirm = function(context)
--                 presetData.pets = {}
--                 -- presetData.soliderId = 0
--                 -- presetData.soliderCount = 0
-- 				saveData()
--                 return true
--             end
--             dialogParam.onCancel = function(context)
--                 return true
--             end
--             g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam, nil, true)
--         else
--             saveData()
--         end
--     end

--     -- 兵量冗余检查
--     -- local reducedSoldierCount = (readonlyData.soliderCount or 0) - (presetData.soliderCount or 0)
--     -- if (reducedSoldierCount > 0) then
--     --     local castle = ModuleRefer.PlayerModule:GetCastle()
--     --     local remainCapacity = castle.Castle.CastleMilitia.Capacity - castle.Castle.CastleMilitia.Count
--     --     local delta = reducedSoldierCount - remainCapacity
--     --     if (delta > 0) then
--     --         ---@type CommonConfirmPopupMediatorParameter
--     --         local dialogParam = {}
--     --         dialogParam.styleBitMask =
--     --             CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
--     --         dialogParam.title = I18N.Get("formation_loseremindTitle")
--     --         local content = I18N.GetWithParams("formation_loseremind", delta)
--     --         dialogParam.content = I18N.Get(content)
--     --         dialogParam.onConfirm = function(context)
-- 	-- 			checkHero()
--     --             return true
--     --         end
--     --         dialogParam.onCancel = function(context)
--     --             return true
--     --         end
--     --         g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam, nil, true)
-- 	-- 	else
-- 	-- 		checkHero()
--     --     end
-- 	-- else
-- 		checkHero()
--     -- end
-- end

-- ---@param presetData TroopPresetCache
-- function TroopEditModule:CallBackToCity(presetData)
--     if not presetData or presetData.troopId < 1 then
--         return
--     end
--     ModuleRefer.SlgModule:ReturnToHome(presetData.troopId)
-- end

-- ---@param presetData TroopPresetCache
-- ---@param targetTile MapRetrieveResult
-- ---@param purpose wrpc.MovePurpose
-- function TroopEditModule:MoveToTile(presetData, targetTile, purpose)
--     if not presetData then
--         return
--     end

--     local troopCtrl = nil
--     if presetData.troopId > 0 then
--         local troopData = ModuleRefer.SlgModule:FindTroop(presetData.troopId)
--         if not ModuleRefer.SlgModule:IsMyTroop(troopData) then
--             return
--         end
--         troopCtrl = ModuleRefer.SlgModule:GetTroopCtrl(presetData.troopId)
--     end
--     if targetTile.entity then
--         ModuleRefer.SlgModule:MoveTroopToEntity(troopCtrl, presetData.index, targetTile.entity.ID, purpose)
--     else
--         local coord = CS.DragonReborn.Vector2Short(targetTile.X, targetTile.Z)
--         ModuleRefer.SlgModule:MoveTroopToCoord(troopCtrl, presetData.index, coord, purpose)
--     end
-- end

-- ---@param purpose wrpc.MovePurpose
-- function TroopEditModule:MoveToEntity(presetData, entityId, purpose)
--     if not presetData or not entityId or entityId < 1 then
--         return
--     end
--     local troopCtrl = nil
--     if presetData.troopId > 0 then
--         local troopData = ModuleRefer.SlgModule:FindTroop(presetData.troopId)
--         if not ModuleRefer.SlgModule:IsMyTroop(troopData) then
--             return
--         end
--         troopCtrl = ModuleRefer.SlgModule:GetTroopCtrl(presetData.troopId)
--     end
--     ModuleRefer.SlgModule:MoveTroopToEntity(troopCtrl, presetData.index, entityId, purpose)
-- end

TroopEditModule.TroopState = {
    Null = 0,
    View = 1, -- 信息展示
    Editable = 2, -- 可编辑
    BattleField = 3, -- 出征, 可编辑宠物
    NotEditable = 4, -- 不可编辑
    AddHeroOnly = 5 -- 只能上阵英雄
}

-- ---@param preset TroopPresetCache
-- ---@return number
-- function TroopEditModule:GetTroopState(preset)
--     if not preset then
--         return TroopEditModule.TroopState.Null
--     end

--     if preset.index < 1 then
--         return TroopEditModule.TroopState.View
--     end

--     local hasTroop = preset.troopId > 0

--     local troopStaus = preset.troopStatus
--     if
--         (troopStaus == wds.TroopPresetStatus.TroopPresetIdle or troopStaus == wds.TroopPresetStatus.TroopPresetInSignUp or
--             troopStaus == wds.TroopPresetStatus.TroopPresetInHome)
--      then
--         if (troopStaus == wds.TroopPresetStatus.TroopPresetInHome and hasTroop) then
--             -- local myTroops = ModuleRefer.SlgModule:GetMyTroops()
--             -- ---@type TroopInfo
--             -- local troop = myTroops[preset.troopId]
--             -- if (troop and troop.entityData and troop.entityData.MapStates.Battling) then
--             --     return TroopEditModule.TroopState.NotEditable
--             -- else
--             --     return TroopEditModule.TroopState.AddHeroOnly
--             -- end
-- 			return TroopEditModule.TroopState.BattleField	-- 内城野外也不让上英雄了
--         else
--             return TroopEditModule.TroopState.Editable
--         end
--     elseif hasTroop and troopStaus == wds.TroopPresetStatus.TroopPresetInBigWorld then
--         return TroopEditModule.TroopState.BattleField
--     end

--     return TroopEditModule.TroopState.NotEditable
-- end

-- ---@param presetCacheData TroopPresetCache
-- ---@return wds.MapEntityState
-- function TroopEditModule:GetTroopMapState(presetCacheData)
--     if not presetCacheData then
--         return nil
--     end
--     if presetCacheData.index < 1 then
--         return nil
--     end
--     local troopId = presetCacheData.troopId
--     if not troopId or troopId < 1 then
--         --Troop is in city
--         return nil
--     end
--     local troop = ModuleRefer.SlgModule:FindTroop(troopId)
--     if troop then
--         return troop.MapStates
--     end
--     return nil
-- end

-- local HeroUnitType = require("HeroUnitType")
-- local SoldierType = require("EnumSoldierType")
-- ---@param type number @HeroUnitType
-- ---@return number @SoldierTypeConfigCell:Id()
-- function TroopEditModule:HeroUnitType2SoldierTypeConfigId(type)
--     --没有骑兵，所以原来的骑兵对应到步兵
--     -- local soldierEnumType
--     -- if type == HeroUnitType.Archer then
--     --     soldierEnumType = SoldierType.Archer
--     -- else
--     --     soldierEnumType = SoldierType.Infantry
--     -- end

--     -- return self:GetSoldierTypeId(soldierEnumType)
-- end
-- ---@param soldierId number @SoldierConfigCell:Id()
-- ---@return boolean
-- function TroopEditModule:IsSoldierUnlocked(soldierId)
--     return true
-- end
-- ---@param typeId number @EnumSoldierType
-- function TroopEditModule:MaxUnlockLv(typeId)
--     -- 1-day 版本只有T1
--     return 1
--     --return 3
-- end

-- ---@param preset TroopPresetCache
-- ---@return boolean @has fixed
-- function TroopEditModule:CheckAndFixPreset(preset)
--     if preset.Heroes == nil or #preset.Heroes < 1 or not preset.hasChanged then
--         return false
--     end

--     local hasEmpty = false
--     local needFix = false
--     for index, value in ipairs(preset.Heroes) do
--         if value < 1 then
--             hasEmpty = true
--         elseif value > 0 and hasEmpty then
--             needFix = true
--             break
--         end
--     end

--     if needFix then
--         local newHeros = {}
--         for index, value in ipairs(preset.Heroes) do
--             if value > 0 then
--                 table.insert(newHeros, value)
--             end
--         end
--         if #newHeros < #preset.Heroes then
--             for i = #newHeros + 1, #preset.Heroes do
--                 newHeros[i] = 0
--             end
--         end
--         preset.Heroes = newHeros
--     end
--     return needFix
-- end

-- ---@param index number
-- ---@param pets number[]
-- function TroopEditModule.SyncPetData(index, pets)
-- 	if (index and index > 0 and pets) then
-- 		TroopEditModule.__cachedPetData[index] = {}
-- 		Utils.CopyArray(pets, TroopEditModule.__cachedPetData[index])
-- 	end
-- end

-- function TroopEditModule.ClearAllCachedPetData()
-- 	TroopEditModule.__cachedPetData = {}
-- end

-- ---@param index number
-- ---@param heroes number[]
-- function TroopEditModule.SyncHeroData(index, heroes)
-- 	if (index and index > 0 and heroes) then
-- 		TroopEditModule.__cachedHeroData[index] = {}
-- 		Utils.CopyArray(heroes, TroopEditModule.__cachedHeroData[index])
-- 	end
-- end

-- function TroopEditModule.ClearAllCachedHeroData()
-- 	TroopEditModule.__cachedHeroData = {}
-- end

-- function TroopEditModule.SyncSoldierData(index, soldierId, soldierCount)
-- 	if (index and index > 0 and soldierId and soldierCount) then
-- 		TroopEditModule.__cachedSoldierData[index] = {
-- 			soldierId = soldierId,
-- 			soldierCount = soldierCount,
-- 		}
-- 	end
-- end

-- function TroopEditModule.ClearAllCachedSoldierData()
-- 	TroopEditModule.__cachedSoldierData = {}
-- end

-- function TroopEditModule.SetSavingData(saving)
-- 	TroopEditModule.__savingData = saving
-- end

-- function TroopEditModule.SetEditUIOpen(open)
-- 	TroopEditModule.__editUiOpen = open
-- end

-- ---@param index number
-- ---@param wdsPetData number[]
-- function TroopEditModule.IsPetDataChanged(index, wdsPetData)
-- 	if (not index or index < 1) then return false end
-- 	if (not wdsPetData) then return false end
-- 	local cachedData = TroopEditModule.__cachedPetData[index]
-- 	if (not cachedData) then return true end
-- 	return not Utils.IsArrayContentEqual(cachedData, wdsPetData)
-- end

-- ---@param index number
-- ---@param wdsHeroData number[]
-- function TroopEditModule.IsHeroDataChanged(index, wdsHeroData)
-- 	if (not index or index < 1) then return false end
-- 	if (not wdsHeroData) then return false end
-- 	local cachedData = TroopEditModule.__cachedHeroData[index]
-- 	if (not cachedData) then return true end
-- 	return not Utils.IsArrayContentEqual(cachedData, wdsHeroData)
-- end

-- function TroopEditModule.IsSoldierDataChanged(index, soldierId, soldierCount)
-- 	if (not index or index < 1) then return false end
-- 	if (not soldierId or not soldierCount) then return false end
-- 	local cachedData = TroopEditModule.__cachedSoldierData[index]
-- 	if (not cachedData) then return true end
-- 	return cachedData.soldierId ~= soldierId or cachedData.soldierCount ~= soldierCount
-- end

-- function TroopEditModule:GetAllPetsInPresets()
-- 	local result = {}
-- 	local castle = self:MyCastle(true)
-- 	if (not castle or not castle.TroopPresets or not castle.TroopPresets.Presets) then return result end

-- 	-- for _, preset in pairs(castle.TroopPresets.Presets) do
-- 	-- 	if (preset and preset.PetObjID) then
-- 	-- 		for _, petId in pairs(preset.PetObjID) do
-- 	-- 			result[petId] = true
-- 	-- 		end
-- 	-- 	end
-- 	-- end

-- 	return result
-- end

-- function TroopEditModule:GetRealtimePreset(index)
-- 	local castle = self:MyCastle(true)
-- 	if (not castle or not castle.TroopPresets or not castle.TroopPresets.Presets) then return nil end
-- 	return castle.TroopPresets.Presets[index]
-- end

-- function TroopEditModule:GetHeroTeamIndex(heroId)
--     local castle = ModuleRefer.PlayerModule:GetCastle()
--     if (not castle or not castle.TroopPresets or not castle.TroopPresets.Presets) then return nil end
--     for index, preset in ipairs(castle.TroopPresets.Presets) do
--         local heroes = preset.Heroes or {}
--         for _, info in ipairs(heroes) do
--             if info.HeroCfgID == heroId then
--                 return index
--             end
--         end
--     end
--     return nil
-- end

-- function TroopEditModule:GetAllPetTypeLinkHerosByIndex(troopIndex, petType)
--     local list = {}
--     local castle = ModuleRefer.PlayerModule:GetCastle()
--     if troopIndex then
--         local preset = castle.TroopPresets.Presets[troopIndex]
--         local heroes = preset.Heroes or {}
--         for _, info in ipairs(heroes) do
--             local linkPetId = ModuleRefer.HeroModule:GetHeroLinkPet(info.HeroCfgID)
--             if linkPetId then
--                 local pet = ModuleRefer.PetModule:GetPetByID(linkPetId)
--                 local petCfg = ModuleRefer.PetModule:GetPetCfg(pet.ConfigId)
--                 if petCfg and petCfg:PetType() == petType then
--                     list[#list + 1] = info.HeroCfgID
--                 end
--             end
--         end
--     end
--     return list
-- end

-- function TroopEditModule:GetAllPetTypeLinkHerosById(heroId, petType)
--     local troopIndex = self:GetHeroTeamIndex(heroId)
--     return self:GetAllPetTypeLinkHerosByIndex(troopIndex, petType)
-- end

return TroopEditModule
