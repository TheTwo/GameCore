local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local BaseItemIcon = require("BaseItemIcon")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class SEHudJoyStickSelectBallTipCellData
---@field pocketBallConfig PetPocketBallConfigCell
---@field count number

---@class SEHudJoyStickSelectBallTipCell:BaseTableViewProCell
---@field super BaseTableViewProCell
local SEHudJoyStickSelectBallTipCell = class("SEHudJoyStickSelectBallTipCell", BaseTableViewProCell)

function SEHudJoyStickSelectBallTipCell:ctor()
    SEHudJoyStickSelectBallTipCell.super.ctor(self)
    self._itemCount = 0
end

function SEHudJoyStickSelectBallTipCell:OnCreate()
    self._p_item_frame = self:Image("p_item_frame")
    self._p_item_icon = self:Image("p_item_icon")
    self._p_img_select = self:GameObject("p_img_select")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_clickArea = self:Button("p_clickArea", Delegate.GetOrCreate(self, self.OnClickSelf))
end

---@param data SEHudJoyStickSelectBallTipCellData
function SEHudJoyStickSelectBallTipCell:OnFeedData(data)
    self._itemCount = data.count
    local configCell = ConfigRefer.Item:Find(data.pocketBallConfig:LinkItem())
    g_Game.SpriteManager:LoadSprite(BaseItemIcon.GetFrameImageNameByQuality(configCell:Quality(), true), self._p_item_frame)
    g_Game.SpriteManager:LoadSprite(configCell:Icon(), self._p_item_icon)
    self._p_text_quantity.text = string.format("x%d", data.count)
end

function SEHudJoyStickSelectBallTipCell:OnClickSelf()
    if self._itemCount <= 0 then return end
    self:SelectSelf()
end

function SEHudJoyStickSelectBallTipCell:Select()
    self._p_img_select:SetVisible(true)
end

function SEHudJoyStickSelectBallTipCell:UnSelect()
    self._p_img_select:SetVisible(false)
end

return SEHudJoyStickSelectBallTipCell