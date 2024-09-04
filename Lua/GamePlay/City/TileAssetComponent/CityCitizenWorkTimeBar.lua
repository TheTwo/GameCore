-- prefab:city_bubble_citizen_work_progress 

local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local I18N = require("I18N")
local CityWorkTargetType = require("CityWorkTargetType")

---@class CityCitizenWorkTimeBarData
---@field targetType number @CityWorkTargetType
---@field targetId number
---@field onclickTrigger fun(trigger:CityTrigger)
---@field processInfo wds.CastleProcess
---@field autoCollectInfo wds.CastleAutoProduceInfo
---@field workData CityCitizenWorkData

---@class CityCitizenWorkTimeBar
---@field new fun():CityCitizenWorkTimeBar
---@field root CS.UnityEngine.Transform
---@field processRoot CS.UnityEngine.Transform
---@field icon CS.U2DSpriteMesh
---@field progress CS.U2DSpriteMesh
---@field progress_s CS.U2DSpriteMesh
---@field Trigger CS.DragonReborn.LuaBehaviour
---@field ani CS.UnityEngine.Animation
---@field process_ani CS.UnityEngine.GameObject
---@field textQuantity CS.U2DTextMesh
---@field foot_icon CS.UnityEngine.GameObject
---@field normalRoot CS.UnityEngine.GameObject
---@field resourceInfo CS.UnityEngine.GameObject
---@field resTextName CS.U2DTextMesh
---@field resTextLeft CS.U2DTextMesh
---@field resTextLeftCount CS.U2DTextMesh
---@field resIconOut CS.U2DSpriteMesh
---@field vx_trigger CS.FpAnimation.FpAnimationCommonTrigger
local CityCitizenWorkTimeBar = class('CityCitizenWorkTimeBar')

function CityCitizenWorkTimeBar:ctor()
    self._usingTick = false
    self._targetId = nil
    self._targetType = nil
    ---@type CityCitizenWorkData
    self._citizenWorkData = nil
    ---@type wds.CastleProcess
    self._processInfo = nil
    ---@type wds.CastleAutoProduceInfo
    self._autoCollectInfo = nil
    ---@type number
    self._uid = nil
    
    ---@type CS.U2DSpriteMesh
    self.icon = nil
    ---@type CS.U2DSpriteMesh
    self.progress_s = nil
    ---@type CS.U2DSpriteMesh
    self.progress = nil
    ---@type CS.U2DTextMesh
    self.text = nil
    ---@type CS.DragonReborn.LuaBehaviour
    self.Trigger = nil
    ---@type CS.U2DTextMesh
    self.textQuantity = nil
    ---@type CS.UnityEngine.GameObject
    self.foot_icon = nil
    self.tickWaitGoTime = false
    self._city = nil
end

function CityCitizenWorkTimeBar:Awake()
    self.up = self.root.up
end

---@param tileView CityTileView
---@param data CityCitizenWorkTimeBarData
---@param heightFix number|nil
function CityCitizenWorkTimeBar:Init(tileView, data, heightFix)
    local cell = tileView.tile:GetCell()
    self._city = tileView.tile:GetCity()
    self.root.localPosition = self.up * (math.max(cell.sizeX, cell.sizeY) + 0.5)
    if heightFix then
        local p = self.root.localPosition
        p.y = p.y + heightFix
        self.root.localPosition = p
    end
    ---@type CityTrigger
    local trigger = self.Trigger.Instance
    trigger:SetOnTrigger(data.onclickTrigger, tileView.tile, true)
    self:RefreshData(data)
end

---@param data CityCitizenWorkTimeBarData
function CityCitizenWorkTimeBar:RefreshData(data)
    self._targetId = data.targetId
    self._targetType = data.targetType
    self._citizenWorkData = data.workData
    self._processInfo = data.processInfo
    self._autoCollectInfo = data.autoCollectInfo
    ---@type CityTrigger
    local trigger = self.Trigger.Instance
    trigger._onTrigger = data.onclickTrigger
    self:Refresh()
end

function CityCitizenWorkTimeBar:Release()
    self:TickStatus(false)
end

function CityCitizenWorkTimeBar:Refresh()
    self.tickWaitGoTime = false
    local usingTick = false
    local showCollect = false
    self.icon.IsGreyMode = false
    self.normalRoot:SetVisible(true)
    self.resourceInfo:SetVisible(false)
    if self._autoCollectInfo then
        usingTick,showCollect = self:RefreshAutoCollectWork()
    else
        usingTick,showCollect = self:RefreshNormalWork()
    end
    if Utils.IsNotNull(self.foot_icon) then
        self.foot_icon:SetVisible(usingTick and self.tickWaitGoTime)
    end
    self:TickStatus(usingTick)
    self.processRoot:SetVisible(not showCollect)
    local u2dSpriteMeshRender = self.processRoot:GetComponent(typeof(CS.U2DSpriteMesh))
    if not showCollect and Utils.IsNotNull(u2dSpriteMeshRender) then
        g_Game.SpriteManager:LoadSpriteAsync('sp_city_bubble_base_02', u2dSpriteMeshRender)
    end
    self.textQuantity:SetVisible(showCollect)
    self.Trigger.transform:SetVisible(showCollect)
    if Utils.IsNotNull(self.ani) then
        if showCollect then
            self.ani:Stop()
            self.ani:Play()
        else
            self.ani:Stop()
            self.ani:SetAnimationTime("anim_bubble_finish", 0)
            self.ani:Sample()
        end
    end
end

---@return boolean,boolean @usingTick,showCollect
function CityCitizenWorkTimeBar:RefreshNormalWork()
    self.tickWaitGoTime = false
    local usingTick = false
    local showCollect = false
    self.process_ani:SetVisible(false)
    if self._targetType == CityWorkTargetType.Furniture then
        local process = self._processInfo
        if not process then
            g_Game.SpriteManager:LoadSpriteAsync("sp_city_icon_task_food", self.icon)
            goto exechere
        end
        local processCfg = ConfigRefer.CityProcess:Find(process.ConfigId)
        local outPutItem = ConfigRefer.Item:Find(processCfg:Output(1):ItemId())
        g_Game.SpriteManager:LoadSpriteAsync(outPutItem:Icon(), self.icon)
        if (process.LeftNum <= 0 or process.FinishNum > 0) and (not self._citizenWorkData or not self._citizenWorkData._isInfinity) then
            showCollect = true
            self.textQuantity.text = process.FinishNum > 0 and tostring(process.FinishNum) or ''
        else
            if self._citizenWorkData then
                if self._citizenWorkData._isInfinity then
                    usingTick = false
                    self.progress.gameObject:SetVisible(false)
                    self.progress_s.gameObject:SetVisible(false)
                    self.text.gameObject:SetActive(false)
                else
                    usingTick = true
                    self.progress.gameObject:SetVisible(true)
                    self.progress_s.gameObject:SetVisible(false)
                    local v, leftTime = self._citizenWorkData:GetMakeProgress(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
                    self.progress.fillAmount = v
                    self.text.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
                    local index,goTime,_ = self._citizenWorkData:GetCurrentTargetIndexGoToTimeLeftTime()
                    if index and index == 2 and goTime then
                        self.icon.IsGreyMode = true
                        self.tickWaitGoTime = true
                        self.text.gameObject:SetActive(false)
                    else
                        self.icon.IsGreyMode = false
                        self.text.gameObject:SetActive(true)
                    end
                end
            else
                self.progress.gameObject:SetVisible(false)
                self.progress_s.gameObject:SetVisible(true)
                self.text.gameObject:SetActive(false)
                self.progress_s.fillAmount = math.clamp01(process.FinishNum * 1.0 / (process.LeftNum + process.FinishNum))
            end
        end
    elseif self._targetType == CityWorkTargetType.Resource then
        if not self._citizenWorkData then
            goto exechere
        else
            usingTick = true
            local element = self._city.elementManager:GetElementById(self._targetId)
            local resourceCfg = element.resourceConfigCell
            local outItemGroup = ConfigRefer.ItemGroup:Find(resourceCfg:Reward())
            ---@type ItemGroupInfo
            local outItem
            local iconFallback = true
            if outItemGroup and outItemGroup:ItemGroupInfoListLength() > 0 then
                outItem = outItemGroup:ItemGroupInfoList(1)
                local outItemConfig = ConfigRefer.Item:Find(outItem:Items())
                if outItemConfig then
                    g_Game.SpriteManager:LoadSpriteAsync(outItemConfig:Icon(), self.resIconOut)
                    g_Game.SpriteManager:LoadSpriteAsync(outItemConfig:Icon(), self.icon)
                    iconFallback = false
                end
            end
            if iconFallback then
                local bubbleIcon = ArtResourceUtils.GetUIItem(resourceCfg:BubbleIcon())
                g_Game.SpriteManager:LoadSpriteAsync(bubbleIcon, self.icon)
                g_Game.SpriteManager:LoadSpriteAsync(bubbleIcon, self.resIconOut)
            end
            local v, leftTime = self._citizenWorkData:GetMakeProgress(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
            self.progress.fillAmount = v
            self.text.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
            local index,goTime,_ = self._citizenWorkData:GetCurrentTargetIndexGoToTimeLeftTime()
            if index and index == 2 and goTime then
                self.normalRoot:SetVisible(false)
                self.resourceInfo:SetVisible(true)
                self.resTextName.text = I18N.Get(resourceCfg:NameKey())
                self.resTextLeft.text = I18N.Get("city_pickup_item")
                local process = self._city.elementManager:GetResourceProcess(self._targetId)
                if process then
                    self.resTextLeftCount.text = tostring(process.LeftTimes * outItem:Nums())
                else
                    self.resTextLeftCount.text = tostring(resourceCfg:CollectCount() * outItem:Nums())
                end
                self.icon.IsGreyMode = true
                self.tickWaitGoTime = true
                self.text.gameObject:SetActive(false)
            else
                self.progress.gameObject:SetVisible(true)
                self.progress_s.gameObject:SetVisible(false)
                self.icon.IsGreyMode = false
                self.text.gameObject:SetActive(true)
            end
        end
    end
    ::exechere::
    return usingTick,showCollect
end

---@return boolean,boolean @usingTick,showCollect
function CityCitizenWorkTimeBar:RefreshAutoCollectWork()
    local usingTick = false
    local showCollect = false
    self.progress.gameObject:SetVisible(false)
    self.progress_s.gameObject:SetVisible(false)
    self.icon.IsGreyMode = false
    if self._autoCollectInfo then
        local config = ConfigRefer.CityResourceCheck:Find(self._autoCollectInfo.ConfigId)
        if config then
            local outPutItem = ConfigRefer.Item:Find(config:OutputItem())
            g_Game.SpriteManager:LoadSpriteAsync(outPutItem:Icon(), self.icon)
        end
        usingTick = true
    end
    self.process_ani:SetVisible(self._autoCollectInfo and self._autoCollectInfo.Working or false)
    return usingTick, showCollect
end

function CityCitizenWorkTimeBar:TickStatus(on)
    if on == self._usingTick then
        return
    end
    if not on then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.FrameTick))
    else
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.FrameTick))
    end
    self._usingTick = on
end

function CityCitizenWorkTimeBar:FrameTick(_)
    if self._autoCollectInfo then
        self:TickAutoCollectWork()
    elseif self._citizenWorkData then
        self:TickNormalWork()
    end
end

function CityCitizenWorkTimeBar:TickNormalWork()
    if not self._citizenWorkData then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local v, leftTime = self._citizenWorkData:GetMakeProgress(nowTime)
    self.progress.fillAmount = v
    self.text.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
    if self.tickWaitGoTime then
        local _,goTime,_ = self._citizenWorkData:GetCurrentTargetIndexGoToTimeLeftTime()
        if not goTime then
            self.normalRoot:SetVisible(true)
            self.resourceInfo:SetVisible(false)
            self.tickWaitGoTime = false
            self.icon.IsGreyMode = false
            self.text.gameObject:SetActive(true)
            if Utils.IsNotNull(self.foot_icon) then
                self.foot_icon:SetVisible(false)
            end
        end
    end
end

function CityCitizenWorkTimeBar:TickAutoCollectWork()
    if not self._autoCollectInfo then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local leftTime = self._autoCollectInfo.FinishTime.ServerSecond - nowTime
    self.text.text = leftTime > 0 and TimeFormatter.SimpleFormatTimeWithoutZero(leftTime) or "--:--"
    self.process_ani:SetVisible(self._autoCollectInfo.Working)
end

function CityCitizenWorkTimeBar:PlayInAni()
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function CityCitizenWorkTimeBar:PlayOutAni()
    self.vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
end

function CityCitizenWorkTimeBar:GetFadeOutDuration()
    return self.vx_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom2)
end

return CityCitizenWorkTimeBar