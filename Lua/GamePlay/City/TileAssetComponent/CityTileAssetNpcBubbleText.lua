---@type CS.UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require('ModuleRefer')
local NpcServiceType = require("NpcServiceType")
local EventConst = require('EventConst')
local ArtResourceUtils = require('ArtResourceUtils')

---@class CityTileAssetNpcBubbleText
---@field new fun():CityTileAssetNpcBubbleText
---@field normalIconTrans CS.UnityEngine.Transform
---@field singleStateIcon CS.U2DSpriteMesh
---@field textNodeTrans CS.UnityEngine.Transform
---@field bubbleIconTrans CS.UnityEngine.Transform
---@field textStateIcon CS.U2DSpriteMesh
---@field text CS.U2DTextMesh
---@field textCollider CS.UnityEngine.BoxCollider
local CityTileAssetNpcBubbleText = sealedClass('CityTileAssetNpcBubbleText')

function CityTileAssetNpcBubbleText:ctor()
    ---@type BubbleConfigCell
    self._bubbleConfig = nil
    self._needReSizeText = false
    self._noTextMode = false
end

function CityTileAssetNpcBubbleText:OnEnable()
    self._needReSizeText = true
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:AddListener(EventConst.ON_CHANGE_ITEMS, Delegate.GetOrCreate(self, self.RefreshBubbleState))
end

function CityTileAssetNpcBubbleText:OnDisable()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.ON_CHANGE_ITEMS, Delegate.GetOrCreate(self, self.RefreshBubbleState))
end

---@param npcConfig CityElementNpcConfigCell
function CityTileAssetNpcBubbleText:SetConfig(npcConfig, popupTradeEnough)
    self._bubbleConfig = nil
    self._duration = nil
    self._interval = nil
    self._npcCfg = npcConfig
    self:RefreshBubbleState()
end

function CityTileAssetNpcBubbleText:RefreshBubbleState()
    self._noTextMode = true
    if self._npcCfg and self._npcCfg:BubbleId() > 0 then
        if self:CheckPopueTradeIsEnough() then
            self._bubbleConfig = ConfigRefer.Bubble:Find(self._npcCfg:BubbleIdReady())
        else
            self._bubbleConfig = ConfigRefer.Bubble:Find(self._npcCfg:BubbleId())
        end
        if self._bubbleConfig then
            self:LoadIcon()
            local content = self._bubbleConfig:Content()
            if string.IsNullOrEmpty(content) then
                self:SetTextContent('')
            else
                self._noTextMode = false
                self:SetTextContent(I18N.Get(content))
            end
        end
    end
    self:Refresh(false)
end

function CityTileAssetNpcBubbleText:CheckPopueTradeIsEnough()
    local servicesGroup = self._npcCfg:ServiceGroupId()
    local servicesCfg = ConfigRefer.NpcServiceGroup:Find(servicesGroup)
    for i = 1, servicesCfg:ServicesLength() do
        local serviceId = servicesCfg:Services(i)
        local serviceCfg = ConfigRefer.NpcService:Find(serviceId)
        if serviceCfg:ServiceType() == NpcServiceType.CommitItem then
            return ModuleRefer.StoryPopupTradeModule:CheckItemsAllEnough(self._elementId, serviceId)
        end
    end
    return false
end

function CityTileAssetNpcBubbleText:LoadIcon()
    local icon = "sp_troop_icon_b"
    if self._bubbleConfig and self._bubbleConfig:Icon() > 0 then
        icon = ArtResourceUtils.GetUIItem(self._bubbleConfig:Icon())
    end
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.singleStateIcon)
    g_Game.SpriteManager:LoadSpriteAsync(icon, self.textStateIcon)
end

function CityTileAssetNpcBubbleText:SetTextContent(content)
    self.text.text = content
    self._needReSizeText = true
end

function CityTileAssetNpcBubbleText:Tick(dt)
    if self._noTextMode then
        return
    end
    if not self._bubbleConfig then
        return
    end
    if self._needReSizeText then
        self._needReSizeText = false
        self.textCollider.size = Vector3(self.text.width + 20, self.text.height, 0.0)
        self.textCollider.center = Vector3((self.text.width + 20) * 0.5, 0, self.text.height)
        local p = self.bubbleIconTrans.localPosition
        p.x = -0.5 * self.text.width - 24
        self.bubbleIconTrans.localPosition = p
        p = self.text.transform.localPosition
        p.x = -0.5 * self.text.width
        self.text.transform.localPosition = p
    end
    if self._duration then
        self._duration = self._duration - dt
        if self._duration <= 0 then
            self:Refresh(false)
        end
    elseif self._interval then
        self._interval = self._interval - dt
        if self._interval <= 0 then
            self:Refresh(true)
        end
    end
end

---@param showText boolean
function CityTileAssetNpcBubbleText:Refresh(showText)
    self._duration = nil
    self._interval = nil
    if not self._bubbleConfig or self._bubbleConfig:Duration() <= 0 then
        self.textNodeTrans:SetVisible(false)
        self.normalIconTrans:SetVisible(true)
        return
    elseif self._bubbleConfig:Interval() <= 0 then
        self.textNodeTrans:SetVisible(true)
        self.normalIconTrans:SetVisible(false)
        return
    end
    self.textNodeTrans:SetVisible(showText)
    self.normalIconTrans:SetVisible(not showText)
    if showText then
        self._duration = self._bubbleConfig:Duration()
    else
        self._interval = self._bubbleConfig:Interval()
    end
end

return CityTileAssetNpcBubbleText

