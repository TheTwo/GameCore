local CityProcessV2UIParameter = require("CityProcessV2UIParameter")
local CityWorkFurnitureUpgradeUIParameter = require("CityWorkFurnitureUpgradeUIParameter")
local CityWorkCollectUIParameter = require("CityWorkCollectUIParameter")
local CityCollectV2UIParameter = require("CityCollectV2UIParameter")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local CityFurnitureUpgradeSpeedUpHolder = require("CityFurnitureUpgradeSpeedUpHolder")
local CityWorkType = require("CityWorkType")
local CityHatchEggUIParameter = require("CityHatchEggUIParameter")
local I18N = require("I18N")
local CityFurnitureDeployUIParameter = require("CityFurnitureDeployUIParameter")
local BuildMasterDeployUIDataSrc = require("BuildMasterDeployUIDataSrc")
local ShareLevelPetDeployUIDataSrc = require("ShareLevelPetDeployUIDataSrc")
local ShareLevelHeroDeployUIDataSrc = require("ShareLevelHeroDeployUIDataSrc")
local CityMobileUnitUIParameter = require("CityMobileUnitUIParameter")
local CityStoreroomUIParameter = require("CityStoreroomUIParameter")
local CityManageCenterUIParameter = require("CityManageCenterUIParameter")
local HeaterPetDeployUIDataSrc = require("HeaterPetDeployUIDataSrc")
local CityMaterialProcessV2UIParameter = require("CityMaterialProcessV2UIParameter")
local CityWorkI18N = require("CityWorkI18N")
local NumberFormatter = require("NumberFormatter")
local ColorConsts = require("ColorConsts")
local CityWorkClosureFactory = {}
local AdornmentType = require("AdornmentType")

---@param city City
---@param workCfg CityWorkConfigCell
function CityWorkClosureFactory.CreateDisableButton()
    return function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_64"))
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateProcessButton(tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityProcessV2UIParameter.new(tile)
        g_Game.UIManager:Open(UIMediatorNames.CityProcessV2UIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateMaterialProcessButton(tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityMaterialProcessV2UIParameter.new(tile)
        g_Game.UIManager:Open(UIMediatorNames.CityProcessV2UIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateBuildMaterButton(tile, state)
    return function()
        state:ExitToIdleState()
        local dataSrc = BuildMasterDeployUIDataSrc.new(tile)
        local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateMainFurnitureButton(tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityManageCenterUIParameter.new(tile:GetCity())
        g_Game.UIManager:Open(UIMediatorNames.CityManageCenterUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateSharePetLevelButton(tile, state)
    return function()
        state:ExitToIdleState()
        local dataSrc = ShareLevelPetDeployUIDataSrc.new(tile)
        local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateShareHeroLevelButton(tile, state)
    return function()
        state:ExitToIdleState()
        local dataSrc = ShareLevelHeroDeployUIDataSrc.new(tile)
        local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateStoreroomButton(tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityStoreroomUIParameter.new(tile)
        g_Game.UIManager:Open(UIMediatorNames.CityStoreroomUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateHeaterButton(tile, state)
    return function()
        state:ExitToIdleState()
        local dataSrc = HeaterPetDeployUIDataSrc.new(tile)
        local param = CityFurnitureDeployUIParameter.new(tile, dataSrc)
        g_Game.UIManager:Open(UIMediatorNames.CityFurnitureDeployUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateMobileUnitButton(tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityMobileUnitUIParameter.new(tile)
        g_Game.UIManager:Open(UIMediatorNames.CityMobileUnitUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateHatchEggButton(tile, state)
    return function()
        state:ExitToIdleState()
        local furniture = tile:GetCell()
        furniture:TryOpenHatchEggUI()
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateFurnitureLvUpImmediatelyButton(tile, workCfg, state)
    return function()
        state:ExitToIdleState()

        local city = state.city
        local gap = city:GetWorkTimeSyncGap()
        local levelUpInfo = tile:GetCastleFurniture().LevelUpInfo
        local efficiency = 1
        local done = levelUpInfo.CurProgress + gap * efficiency
        local target = levelUpInfo.TargetProgress
        local remainTime = math.max(0, (target - done) / efficiency)

        local isEnough = ModuleRefer.ConsumeModule:CanSpeedUpFurnitureLevelUpCostWithMoney(remainTime)
        if isEnough then
            local function callback()
                city.furnitureManager:RequestLevelUpImmediately(tile:GetCell().singleId, workCfg:Id())
            end
            ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(remainTime, callback)
        else
            ModuleRefer.ConsumeModule:GotoShop()
        end
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
---@return { image: string, text: string }[]
function CityWorkClosureFactory.CreateFurnitureLvUpImmediatelyExtraInfo(tile, workCfg, state)
    local city = state.city
    local gap = city:GetWorkTimeSyncGap()
    local levelUpInfo = tile:GetCastleFurniture().LevelUpInfo
    local efficiency = 1
    local done = levelUpInfo.CurProgress + gap * efficiency
    local target = levelUpInfo.TargetProgress
    local remainTime = math.max(0, (target - done) / efficiency)

    local cost = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
    local itemCfg = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg()

    if ModuleRefer.ConsumeModule:CanSpeedUpFurnitureLevelUpCostWithMoney(remainTime) then
        return {
            {
                image = itemCfg:Icon(),
                text = NumberFormatter.Normal(cost)
            }
        }
    else
        return {
            {
                image = itemCfg:Icon(),
                text = ("<color=%s>%s</color>"):format(ColorConsts.warning, NumberFormatter.Normal(cost))
            }
        }
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateFurnitureLvUpSpeedUpButton(tile, state)
    return function()
        state:ExitToIdleState()
        local furniture = tile:GetCell()
        local holder = CityFurnitureUpgradeSpeedUpHolder.new(furniture)
        local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp))
        local provider = require("CitySpeedUpGetMoreProvider").new()
        provider:SetHolder(holder)
        provider:SetItemList(itemList)
        g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateFurnitureLvUpButton(workCfg, tile, state)
    return function()
        state:ExitToIdleState()
        local furniture = tile:GetCell()
        furniture:TryOpenLvUpUI()
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateFurnitureResCollectButton(workCfg, tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityWorkCollectUIParameter.new(workCfg, tile)
        g_Game.UIManager:Open(UIMediatorNames.CityWorkCollectUIMediator, param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateMilitiaTrainButton(workCfg, tile, state)
    return function()
        state:ExitToIdleState()
        -- local param = CityLegoBuildingUIParameter.new(tile:GetCity(), nil, tile:GetCell():UniqueId())
        -- g_Game.UIManager:Open('CityLegoBuildingUIMediator', param)
    end
end

---@param tile CityFurnitureTile
---@param workCfg CityWorkConfigCell
---@param state CityState
function CityWorkClosureFactory.CreateResGenButton(tile, state)
    return function()
        state:ExitToIdleState()
        local param = CityCollectV2UIParameter.new(tile)
        g_Game.UIManager:Open(UIMediatorNames.CityCollectV2UIMediator, param)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateGachaButton(state)
    return function()
        state:ExitToIdleState()
        g_Game.UIManager:Open(UIMediatorNames.HeroCardMediator)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateEquipButton(state)
    return function()
        state:ExitToIdleState()
        g_Game.UIManager:Open(UIMediatorNames.HeroEquipForgeRoomUIMediator)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateRaderButton(state)
    return function()
        local city = state.city
        local camera = city:GetCamera()
        state:ExitToIdleState()
        ModuleRefer.RadarModule:SetRadarState(true)
        local param = {isInCity = true, stack = camera and camera:RecordCurrentCameraStatus()}
        g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateCastleSkinButton(state)
    return function()
        state:ExitToIdleState()
        g_Game.UIManager:Open(UIMediatorNames.PersonaliseChangeMediator, {typeIndex = AdornmentType.CastleSkin})
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateReplicaPVPButton(state)
    return function()
        state:ExitToIdleState()
        g_Game.UIManager:Open(UIMediatorNames.ReplicaPVPMainMediator)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateEquipMakingButton(state)
    return function()
        state:ExitToIdleState()
        g_Game.UIManager:Open(UIMediatorNames.HeroEquipForgeRoomUIMediator)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateCityDefenceButton(state)
    return function()
        state:ExitToIdleState()
        g_Game.UIManager:Open(UIMediatorNames.DefenceMediator)
    end
end

---@param state CityState
function CityWorkClosureFactory.CreateCityHuntingButton(state)
    return function()
        state:ExitToIdleState()
        ModuleRefer.HuntingModule:OpenHuntingMediator()
    end
end

function CityWorkClosureFactory.CreateCityHuntingDisableButton()
    return function()
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("/*未解锁"))
    end
end

return CityWorkClosureFactory