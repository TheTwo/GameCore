local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local UIStatusEnum = require("CityProcessV2UIStatusEnum")
local Delegate = require('Delegate')
local CityProcessUtils = require("CityProcessUtils")

---@class CityProcessV2UIFurnitureRecipe:BaseTableViewProCell
local CityProcessV2UIFurnitureRecipe = class('CityProcessV2UIFurnitureRecipe', BaseTableViewProCell)

function CityProcessV2UIFurnitureRecipe:OnCreate()
    self._statusRecord = self:StatusRecordParent("")
    ---品质色
    self._p_frame_furniture = self:Image("p_frame_furniture")
    self._child_img_select = self:GameObject("child_img_select")
    self._p_icon_furniture = self:Image("p_icon_furniture")
    self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param data CityProcessV2UIRecipeData
function CityProcessV2UIFurnitureRecipe:OnFeedData(data)
    self.data = data
    local status = self.data.param:GetUIStatusByRecipeId(self.data.processCfg:Id(), true)
    local canMake = false
    if status == UIStatusEnum.NotWorking_LimitNotReach then
        self._statusRecord:ApplyStatusRecord(1)
    elseif status == UIStatusEnum.NotWorking_LimitReach then
        self._statusRecord:ApplyStatusRecord(2)
    elseif status == UIStatusEnum.NotWorking_Locked then
        self._statusRecord:ApplyStatusRecord(3)
    else
        self._statusRecord:ApplyStatusRecord(0)
        canMake = true
    end

    local itemCfg = self.data:GetItemIconData().configCell
    local background = ("sp_item_frame_%d"):format(itemCfg:Quality())
    g_Game.SpriteManager:LoadSprite(background, self._p_frame_furniture)

    local lvCfgId = checknumber(itemCfg:UseParam(1))
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())

    g_Game.SpriteManager:LoadSprite(typeCfg:Image(), self._p_icon_furniture)
    self._child_img_select:SetActive(self.data.param:IsRecipeSelected(self.data.processCfg:Id()))

    if canMake and CityProcessUtils.GetCostEnoughTimes(self.data.processCfg) > 0 then
        self._child_reddot_default:ShowRedDot()
    else
        self._child_reddot_default:HideAllRedDot()
    end
end

function CityProcessV2UIFurnitureRecipe:OnClick()
    if self.data.param:IsRecipeSelected(self.data.processCfg:Id()) then return end
    self.data.param:SelectRecipe(self.data.processCfg)
end

return CityProcessV2UIFurnitureRecipe