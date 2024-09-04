--- scene:scene_league_tips_active
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIHelper = require("UIHelper")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceActiveTipMediatorParameter
---@field clickTrans CS.UnityEngine.RectTransform
---@field activeValue number

---@class AllianceActiveTipMediator:BaseUIMediator
---@field new fun():AllianceActiveTipMediator
---@field super BaseUIMediator
local AllianceActiveTipMediator = class('AllianceActiveTipMediator', BaseUIMediator)

function AllianceActiveTipMediator:ctor()
    AllianceActiveTipMediator.super.ctor(self)
    self._clickTrans = nil
end

function AllianceActiveTipMediator:OnCreate()
    self._p_content = self:RectTransform("p_content")
    self._p_icon_active = self:Image("p_icon_active")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_content = self:Text("p_text_content", "alliance_activation_desc5")
    self._p_detail_title = self:GameObject("p_detail_title")
    self._p_text_title = self:Text("p_text_title")
    ---@see AllianceActiveTipCell
    self._p_item_detail = self:LuaBaseComponent("p_item_detail")
    self._p_item_detail:SetVisible(false)
    self._p_items_root = self:RectTransform("p_items_root")
    self._icon_arrow = self:GameObject("icon_arrow")
end

---@param param AllianceActiveTipMediatorParameter
function AllianceActiveTipMediator:OnOpened(param)
    self._p_text_title:SetVisible(false)
    self._clickTrans = param.clickTrans
    local currentLvConfig = AllianceModuleDefine.GetAllianceActiveScoreLevelConfig(param.activeValue)
    g_Game.SpriteManager:LoadSprite(currentLvConfig:Icon(), self._p_icon_active)
    self._p_text_name.text = I18N.Get(currentLvConfig:Name()) .. ("(%s)"):format(param.activeValue)
    self:BuildList()

    self._icon_arrow:SetVisible(not param.hideArrow)
end

function AllianceActiveTipMediator:OnShow()
    self:TipRectFix()
end

function AllianceActiveTipMediator:BuildList()
    self._p_item_detail:SetVisible(true)
    local lastVlaue
    for _, value in ConfigRefer.AllianceActive:inverse_ipairs() do
        ---@type AllianceActiveTipCellData
        local data = {}
        data.icon = value:Icon()
        data.name = I18N.Get(value:Name())
        data.quantity = lastVlaue and (("%s-%s"):format(value:Value(), lastVlaue)) or tostring(value:Value())
        lastVlaue = value:Value()
        local cell = UIHelper.DuplicateUIComponent(self._p_item_detail, self._p_items_root)
        cell:FeedData(data)
    end
    self._p_item_detail:SetVisible(false)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_items_root)
end

function AllianceActiveTipMediator:TipRectFix()
    TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self._clickTrans, self._p_content,3)
end

return AllianceActiveTipMediator