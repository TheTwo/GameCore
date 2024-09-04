local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")

local BaseUIComponent = require("BaseUIComponent")

---@class CommonResourceRequirementComponentParameter
---@field iconComponent string
---@field numberComponent string
---@field requireId number|nil
---@field requireValue number|nil
---@field normalColor CS.UnityEngine.Color
---@field notEnoughColor CS.UnityEngine.Color
---@field requireType number @resource -1 | item - 2 | allianceCurrency - 3

---@class CommonResourceRequirementComponent:BaseUIComponent
---@field new fun():CommonResourceRequirementComponent
---@field super BaseUIComponent
local CommonResourceRequirementComponent = class('CommonResourceRequirementComponent', BaseUIComponent)

function CommonResourceRequirementComponent:ctor()
    BaseUIComponent.ctor(self)
    ---@type CommonResourceRequirementComponentParameter
    self._parameter = nil
    self._castleBriefId = nil
    self._playerId = nil
    self._text = nil
    self._icon = nil
    self._lakeCount = 0
    self._isEnough = false
end

function CommonResourceRequirementComponent:OnCreate(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Resource.Values.MsgPath, Delegate.GetOrCreate(self, self.OnResourceChanged))
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemDataChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
end

---@param data CommonResourceRequirementComponentParameter
function CommonResourceRequirementComponent:OnFeedData(data)
    self._parameter = data
    self._playerId = ModuleRefer.PlayerModule.playerId
    self._castleBriefId = ModuleRefer.PlayerModule:GetPlayer().SceneInfo.CastleBriefId
    self._text = self:Text(data.numberComponent)
    self._icon = self:Image(data.iconComponent)
    
    if Utils.IsNotNull(self._icon) and data.requireId then
        if data.requireType == 1 then

        elseif data.requireType == 2 then
            local cfg = ConfigRefer.Item:Find(data.requireId)
            if cfg then
                g_Game.SpriteManager:LoadSprite(cfg:Icon(), self._icon)
            end
        elseif data.requireType == 3 then
            local cfg = ConfigRefer.AllianceCurrency:Find(data.requireId)
            if cfg then
                g_Game.SpriteManager:LoadSprite(cfg:Icon(), self._icon)
            end
        end
    end
    self._text.text = data.requireValue and tostring(data.requireValue) or string.Empty
    if data.normalColor then
        self._text.color = data.normalColor
    end
    self._lakeCount = nil
    self:OnResourceChanged({ID = self._playerId}, nil)
    self:OnItemDataChanged()
    self:OnAllianceCurrencyChanged({data.requireId})
end

function CommonResourceRequirementComponent:OnClose(param)
    self._parameter = nil
    self._playerId = nil
    self._castleBriefId = nil
    self._icon = nil
    self._text = nil
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.OnItemDataChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Resource.Values.MsgPath, Delegate.GetOrCreate(self, self.OnResourceChanged))
end

function CommonResourceRequirementComponent:GetIsEnough()
    return self._isEnough
end

function CommonResourceRequirementComponent:ShowLakeJump()
    if self._isEnough or not self._parameter or not self._parameter.requireId or not self._lakeCount then
        return
    end
    if self._parameter.requireType == 2 then
        local cfg = ConfigRefer.Item:Find(self._parameter.requireId)
        if cfg then
            ---@type {id:number, num:number}[]
            local getmoreList ={}
            getmoreList[1] = {}
            getmoreList[1].id = self._parameter.requireId
            getmoreList[1].num = self._lakeCount
            ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
        end
    end
end

---@param entity wds.Player
function CommonResourceRequirementComponent:OnResourceChanged(entity, _)
    local parameter = self._parameter
    if not parameter or parameter.requireType ~= 1 then
        return
    end
    if self._playerId ~= entity.ID then
        return
    end
    local value = parameter.requireId and ModuleRefer.PlayerModule:GetPlayer().Resource.Values[parameter.requireId] or 0
    if parameter.requireId and parameter.requireValue and (value < parameter.requireValue) then
        if Utils.IsNotNull(self._text) and parameter.notEnoughColor then
            self._text.color = parameter.notEnoughColor
        end
        self._lakeCount = parameter.requireValue - value
        self._isEnough = false
    else
        if Utils.IsNotNull(self._text) and parameter.normalColor then
            self._text.color = parameter.normalColor
        end
        self._lakeCount = 0
        self._isEnough = true
    end
end

function CommonResourceRequirementComponent:OnItemDataChanged()
    local parameter = self._parameter
    if not parameter or parameter.requireType ~= 2 then
        return
    end
    local itemCount = parameter.requireId and ModuleRefer.InventoryModule:GetAmountByConfigId(parameter.requireId) or 0
    if parameter.requireId and parameter.requireValue and (itemCount < parameter.requireValue) then
        if Utils.IsNotNull(self._text) and parameter.notEnoughColor then
            self._text.color = parameter.notEnoughColor
        end
        self._lakeCount = parameter.requireValue - itemCount
        self._isEnough = false
    else
        if Utils.IsNotNull(self._text) and parameter.normalColor then
            self._text.color = parameter.normalColor
        end
        self._lakeCount = 0
        self._isEnough = true
    end
end

function CommonResourceRequirementComponent:OnAllianceCurrencyChanged(idMap)
    local parameter = self._parameter
    if not parameter or parameter.requireType ~= 3 or not parameter.requireId or not idMap[parameter.requireId] then
        return
    end
    local itemCount = ModuleRefer.AllianceModule:GetAllianceCurrencyById(parameter.requireId)
    if parameter.requireValue and (not itemCount or itemCount < parameter.requireValue) then
        if Utils.IsNotNull(self._text) and parameter.notEnoughColor then
            self._text.color = parameter.notEnoughColor
        end
        self._isEnough = false
    else
        if Utils.IsNotNull(self._text) and parameter.normalColor then
            self._text.color = parameter.normalColor
        end
        self._isEnough = true
    end
end

return CommonResourceRequirementComponent