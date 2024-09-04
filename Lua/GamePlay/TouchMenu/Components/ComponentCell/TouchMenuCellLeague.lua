local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')

---@class TouchMenuCellLeague : BaseUIComponent
---@field p_league_logo CommonAllianceLogoComponent
local TouchMenuCellLeague = class("TouchMenuCellLeague", BaseUIComponent)

function TouchMenuCellLeague:OnCreate()
    self.root = self:RectTransform("")
    self.p_logo = self:GameObject("logo")
    self.p_league_logo = self:LuaObject("p_league_logo")
    self.p_text_name = self:Text("p_text_name")
    self.p_button_go = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClicked))
    self.p_league = self:Text('p_text_league','bw_info_base_title_alliance')
end

---@param data TouchMenuCellLeagueDatum
function TouchMenuCellLeague:OnFeedData(data)
    self.data = data
    if self.data.appear > 0 and self.data.pattern > 0 then
        self.p_league_logo:Refresh(self.data.appear, self.data.pattern)
        self.p_logo:SetVisible(true)
        self.p_league:SetVisible(true)
    else
        self.p_logo:SetVisible(false)
        self.p_league:SetVisible(false)
    end
    self.p_text_name.text = self.data.label
    self.p_text_name.color = self.data.labelColor or CS.UnityEngine.Color.white
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.root)
    if data.hideButton then
        self.p_button_go:SetVisible(false)
    else
        self.p_button_go:SetVisible(true)
    end
end

function TouchMenuCellLeague:OnClose()
    self.data = nil
end

function TouchMenuCellLeague:OnGotoClicked()
    if self.data and self.data.clickCallback then
        self.data.clickCallback()
    end
end

return TouchMenuCellLeague