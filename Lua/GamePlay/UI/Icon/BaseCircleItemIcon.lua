local Delegate = require("Delegate")
local Utils = require("Utils")
local UIHelper = require("UIHelper")

--- scene:scene_child_item_circle
local BaseUIComponent = require("BaseUIComponent")

---@class BaseCircleItemIcon:BaseUIComponent
---@field new fun():BaseCircleItemIcon
---@field super BaseUIComponent
---@field itemData ItemConfigCell
---@field count number
---@field addCount number
---@field locked boolean @是否锁定 default false
---@field showCount boolean @是否显示数量 default true
---@field useNoneMask boolean @如果显示数量，当数量为0时，是否显示NoneMask default true
---@field countAtTop boolean @如果显示数量，数量是否显示在顶部 default false
---@field showNumPair boolean @是否显示为数量对，如果为是，则数量显示为count/addCount，default false
---@field isPlayAnim boolean @是否需要播放动画
---@field customData table
---@field onClick fun(item:ItemConfigCell,customData:table)
---@field onDelBtnClick fun(item:ItemConfigCell,customData:table)
local BaseCircleItemIcon = class('BaseCircleItemIcon', BaseUIComponent)

function BaseCircleItemIcon:OnCreate(param)
    --base info
    self.itemBase = self:Button('p_item_base',Delegate.GetOrCreate(self,self.OnClick))
    ---@type CS.Empty4Raycast
    self.itemBaseEmpty4Raycast = self:BindComponent('p_item_base', typeof(CS.Empty4Raycast))
    self.imgItemFrame = self:Image('p_item_frame')
    self.imgItemIcon = self:Image('p_item_icon')
    self.imgItemSelect = self:Image('p_img_select')
    self.textLv = self:Text("p_text_lv")
    self.p_group_lock = self:GameObject("p_group_lock")
end

---OnFeedData
---@param data ItemIconData
function BaseCircleItemIcon:OnFeedData(data)
    self.itemData = data.configCell
    
    self.onClick = data.onClick
    self.showSelect = data.showSelect or false
    self:UpdateIcon()
    if data.count and Utils.IsNotNull(self.textLv) then
        self.textLv.text = tostring(data.count)
    end
    if Utils.IsNotNull(self.p_group_lock) then
        self.p_group_lock:SetVisible(data.locked)
    end
end

function BaseCircleItemIcon:UpdateIcon()
    if not self.itemData then
        self:Reset(true)
        return
    end
    self:Reset()
    self:ChangeIcon(self.itemData:Icon())
    local quality = self.itemData:Quality()
    self:ChangeItemFrame('sp_item_frame_circle_'..tostring(quality))
    self:ChangeSelectStatus(self.showSelect)
end

function BaseCircleItemIcon:Reset(resetIcon)
    if resetIcon then
        self:ChangeIcon("sp_icon_missing")
        self:ChangeItemFrame('sp_item_frame_circle_0')
    end
    self:ChangeSelectStatus(false)
end

function BaseCircleItemIcon:ChangeIcon(icon)
    g_Game.SpriteManager:LoadSprite(icon, self.imgItemIcon)
    self.itemIconName = icon
end

function BaseCircleItemIcon:ChangeItemFrame(iconName)
    g_Game.SpriteManager:LoadSprite(iconName, self.imgItemFrame)
    self.framIconName = iconName
end

function BaseCircleItemIcon:ChangeSelectStatus(isSelected)
    self.imgItemSelect:SetVisible(isSelected)
end

function BaseCircleItemIcon:SetGray(isGray)
    if Utils.IsNotNull(self.imgItemIcon) then
        UIHelper.SetGray(self.imgItemIcon.gameObject, isGray)
    end
end

---@param color CS.UnityEngine.Color
function BaseCircleItemIcon:SetCountColor(color)
    if Utils.IsNotNull(self.textLv) then
        self.textLv.color = color
    end
end

return BaseCircleItemIcon