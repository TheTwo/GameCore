local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
---@class GotoItemCell : BaseTableViewProCell
local GotoItemCell = class('GotoItemCell',BaseTableViewProCell)

---@class GotoItemCellData
---@field desc string
---@field gotoIndex number
---@field itemId number
---@field gotoId number
---@field isOpend boolean
---@field lockedDesc string
---@field getMoreCfg GetMoreConfigCell

function GotoItemCell:OnCreate(param)
    self.base = self:GameObject('base')
    self.text = self:Text('p_text')
    self.textWay = self:Text('p_text_way')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
end

---@param data GotoItemCellData
function GotoItemCell:OnFeedData(data)
    self.textWay.text = data.desc
    self.gotoIndex = data.gotoIndex
    self.itemId = data.itemId
    self.getMoreCfg = data.getMoreCfg
    self.btnGoto.gameObject:SetActive(data.gotoId ~= nil and data.gotoId > 0)
    self.btnGoto.interactable = data.isOpend
    self.base:SetActive(data.isOpend)
    if data.isOpend then
        self.text.text = I18N.Get("getmore_go")
        self.textWay.text = data.desc
    else
        self.text.text = I18N.Get("build_unknown")
        self.textWay.text = data.lockedDesc
    end

    self.isActivity = self.getMoreCfg:Goto(self.gotoIndex):GotoActivityLength() > 0
end

function GotoItemCell:OnBtnGotoClicked(args)
    if not self.isActivity then
        g_Game.EventManager:TriggerEvent(EventConst.COMMON_ITEM_DETAILS_GOTO_CLICK, self.itemId, self.gotoIndex)
        self:GetParentBaseUIMediator():CloseSelf()
        require('GuideUtils').GotoItemAccess(self.itemId, self.gotoIndex)
    else
        local gotoActivityId = ModuleRefer.ActivityCenterModule:GetOpeningActivityFromGetMoreCfg(self.getMoreCfg, self.gotoIndex)
        if gotoActivityId > 0 then
            ModuleRefer.ActivityCenterModule:GotoActivity(gotoActivityId)
        end
    end
end

return GotoItemCell
