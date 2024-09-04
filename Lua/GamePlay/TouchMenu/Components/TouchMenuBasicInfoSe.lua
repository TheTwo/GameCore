local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local Utils = require("Utils")

local I18N = require("I18N")

---@class TouchMenuBasicInfoSe:BaseUIComponent
local TouchMenuBasicInfoSe = class('TouchMenuBasicInfoSe', BaseUIComponent)

function TouchMenuBasicInfoSe:OnCreate()
    self._head = self:GameObject("head")
    self._p_img_head = self:Image("p_img_head")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_detail = self:Text("p_text_detail_se")
    self._p_text_position = self:Text("p_text_position")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))
end

---@param data TouchMenuBasicInfoDatumSe
function TouchMenuBasicInfoSe:OnFeedData(data)
    self.data = data
    local showHeader = not string.IsNullOrEmpty(data.image)
    self._head:SetActive(showHeader)
    if showHeader then
        g_Game.SpriteManager:LoadSprite(data.image, self._p_img_head)
    end
    self._p_text_name.text = I18N.Get(data.name)

    local showDesc = not string.IsNullOrEmpty(data.desc)
    self._p_text_detail:SetVisible(showDesc)
    if showDesc then
        self._p_text_detail.text = I18N.Get(data.desc)
    end

    local showCoord = data.coord ~= nil
    self._p_text_position:SetVisible(showCoord)
    if showCoord then
        self._p_text_position.text = string.format("X:%d Y:%d", data.coord.x, data.coord.y)
    end
    
    self._p_btn_detail:SetVisible(data.detailClick ~= nil)
end

function TouchMenuBasicInfoSe:OnClickDetails()
    self.data.detailClick()
end

function TouchMenuBasicInfoSe:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, Delegate.GetOrCreate(self, self.OnOverlapDetailPanelShow))
    g_Game.EventManager:AddListener(EventConst.TOUCH_MENU_HIDE_OVERLAP_DETAIL_PAENL, Delegate.GetOrCreate(self, self.OnOverlayDetailPanelHide))
end

function TouchMenuBasicInfoSe:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_SHOW_OVERLAP_DETAIL_PAENL, Delegate.GetOrCreate(self, self.OnOverlapDetailPanelShow))
    g_Game.EventManager:RemoveListener(EventConst.TOUCH_MENU_HIDE_OVERLAP_DETAIL_PAENL, Delegate.GetOrCreate(self, self.OnOverlayDetailPanelHide))
end

function TouchMenuBasicInfoSe:OnOverlapDetailPanelShow()
    if Utils.IsNotNull(self._p_img_head) then
        self._p_img_head:SetVisible(false)
    end
end

function TouchMenuBasicInfoSe:OnOverlayDetailPanelHide()
    if Utils.IsNotNull(self._p_img_head) then
        local showHeader = self.data and not string.IsNullOrEmpty(self.data.image)
        self._p_img_head:SetVisible(showHeader)
    end
end

return TouchMenuBasicInfoSe
