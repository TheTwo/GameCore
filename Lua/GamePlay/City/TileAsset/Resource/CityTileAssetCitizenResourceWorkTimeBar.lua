local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local CityTileAssetBubble = require("CityTileAssetBubble")
local CityTilePriority = require("CityTilePriority")
local TimeFormatter = require("TimeFormatter")
local CityWorkTargetType = require("CityWorkTargetType")
local ItemGroupHelper = require("ItemGroupHelper")

---@class CityTileAssetCitizenResourceWorkTimeBar:CityTileAssetBubble
---@field new fun():CityTileAssetCitizenResourceWorkTimeBar
---@field super CityTileAssetBubble
---@field bubble CityCitizenWorkTimeBar|City3DBubbleStandard
local CityTileAssetCitizenResourceWorkTimeBar = class('CityTileAssetCitizenResourceWorkTimeBar', CityTileAssetBubble)

function CityTileAssetCitizenResourceWorkTimeBar:ctor()
    CityTileAssetBubble.ctor(self)
    self._elementId = nil
    self._citizenWorkData = nil
    self.isUI = true
end

function CityTileAssetCitizenResourceWorkTimeBar:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._cityCamera = city:GetCamera()
    self._uid = city.uid
    self._cityCamera = city:GetCamera()
    self._elementId = self.tileView.tile:GetCell().tileId
    ---@type CityElementResource
    local element = city.elementManager:GetElementById(self._elementId)
    if element then
        self._resourceConfig = element.resourceConfigCell
        if self._resourceConfig then
            self._artConfig = ConfigRefer.ArtResource:Find(self._resourceConfig:Model())
        end
    end
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
end

function CityTileAssetCitizenResourceWorkTimeBar:OnTileViewRelease()
    CityTileAssetBubble.OnTileViewRelease(self)
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataDel))
end

---@return boolean
function CityTileAssetCitizenResourceWorkTimeBar:ShouldShow()
    self._citizenWorkData = nil
    local city = self:GetCity()
    if ModuleRefer.CityModule.myCity.uid ~= city.uid then
        return false
    end
    local citizenMgr = city.cityCitizenManager
    self._citizenWorkData = citizenMgr:GetWorkDataByTarget(self._elementId, CityWorkTargetType.Resource)
    return self._citizenWorkData ~= nil and not self.tileView.tile.inMoveState
end

function CityTileAssetCitizenResourceWorkTimeBar:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end
    return self:GetPrefabNameImp()
end

function CityTileAssetCitizenResourceWorkTimeBar:GetPrefabNameImp()
    local index, goTime,_ = self._citizenWorkData:GetCurrentTargetIndexGoToTimeLeftTime()
    self.showDescBubble = index == 2 and goTime ~= nil
    return self.showDescBubble
        and ArtResourceUtils.GetItem(ArtResourceConsts.city_bubble_citizen_work_progress)
        or ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_group)
end

---@param go CS.UnityEngine.GameObject
---@param userData any
function CityTileAssetCitizenResourceWorkTimeBar:OnAssetLoaded(go, userData)
    CityTileAssetBubble.OnAssetLoaded(self, go, userData)
    if Utils.IsNull(go) then
        return
    end

    if self.showDescBubble then
        ---@type CityCitizenWorkTimeBarData
        local data = {}
        data.targetType = CityWorkTargetType.Resource
        data.targetId = self._elementId
        data.onclickTrigger = nil
        data.workData = self._citizenWorkData
        data.processInfo = nil
        data.autoCollectInfo = nil
        self.bubble = go:GetLuaBehaviour("CityCitizenWorkTimeBar").Instance
        local heightFix
        if self._artConfig then
            heightFix = self._artConfig:CapsuleHeight()
        end
        self.bubble:Init(self.tileView, data, heightFix)
        self:TickDescBubble(true)
        self.bubble:PlayInAni()
    else
        self.bubble = go:GetLuaBehaviour("City3DBubbleStandard").Instance
        self.bubble:Reset()
        self.bubble:EnableTrigger(false)
        if not self:TrySetPosToMainAssetAnchor(self.bubble.transform) then
            self:SetPosToTileWorldCenter(go)
        end
        local resourceCfg = self._resourceConfig
        local outItemGroup = ConfigRefer.ItemGroup:Find(resourceCfg:Reward())
        local gotIcon, icon = ItemGroupHelper.GetItemIcon(outItemGroup)
        if not gotIcon then
            local bubbleIcon = ArtResourceUtils.GetUIItem(resourceCfg:BubbleIcon())
            icon = bubbleIcon
        end
        local v, leftTime = self._citizenWorkData:GetMakeProgress(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
        self.bubbleLeftTime = leftTime
        self.bubble:ShowProgress(v, icon, false, TimeFormatter.SimpleFormatTimeWithoutZero(self.bubbleLeftTime))
        self:TickProgressBubble(true)
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:OnAssetUnload(go, fade)
    if self.bubble then
        if self.showDescBubble then
            self.bubble:Release()
        else
            self.bubble:Reset()
            self.bubble:PlayOutAni()
        end
        self.bubble = nil
    end
    self:TickDescBubble(false)
    self:TickProgressBubble(false)
    self.showDescBubble = nil
end

function CityTileAssetCitizenResourceWorkTimeBar:GetFadeOutDuration()
    if self.bubble and not self.showDescBubble then
        return self.bubble:GetFadeOutDuration()
    end
    return 0
end

function CityTileAssetCitizenResourceWorkTimeBar:Refresh()
    self:Hide()
    self:Show()
end

function CityTileAssetCitizenResourceWorkTimeBar:TickDescBubble(on)
    if on then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnDescBubbleTick))
    else
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnDescBubbleTick))
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:TickProgressBubble(on)
    if on then
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnProgressBubbleTick))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTextBubbleTick))
    else
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnProgressBubbleTick))
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTextBubbleTick))
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:OnDescBubbleTick(delta)
    if not self._citizenWorkData then
        self:Refresh()
        return
    end
    local index, goTime, _ = self._citizenWorkData:GetCurrentTargetIndexGoToTimeLeftTime()
    if index ~= 2 or goTime == nil then
        self:Refresh()
        return
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:OnProgressBubbleTick(delta)
    if not self._citizenWorkData then
        self:Refresh()
        return
    end

    local v, leftTime = self._citizenWorkData:GetMakeProgress(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor())
    self.bubbleLeftTime = leftTime
    self.bubble:UpdateProgress(v)
end

function CityTileAssetCitizenResourceWorkTimeBar:OnTextBubbleTick(delta)
    self.bubble:ShowTimeText(TimeFormatter.SimpleFormatTimeWithoutZero(self.bubbleLeftTime))
end

---@param content table @{targetId=targetId,targetType=targetType}
function CityTileAssetCitizenResourceWorkTimeBar:OnWorkDataAdd(city, id, content)
    if not self._uid or city.uid ~= self._uid then
        return
    end
    if content.targetType == CityWorkTargetType.Resource and content.targetId == self._elementId then
        self:Refresh()
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:OnWorkDataChanged(city, id)
    if not self._uid or city.uid ~= self._uid then
        return
    end
    if self._citizenWorkData and id == self._citizenWorkData._id then
        self:Refresh()
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:OnWorkDataDel(city, id)
    if not self._uid or city.uid ~= self._uid then
        return
    end
    if self._citizenWorkData and id == self._citizenWorkData._id then
        self:Refresh()
    end
end

function CityTileAssetCitizenResourceWorkTimeBar:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.RESOURCE
end

function CityTileAssetCitizenResourceWorkTimeBar:OnMoveBegin()
    self:Hide()
end

function CityTileAssetCitizenResourceWorkTimeBar:OnMoveEnd()
    if self:ShouldShow() then
        self:Show()
    end
end

return CityTileAssetCitizenResourceWorkTimeBar

