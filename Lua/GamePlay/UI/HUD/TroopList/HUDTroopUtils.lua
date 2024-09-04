local I18N = require("I18N")
local ObjectType = require("ObjectType")
local MailUtils = require("MailUtils")
local SlgUtils = require("SlgUtils")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityElementType = require("CityElementType")
local HeroUIUtilities = require("HeroUIUtilities")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local SlgBattlePowerHelper = require("SlgBattlePowerHelper")
local RPPType = require("RPPType")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")
local GotoUtils = require("GotoUtils")
local DBEntityType = require("DBEntityType")
local HUDTroopCondition = require("HUDTroopCondition")

---@class HUDTroopUtils
local HUDTroopUtils = {}

---@param index number
---@return boolean
function HUDTroopUtils.IsPresetInHome(index)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local preset = castle.TroopPresets.Presets[index]
    if preset then
        return preset.Status == wds.TroopPresetStatus.TroopPresetInHome or preset.Status == wds.TroopPresetStatus.TroopPresetIdle
    end
    return false --GM创建的部队，没有对应的编队数据
end

---@param index number
---@return boolean
function HUDTroopUtils.IsPresetInHomeSe(index)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    local preset = castle.TroopPresets.Presets[index]
    if preset then
        return preset.Status == wds.TroopPresetStatus.TroopPresetInHome
    end
    return false
end

---@param teamData CityExplorerTeamData
---@return boolean
function HUDTroopUtils.ShouldShowCityTeamMoveTime(teamData)
    if teamData then
        return teamData:IsInMoving() and not teamData:Battling()
    end
    return false
end

---@param teamData CityExplorerTeamData
---@return string
function HUDTroopUtils.GetCityTeamDestination(teamData)
    local targetId = teamData:GetTargetId()
    local cityElementCell = ConfigRefer.CityElementData:Find(targetId)
    if cityElementCell then
        local cfgId = cityElementCell:ElementId()
        local type = cityElementCell:Type()
        if type == CityElementType.Npc then
            local cell = ConfigRefer.CityElementNpc:Find(cfgId)
            if cell then
                return I18N.Get(cell:Name())
            end
        elseif type == CityElementType.Resource then
            local cell = ConfigRefer.CityElementResource:Find(cfgId)
            if cell then
                return I18N.Get(cell:NameKey())
            end
        elseif type == CityElementType.Spawner then
            local cell = ConfigRefer.CityElementSpawner:Find(cfgId)
            if cell then
                return I18N.Get(cell:NameForTask())
            end
        end
    end

    local preset = teamData:GetScenePlayerPreset()
    if preset then
        if preset.TargetObjectType == ObjectType.SlgExpedition then
            local cell = ConfigRefer.CityElementSpawner:Find(preset.TargetConfigId)
            if cell then
                return I18N.Get(cell:NameForTask())
            end
        end
    end
    
    return I18N.Get("team_locat_empty")
end

---@param teamData CityExplorerTeamData
---@return number
function HUDTroopUtils.GetCityTeamMoveDuration(teamData)
    if teamData then
        local hero = teamData:GetEntity()
        if hero then
            return SlgUtils.CalculateTroopMoveDuration(hero.MapBasics, hero.MovePathInfo)
        end
    end
    return 0
end

---@param troopInfo TroopInfo
---@return wds.MapEntityState | wds.PresetTroopBasicInfo
function HUDTroopUtils.GetTroopStates(troopInfo)
    local troop = troopInfo.entityData
    if troop then
        return troop.MapStates
    end

    local preset = troopInfo.preset
    if preset then
        return preset.BasicInfo
    end
end

---@param troopInfo TroopInfo
---@return boolean
function HUDTroopUtils.ShouldShowTroopMoveTime(troopInfo)
    local states = HUDTroopUtils.GetTroopStates(troopInfo)
    if states then
        return states.Moving and not states.Attacking
    end
    return false
end

---@param troopInfo TroopInfo
---@return string
function HUDTroopUtils.GetTroopMoveState(troopInfo)
    local states = HUDTroopUtils.GetTroopStates(troopInfo)
    if states then
        if states.Moving then
            if states.BackToCity then
                return I18N.Get("troop_status_5")
            else
                return I18N.Get("formation-xingjun")
            end
        end
    end
    return string.Empty
end

---@param troopInfo TroopInfo
---@return string
function HUDTroopUtils.GetTroopNonMoveState(troopInfo)
    local states = HUDTroopUtils.GetTroopStates(troopInfo)
    if states then
        if not states.Moving then
            if states.Gathering then
                return I18N.Get("team_status_collect")
            else
                return I18N.Get("team_status_stay")
            end
        end
    end
    return string.Empty
end

---@param troopInfo TroopInfo
---@return string
function HUDTroopUtils.GetTroopMoveDestination(troopInfo)
    local troop = troopInfo.entityData
    if troop then
        local mapStates = troop.MapStates
        if mapStates.BackToCity or SlgUtils.IsTroopRetreating(mapStates) then
            return I18N.Get("My_city")
        end
    end

    local preset = troopInfo.preset
    if preset then
        local targetInfo = preset.BasicInfo

        if targetInfo.TargetObjectType == 0 then
            return I18N.Get("team_locat_empty")
    	-- 怪物
        elseif targetInfo.TargetObjectType == ObjectType.SlgMob then
		    local name, _, level = MailUtils.GetMonsterNameIconLevel(targetInfo.TargetConfigId)
            return "Lv." .. level .. " " .. name
        -- 建筑
        elseif targetInfo.TargetObjectType == ObjectType.SlgVillage or 
            targetInfo.TargetObjectType == ObjectType.Pass or 
            targetInfo.TargetObjectType == ObjectType.SlgCommonBuilding or 
            targetInfo.TargetObjectType == ObjectType.SlgResource or 
            targetInfo.TargetObjectType == ObjectType.SlgEnergyTower or 
            targetInfo.TargetObjectType == ObjectType.SlgTransferTower or 
            targetInfo.TargetObjectType == ObjectType.SlgDefenceTower or 
            targetInfo.TargetObjectType == ObjectType.SlgMobileFortress or
            targetInfo.TargetObjectType == ObjectType.BehemothCage
        then
            local name, _, level = MailUtils.GetMapBuildingNameIconLevel(targetInfo.TargetConfigId)
            return "Lv." .. level .. " " .. name
        elseif targetInfo.TargetObjectType == ObjectType.SlgInteractor then
            local name = MailUtils.GetSlgInteractorNameIcon(targetInfo.TargetConfigId)
            return name
        elseif targetInfo.TargetObjectType == ObjectType.SlgCastle or
            targetInfo.TargetObjectType == ObjectType.SlgTroop or
            targetInfo.TargetObjectType == ObjectType.SlgTroopChariot
        then
            return targetInfo.TargetOwnerName
        end
    end

    return I18N.Get("team_locat_empty")
end

---@param troopInfo TroopInfo
---@return number @行军结束时间戳（单位：秒）
function HUDTroopUtils.GetTroopoMoveEndTime(troopInfo)
    local troop = troopInfo.entityData
    if SlgUtils.IsTroopInRally(troop) and SlgUtils.IsTroopInGarrison(troop) then
        troop = g_Game.DatabaseManager:GetEntity(troop.TrusteeshipInfo.TroopChariotId, DBEntityType.TroopChariot)
    end

    if troop then
        local mapBasics = troop.MapBasics
        local movePathInfo = troop.MovePathInfo
        local endTime = SlgUtils.CalculateTroopMoveStopTime(mapBasics, movePathInfo)
        return endTime
    end

    local preset = troopInfo.preset
    if preset then
        return preset.BasicInfo.MoveStopTime / 1000
    end

    return 0
end

---@param presetIndex number
---@return TroopInfo
function HUDTroopUtils.GetTroopInfo(presetIndex)
    return ModuleRefer.SlgInterfaceModule:GetTroopInfoByPresetIndex(presetIndex)
end

function HUDTroopUtils.GetTroopIdOfPreset(presetIndex)
    local troopInfo = HUDTroopUtils.GetTroopInfo(presetIndex)
    if troopInfo and troopInfo.entityData then
        return troopInfo.entityData.ID
    end
    return 0
end

---@param presetIndex number
---@return wds.TroopPreset
function HUDTroopUtils.GetPreset(presetIndex)
    local troopInfo = HUDTroopUtils.GetTroopInfo(presetIndex)
    if troopInfo then
        return troopInfo.preset
    end
    return nil
end

function HUDTroopUtils.GetMyCity()
    return ModuleRefer.CityModule.myCity
end

function HUDTroopUtils.GetCitySeManager()
    local city = HUDTroopUtils.GetMyCity()
    return city.citySeManger
end

---@return CityExplorerTeam
function HUDTroopUtils.GetExplorerTeam(presetIndex)
    local city = HUDTroopUtils.GetMyCity()
    return city.cityExplorerManager:GetTeamByPresetIndex(presetIndex - 1)
end

---@return CityExplorerTeamData
function HUDTroopUtils.GetExplorerTeamData(presetIndex)
    local team = HUDTroopUtils.GetExplorerTeam(presetIndex)
    if team then
        return team:GetTeamData()
    end
    return nil
end

---@param presetIndex number
---@return string,string,boolean
function HUDTroopUtils.GetPresetStateIcon(presetIndex)
    if HUDTroopUtils.IsPresetInHome(presetIndex) then
        local teamData = HUDTroopUtils.GetExplorerTeamData(presetIndex)
        if teamData then
            return HUDTroopUtils.CityTeamStateIcon(teamData)
        else
            return '','',false
        end
    else
        local troopInfo = HUDTroopUtils.GetTroopInfo(presetIndex)
        if troopInfo then
            if troopInfo.entityData then
                return HeroUIUtilities.TroopStateIcon(troopInfo.entityData)
            end
    
            if troopInfo.preset then
                return HeroUIUtilities.PresetStateIcon(troopInfo.preset)
            end
        end
    end
    return '','',false
end

---@param teamData CityExplorerTeamData
function HUDTroopUtils.CityTeamStateIcon(teamData)
    if not teamData then
        return '','',false
    end

    if teamData:Battling() then
        return 'sp_troop_icon_status_battle','sp_troop_img_state_base_4',true
    elseif teamData:IsInMoving() then
        return 'sp_troop_img_state_walk','sp_troop_img_state_base_1',true
    elseif teamData:Interacting() then
        return 'sp_troop_img_state_collect','sp_troop_img_state_base_2',true
    else
        return 'sp_city_icon_refugee','sp_troop_img_state_base_2',true
    end
end

function HUDTroopUtils.ShowDialog1Button(title, content, confirm, onConfirm)
    ---@type CommonConfirmPopupMediatorParameter
    local data = {}
    data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    data.title = title
    data.content = content
    data.confirmLabel = confirm
    data.onConfirm = onConfirm
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator,data, nil, true)
end

function HUDTroopUtils.ShowDialog2Buttons(title, content, confirm, cancel, onConfirm, onCancel)
    ---@type CommonConfirmPopupMediatorParameter
    local data = {}
    data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    data.title = title
    data.content = content
    data.confirmLabel = confirm
    data.cancelLabel = cancel
    data.onConfirm = onConfirm
    data.onCancel = onCancel
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator,data,nil,true)
end

---@param troopInfo TroopInfo
function HUDTroopUtils.IsTroopInRally(troopInfo)
    if troopInfo == nil then
        return false
    end

    if troopInfo.entityData then
        if SlgUtils.IsTroopInRally(troopInfo.entityData) then
            return true
        end
    end

    if troopInfo.preset then
        if troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetTeamInTrusteeship then
            return true
        end
    end

    return false
end

---@param troopInfo TroopInfo
function HUDTroopUtils.IsTroopRetreating(troopInfo)
    local mapStates = HUDTroopUtils.GetTroopStates(troopInfo)

    if SlgUtils.IsTroopRetreating(mapStates) then
        return true
    end

    return false
end

---@param troopInfo TroopInfo
function HUDTroopUtils.IsTroopGathering(troopInfo)
    if troopInfo.entityData then
        return troopInfo.entityData.MapStates.Gathering
    end

    if troopInfo.preset then
        return troopInfo.preset.BasicInfo.Gather
    end

    return false
end

---@param troopInfo TroopInfo
function HUDTroopUtils.IsTroopHasGatherReward(troopInfo)
    if troopInfo.preset then
        return troopInfo.preset.BasicInfo.GatherItems:Count() > 0
    end
    return false
end

---@param troopInfo TroopInfo
function HUDTroopUtils.HasHero(troopInfo)
    if troopInfo == nil then
        return false
    end

    return HUDTroopUtils.DoesPresetHaveAnyHero(troopInfo.preset)
end

function HUDTroopUtils.DoesPresetHaveAnyHero(preset)
    local heroId = ModuleRefer.TroopModule:GetPresetLeadHeroId(preset)
    return heroId > 0
end

function HUDTroopUtils.ComparePower(troopPower, needPower, recommendPower, catchPet)
    local compareResult = -1
    if catchPet then
        compareResult = (needPower >= recommendPower) and 1 or 2
    else
        compareResult = SlgBattlePowerHelper.ComparePower(troopPower, needPower, recommendPower)
    end
    return compareResult
end

function HUDTroopUtils.GetUnlockedPresetCount()
    local myTroops, gmTroops = ModuleRefer.SlgInterfaceModule:GetMyTroops(true)
    local count = 0
    for _, troop in pairs(myTroops) do
        if not troop.locked then
            count = count + 1
        end
    end
    return count
end

---@param listData HUDSelectTroopListData
function HUDTroopUtils.GetPowerType(listData)
    local powerType
    if listData.catchPet then
        powerType = RPPType.Pet
    elseif listData.isSE then
        powerType = RPPType.Se
    else
        powerType = RPPType.Slg
    end
    return powerType
end

---@param index number
---@param callback func
function HUDTroopUtils.DoestTroopInjuredHeroMeetStartMarchConditions(index, callback)
    local troopInfo = HUDTroopUtils.GetTroopInfo(index)
    if SlgUtils.PresetHasInjuredUnit(troopInfo.preset, ModuleRefer.SlgModule.battleMinHpPct) and
       not SlgUtils.PresetAllHeroInjured(troopInfo.preset, ModuleRefer.SlgModule.battleMinHpPct)
    then
        local title = I18N.Get("bestrongwarning_title")
        local content = I18N.Get("popup_hp0_heal_alert")
        local confirm = I18N.Get("confirm")
        local cancel = I18N.Get("cancle")
        HUDTroopUtils.ShowDialog2Buttons(title, content, confirm, cancel, function()
            if callback then
                callback()
            end
            return true
        end)
    else
        if callback then
            callback()
        end
    end
end

---@param listData HUDSelectTroopListData
---@param index number
---@param callback func
function HUDTroopUtils.DoestTroopPowerMeetStartMarchConditions(listData, index, callback)
    if listData == nil then
        return
    end

    local troopInfo = HUDTroopUtils.GetTroopInfo(index)
    local troopPower = ModuleRefer.SlgInterfaceModule:GetTroopPowerByPreset(troopInfo.preset)
    local powerType = HUDTroopUtils.GetPowerType(listData)
    local compareResult = HUDTroopUtils.ComparePower(troopPower, listData.needPower, listData.recommendPower, listData.catchPet)
    if compareResult == 2 then
        SlgBattlePowerHelper.ShowRaisePowerPopup(powerType, callback)
    else
        if callback then
            callback()
        end
    end
end

---@param index number
---@param onSucces func
function HUDTroopUtils.DoestTroopStateMeetStartMarchConditions(index, onSucces)
    local troopInfo = HUDTroopUtils.GetTroopInfo(index)

    --判断是否所有英雄都重伤
    if SlgUtils.PresetAllHeroInjured(troopInfo.preset, ModuleRefer.SlgModule.battleMinHpPct) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_hp0_march_alert'))
        return
    end

    --检查是否有英雄
    if not HUDTroopUtils.HasHero(troopInfo) then
        local destination = HUDTroopUtils.GetTroopMoveDestination(troopInfo)
        local title = I18N.Get("bestrongwarning_title")
        local content = I18N.Get("toast_team_empty", destination)
        local confirm = I18N.Get("power_goto_squad_name")
        local cancel = I18N.Get("cancle")
        HUDTroopUtils.ShowDialog2Buttons(title, content, confirm, cancel, function()
            g_Game.UIManager:Open(UIMediatorNames.UITroopMediator)
            return true
        end)
        return
    end

    --检查是否在集结中
    if HUDTroopUtils.IsTroopInRally(troopInfo) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_team_busy_02'))
        return
    end

    --检查是否在溃败中
    if HUDTroopUtils.IsTroopRetreating(troopInfo) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_team_busy_03'))
        return
    end

    --检查是否在行军中
    if HUDTroopUtils.ShouldShowTroopMoveTime(troopInfo) then
        local destination = HUDTroopUtils.GetTroopMoveDestination(troopInfo)
        local title = I18N.Get("bestrongwarning_title")
        local content = I18N.GetWithParams("popup_team_goto", destination)
        local confirm = I18N.Get("confirm")
        local cancel = I18N.Get("cancle")
        HUDTroopUtils.ShowDialog2Buttons(title, content, confirm, cancel, function()
            if onSucces then
                onSucces()
            end
            return true
        end)
        return
    end

    --检查是否在采集
    if HUDTroopUtils.IsTroopGathering(troopInfo) and HUDTroopUtils.IsTroopHasGatherReward(troopInfo) then
        ---@type GatherInterruptData
        local param = {}
        param.preset = troopInfo.preset
        param.onLeave = onSucces
        g_Game.UIManager:Open(UIMediatorNames.GatherInterruptMediator, param)
        return
    end

    if onSucces then
        onSucces()
    end
end

---@param listData HUDSelectTroopListData
---@param index number
function HUDTroopUtils.DoStartMarch(listData, index)
    if listData == nil then
        return
    end

    if listData.overrideItemClickGoFunc then
        local HUDSelectTroopList = require("HUDSelectTroopList")
        local troop = ModuleRefer.SlgInterfaceModule:GetTroopInfoByPresetIndex(index)
        local listItemData = HUDSelectTroopList.MakeHUDSelectTroopListItemData(index, troop, listData, nil)
        listData.overrideItemClickGoFunc(listItemData)
        return
    end

	local worldPetData = listData.worldPetData
    local troopInfo = HUDTroopUtils.GetTroopInfo(index)
    local selectEntity = listData.entity
    local troop = troopInfo.entityData
    local troopId = 0
    if troop then
        troopId = troop.ID;
    end

    if (selectEntity) then
        if listData.isSE then
            local fromType = ModuleRefer.SlgModule:IsInCity() and SEHudTroopMediatorDefine.FromType.City or SEHudTroopMediatorDefine.FromType.World
            local gridPos = wds.Vector3F(0,0,0)
            if listData.isPersonalInteractor then
                gridPos = selectEntity.Position
            else
                gridPos = selectEntity.MapBasics.BuildingPos
            end

            if selectEntity.TypeHash == wds.PlayerMapCreep.TypeHash then
                ModuleRefer.SEPreModule:PrepareEnv(true, troopId, true, true,
                fromType)
                GotoUtils.GotoSceneClearCreepTumor(listData.tid,troopId,selectEntity.ID,index)
            elseif selectEntity.TypeHash == wds.SeEnter.TypeHash then
                ModuleRefer.SEPreModule:PrepareEnv(true, troopId, true, true,
                fromType, math.floor(gridPos.X), math.floor(gridPos.Y))
                GotoUtils.GotoScenePersonalInteractor(listData.tid,troopId,selectEntity.ID,index)
            else
                ModuleRefer.SEPreModule:PrepareEnv(true, troopId, true, true,
                fromType, gridPos.X, gridPos.Y)
                GotoUtils.GotoSceneByInteractor(listData.tid,troopId,listData.interactorId,index)
            end
        else
            if not HUDTroopCondition.CheckBehemothCage(troop, selectEntity) then
                return
            end

            local entityPos = selectEntity.MapBasics.Position
            if listData.moveToPos then
                local coord = listData.moveToPos
                if type(coord) == 'function' then
                    coord = coord()
                end
                ModuleRefer.SlgModule:MoveTroopToCoordViaData(troop, index, coord, listData.purpose)
            else
                ModuleRefer.SlgModule:MoveTroopToEntityViaData(troop, index, selectEntity.ID, listData.purpose, entityPos.X, entityPos.Y)
            end
        end
    elseif worldPetData and listData.catchPet then
        local gridPos = worldPetData.gridPos
        local fromType = SEHudTroopMediatorDefine.FromType.World
        if ModuleRefer.PetModule:CheckIsFullPet() then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_amout_limit"))
            return
        end

        ModuleRefer.SEPreModule:PrepareEnv(true, troopId, true, true,fromType, gridPos.X, gridPos.Y)
        GotoUtils.GotoScenePetCatch(listData.tid,troopId,worldPetData.uniqueName,0,0,index)
    elseif listData.tile then
        local coord = CS.DragonReborn.Vector2Short(listData.tile.X, listData.tile.Z)
        ModuleRefer.SlgModule:MoveTroopToCoordViaData(troop,index,coord,listData.purpose)
    elseif listData.isSE and listData.isPersonalInteractor then
        local fromType = ModuleRefer.SlgModule:IsInCity()
            and SEHudTroopMediatorDefine.FromType.City
            or SEHudTroopMediatorDefine.FromType.World
        ---@type wds.SeEnter
        local seEnterData = selectEntity
        local gridPos = seEnterData.Position

        if seEnterData.TypeHash == wds.SeEnter.TypeHash then
            ModuleRefer.SEPreModule:PrepareEnv(true, troopId, true, true,
            fromType, gridPos.X, gridPos.Y)
            GotoUtils.GotoScenePersonalInteractor(listData.tid,troopId,listData.interactorId,index)
        end
    else
        g_Logger.ErrorChannel('HUDSelectTroopListItem','unknown Goto target')
    end

    g_Game.UIManager:CloseByName(UIMediatorNames.HUDSelectTroopList)
end

---@param listData HUDSelectTroopListData
---@param index number
function HUDTroopUtils.StartSingleMarch(listData, index)
    HUDTroopUtils.DoestTroopInjuredHeroMeetStartMarchConditions(index, function()
        HUDTroopUtils.DoestTroopPowerMeetStartMarchConditions(listData, index, function()
            HUDTroopUtils.DoestTroopStateMeetStartMarchConditions(index, function()
                HUDTroopUtils.DoStartMarch(listData, index)
            end)
        end)
    end)
end

---@param listData HUDSelectTroopListData
function HUDTroopUtils.StartMarch(listData)
    local count = HUDTroopUtils.GetUnlockedPresetCount()
    if not listData.isAssemble and count == 1 then
        HUDTroopUtils.StartSingleMarch(listData, 1)
    else
        g_Game.UIManager:Open(UIMediatorNames.HUDSelectTroopList, listData)
    end
end

---@param troopInfo TroopInfo
function HUDTroopUtils.CanCreateOrJoinAssemble(troopInfo)
    local troop = troopInfo.entityData
    if troop == nil then
        return true, ""
    end

    if SlgUtils.IsTroopBatting(troop) then
        return false, "team_status_battle"
    elseif SlgUtils.IsTroopRetreating(troop) then
        return false, "team_status_dead"
    elseif SlgUtils.IsTroopGathering(troop) then
        return false, "team_status_collect"
    elseif SlgUtils.IsTroopInRally(troop) then
        return false, "team_status_rally"
    elseif SlgUtils.IsTroopInGarrison(troop) then
        return false, "team_status_hold"
    elseif SlgUtils.IsTroopInStrengthen(troop) then
        return false, "team_status_hold"
    end

    return true, ""
end

return HUDTroopUtils