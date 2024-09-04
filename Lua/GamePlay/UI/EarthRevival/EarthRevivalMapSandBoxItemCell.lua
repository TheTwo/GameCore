local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EarthRevivalDefine = require('EarthRevivalDefine')
local TouchMenuBasicInfoDatum = require('TouchMenuBasicInfoDatum')
local TouchMenuCellTextDatum = require('TouchMenuCellTextDatum')

---@class EarthRevivalMapSandBoxItemCell : BaseTableViewProCell
local EarthRevivalMapSandBoxItemCell = class('EarthRevivalMapSandBoxItemCell', BaseTableViewProCell)

---@class EarthRevivalMapSandBoxItemCellParam
---@field type number
---@field configID number

function EarthRevivalMapSandBoxItemCell:OnCreate()
    self.imgIcon = self:Image("p_icon")
    self.btnItem = self:Button("", Delegate.GetOrCreate(self, self.OnClickItem))
end

---@param param EarthRevivalMapSandBoxItemCellParam
function EarthRevivalMapSandBoxItemCell:OnFeedData(param)
    if not param then
        return
    end

    self.type = param.type
    self.configID = param.configID
    self:SetIconByType(self.type)
end

function EarthRevivalMapSandBoxItemCell:OnClickItem()
    local configInfo = self:GetConfigInfoByType(self.type)
    if not configInfo then
        return
    end
    local content = string.Empty
    if self.type == EarthRevivalDefine.EarthRevivalMap_ItemType.Monster then
        content = configInfo:Introduction()
    elseif self.type == EarthRevivalDefine.EarthRevivalMap_ItemType.Building then
        content = configInfo:Des()
    elseif self.type == EarthRevivalDefine.EarthRevivalMap_ItemType.WorldEvent then
        ---@type WorldEventDetailMediatorParameter
        local param = {}
        param.clickTransform = self.btnItem.transform
        param.touchMenuBasicInfoDatum = TouchMenuBasicInfoDatum.new(I18N.Get(configInfo:Name()), "", "", configInfo:Level())
        param.touchMenuCellTextDatum = TouchMenuCellTextDatum.new(I18N.Get(configInfo:Des()), true)
        param.tid = self.configID
        param.openType = 1

        ModuleRefer.ToastModule:ShowWorldEventDetail(param)
        return
    end

    ---@type TextToastMediatorParameter
    local param = {}
    param.clickTransform = self.btnItem:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.content = I18N.Get(content)
    ModuleRefer.ToastModule:ShowTextToast(param)

end

function EarthRevivalMapSandBoxItemCell:GetConfigInfoByType(type)
    local configInfo = nil
    if type == EarthRevivalDefine.EarthRevivalMap_ItemType.Monster then
        configInfo = ConfigRefer.KmonsterData:Find(self.configID)
    elseif type == EarthRevivalDefine.EarthRevivalMap_ItemType.Building then
        configInfo = ConfigRefer.FixedMapBuilding:Find(self.configID)
    elseif type == EarthRevivalDefine.EarthRevivalMap_ItemType.WorldEvent then
        configInfo = ConfigRefer.WorldExpeditionTemplate:Find(self.configID)
    end
    return configInfo
end

function EarthRevivalMapSandBoxItemCell:SetIconByType(type)
    local configInfo = self:GetConfigInfoByType(type)
    if not configInfo then
        return
    end
    if type == EarthRevivalDefine.EarthRevivalMap_ItemType.Monster then
        g_Game.SpriteManager:LoadSprite(configInfo:Icon(), self.imgIcon)
    elseif type == EarthRevivalDefine.EarthRevivalMap_ItemType.Building then
        g_Game.SpriteManager:LoadSprite(configInfo:Image(), self.imgIcon)
    elseif type == EarthRevivalDefine.EarthRevivalMap_ItemType.WorldEvent then
        g_Game.SpriteManager:LoadSprite(configInfo:WorldTaskIcon(), self.imgIcon)
    end
end

return EarthRevivalMapSandBoxItemCell