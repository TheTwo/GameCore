local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
---@class CityFurWorkBubbleStateProcess:CityFurWorkBubbleStateBase
---@field new fun():CityFurWorkBubbleStateProcess
---@field _bubble City3DBubbleStandard
local CityFurWorkBubbleStateProcess = class("CityFurWorkBubbleStateProcess", CityFurWorkBubbleStateBase)
local Delegate = require("Delegate")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
local ConfigRefer = require("ConfigRefer")
local CityProcessV2UIParameter = require("CityProcessV2UIParameter")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkType = require("CityWorkType")
local CityProcessUtils = require("CityProcessUtils")

function CityFurWorkBubbleStateProcess:GetName()
    return CityFurWorkBubbleStateBase.Names.Process
end

function CityFurWorkBubbleStateProcess:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
    self.isHatchEgg = self.furniture:CanDoCityWork(CityWorkType.Incubate)
end

function CityFurWorkBubbleStateProcess:Exit()
    CityFurWorkBubbleStateBase.Exit(self)
    self._bubble = nil
    self.gearAnim = nil
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnFrameTick))
end

function CityFurWorkBubbleStateProcess:OnFrameTick()
    if self._bubble == nil then return end
    if not self.needTick then return end

    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then return end

    local progress = CityWorkProcessWdsHelper.GetCityWorkProcessProgress(self.city, castleFurniture, self.processInfo)
    self._bubble:UpdateProgress(progress)
    if not self.isHatchEgg then
        self._bubble:ShowNumberText(("%d"):format(self.processInfo.FinishNum))
    end
    if progress >= 1 then
        self.needTick = false
        self:OnBubbleLoaded(self._bubble)
    end
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateProcess:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()
    
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo.ConfigId == 0 then
        self.stateMachine:ChangeState(CityFurWorkBubbleStateBase.Names.Idle)
        return
    end

    if processInfo.LeftNum > 0 then
        local paused = castleFurniture.WorkType2Id[CityWorkType.Process] == nil
            and castleFurniture.WorkType2Id[CityWorkType.Incubate] == nil
            and castleFurniture.WorkType2Id[CityWorkType.MaterialProcess] == nil
        self.needTick = not paused
        local progress = CityWorkProcessWdsHelper.GetCityWorkProcessProgress(self.city, castleFurniture, processInfo)
        local processCfg = ConfigRefer.CityWorkProcess:Find(processInfo.ConfigId)
        local icon = CityWorkProcessWdsHelper.GetOutputIcon(processCfg)
        self._bubble:ShowProgress(progress, icon, paused)
        if not self.isHatchEgg then
            self._bubble:ShowNumberText(("%d"):format(processInfo.FinishNum))
        else
            self._bubble:SetProgressIconSortingOrder(800)
        end
        self.processInfo = processInfo
    else
        local processCfg = ConfigRefer.CityWorkProcess:Find(processInfo.ConfigId)
        local icon = CityWorkProcessWdsHelper.GetOutputIcon(processCfg)
        self._bubble:ShowBubble(icon):PlayRewardAnim()
        if not self.isHatchEgg then
            self._bubble:ShowBubbleText(("%d"):format(processInfo.FinishNum))
        else
            self._bubble:SetBubbleIconSortingOrder(1300)
        end
    end
    self.gearAnim = processInfo.Working
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())
end

function CityFurWorkBubbleStateProcess:OnBubbleUnload()
    self.needTick = false
    self._bubble = nil
end

---@param trigger CityTrigger
function CityFurWorkBubbleStateProcess:OnClick(trigger)
    local castleFurniture = self.city.furnitureManager:GetCastleFurniture(self.furnitureId)
    if castleFurniture == nil then
        return true
    end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo.FinishNum > 0 then
        if self.city and self.city.cityWorkManager then
            if self.city.gridView and self.city.gridView:IsViewReady() then
                local cellTile = self.city.gridView:GetFurnitureTile(castleFurniture.Pos.X, castleFurniture.Pos.Y)
                local furLvCfg = cellTile:GetCell().furnitureCell
                ---@type CityWorkConfigCell
                local processWorkCfg = nil
                for i = 1, furLvCfg:WorkListLength() do
                    local workCfgId = furLvCfg:WorkList(i)
                    local workCfg = ConfigRefer.CityWork:Find(workCfgId)
                    if workCfg and workCfg:Type() == CityWorkType.Process or workCfg:Type() == CityWorkType.Incubate or workCfg:Type() == CityWorkType.MaterialProcess then
                        processWorkCfg = workCfg
                        break
                    end
                end
                if processWorkCfg then
                    local callback = nil
                    local processCfg = ConfigRefer.CityWorkProcess:Find(processInfo.ConfigId)
                    if CityProcessUtils.IsFurnitureRecipe(processCfg) then
                        callback = function()
                            local output = ConfigRefer.Item:Find(processCfg:Output())
                            local lvCfgId = checknumber(output:UseParam(1))
                            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
                            self.city:EnterBuildFurniture(lvCfg)
                        end
                    end
                    self.city.cityWorkManager:RequestCollectProcessesLike(self.furnitureId, {}, processWorkCfg:Id(), nil, callback)
                    if processWorkCfg:Type() == CityWorkType.Process then
                        self.city.petManager:BITraceBubbleClick(self.furnitureId, "claim_process")
                    elseif processWorkCfg:Type() == CityWorkType.Incubate then
                        self.city.petManager:BITraceBubbleClick(self.furnitureId, "claim_incubate")
                    elseif processWorkCfg:Type() == CityWorkType.MaterialProcess then
                        self.city.petManager:BITraceBubbleClick(self.furnitureId, "claim_material_process")
                    end
                    g_Game.SoundManager:Play("sfx_ui_reward_crop")
                end
            end
        end
    else
        if self.furniture:CanDoCityWork(CityWorkType.Incubate) then
            if self.city.gridView and self.city.gridView:IsViewReady() then
                local cellTile = self.city.gridView:GetFurnitureTile(castleFurniture.Pos.X, castleFurniture.Pos.Y)
                local CityHatchEggUIParameter = require("CityHatchEggUIParameter")
                local param = CityHatchEggUIParameter.new(cellTile)
                g_Game.UIManager:Open(UIMediatorNames.CityHatchEggUIMediator, param)
            end
        end
    end
    return true
end

return CityFurWorkBubbleStateProcess