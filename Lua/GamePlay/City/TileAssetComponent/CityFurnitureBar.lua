---@class CityFurnitureBar
---@field new fun():CityFurnitureBar
---@field p_rotation CS.U2DFacingCamera
---@field p_progress_upgrade CS.UnityEngine.GameObject
---@field p_bar_upgrade_n CS.U2DSlider
---@field p_bar_upgrade_stop CS.U2DSlider
---@field p_progress CS.UnityEngine.GameObject
---@field p_bar CS.U2DSlider
---@field p_info CS.UnityEngine.GameObject
---@field p_text_lv CS.U2DTextMesh
---@field p_text_name CS.U2DTextMesh
local CityFurnitureBar = class("CityFurnitureBar")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local TimeFormatter = require("TimeFormatter")

---@param city City
function CityFurnitureBar:FeedData(city, furnitureId, selected)
    self.city = city
    self.furnitureId = furnitureId
    self.selected = selected

    if city:GetCamera() and self.p_rotation then
        self.p_rotation.FacingCamera = city.camera.mainCamera
    end

    self.furniture = self.city.furnitureManager:GetFurnitureById(self.furnitureId)
    --- 升级条
    local isUpgrading = self.furniture:IsShowUpgradingBar()
    self.p_progress_upgrade:SetActive(isUpgrading)
    if isUpgrading then
        self:UpdateUpgradingProcess()
    end

    --- 血条
    local showLife = self:NeedShowLife()
    self.p_progress:SetActive(showLife)
    if showLife then
        self.p_bar.progress = self:GetLifeProgress()
    end

    --- 选中信息
    self.p_text_lv.text = tostring(self.furniture.level)
    self.p_text_name.text = self.furniture.name
    self.p_info:SetActive(self.selected)

    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_HP_UPDATE, Delegate.GetOrCreate(self, self.OnHpUpdate))
end

function CityFurnitureBar:Clear()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_HP_UPDATE, Delegate.GetOrCreate(self, self.OnHpUpdate))

    self.city = nil
    self.furnitureId = nil
    self.selected = nil
end

function CityFurnitureBar:UpdateUpgradingProcess()
    local isUpgrading = self.furniture:IsShowUpgradingBar()
    self.p_progress_upgrade:SetVisible(isUpgrading)
    if not isUpgrading then return end

    local isPaused = self.furniture:IsUpgradingPaused()
    self.p_bar_upgrade_n:SetVisible(not isPaused)
    self.p_bar_upgrade_stop:SetVisible(isPaused)

    if isPaused then
        self.p_bar_upgrade_stop.progress = self.furniture:GetPausedLevelUpProgress()
        local remainTime = self.furniture:GetPausedLevelUpRemainTime()
        self.p_text_upgrade_time.text = TimeFormatter.SimpleFormatTime(remainTime)
    else
        self.p_bar_upgrade_n.progress = self.furniture:GetNormalLevelUpProgress()
        local remainTime = self.furniture:GetNormalLevelUpProgressRemainTime()
        self.p_text_upgrade_time.text = TimeFormatter.SimpleFormatTime(remainTime)
    end
end

function CityFurnitureBar:Refresh()
    if not self.furniture then return end

    --- 升级条
    local isUpgrading = self.furniture:IsShowUpgradingBar()
    self.p_progress_upgrade:SetActive(isUpgrading)
    if isUpgrading then
        self:UpdateUpgradingProcess()
    end

    --- 血条
    local showLife = self:NeedShowLife()
    self.p_progress:SetActive(showLife)
    if showLife then
        self.p_bar.progress = self:GetLifeProgress()
    end

    --- 选中信息
    self.p_text_lv.text = tostring(self.furniture.level)
    self.p_text_name.text = self.furniture.name
    self.p_info:SetActive(self.selected)
end

function CityFurnitureBar:SetSelected(flag)
    self.selected = flag
    self.p_info:SetActive(flag)
end

function CityFurnitureBar:NeedShowLife()
    return false
    -- if self.furniture:ForceShowLifeBar() then return true end
    -- if self.furniture:IsInBattleState() then return true end

    -- if ModuleRefer.SlgModule.troopManager == nil then
    --     return false
    -- end
    
    -- local troop = ModuleRefer.SlgModule.troopManager:FindFurnitureCtrlByFunitureId(self.furniture.singleId)
    -- if troop == nil then return false end

    -- return troop._data.Battle.Durability < troop._data.Battle.MaxDurability
end

function CityFurnitureBar:GetLifeProgress()
    local troop = ModuleRefer.SlgModule.troopManager:FindFurnitureCtrlByFunitureId(self.furniture.singleId)
    if troop == nil then return 1 end
    if ModuleRefer.SlgModule.troopManager == nil then return 1 end

    return troop._data.Battle.Durability / troop._data.Battle.MaxDurability
end

function CityFurnitureBar:OnSlgAssetUpdate(typ, uniqueId)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeFurniture then return end
    if uniqueId ~= self.furnitureId then return end
    --- 血条
    local showLife = self:NeedShowLife()
    self.p_progress:SetActive(showLife)
    if showLife then
        self.p_bar.progress = self:GetLifeProgress()
    end
end

function CityFurnitureBar:OnHpUpdate(typ, uniqueId)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeFurniture then return end
    if uniqueId ~= self.furnitureId then return end
    self.p_bar.progress = self:GetLifeProgress()
end

return CityFurnitureBar