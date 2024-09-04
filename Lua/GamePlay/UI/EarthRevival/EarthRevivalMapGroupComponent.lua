local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class EarthRevivalMapGroupComponent : BaseUIComponent
local EarthRevivalMapGroupComponent = class('EarthRevivalMapGroupComponent', BaseUIComponent)

function EarthRevivalMapGroupComponent:OnCreate()
    self.btnTimeLineTab = self:Button('p_btn_tab_timeline', Delegate.GetOrCreate(self, self.OnClickTimeLineTab))
    self.goSelectTimeLineTab = self:GameObject('p_img_select_timeline')
    self.goTimeLine = self:GameObject('p_timeline')
    self.luagoTimeLine = self:LuaObject('p_timeline')

    self.btnMapTab = self:Button('p_btn_tab_map', Delegate.GetOrCreate(self, self.OnClickMapTab))
    self.goSelectMapTab = self:GameObject('p_img_select_map')
    self.goMap = self:GameObject('p_map')
    self.luagoMap = self:LuaObject('p_map')
    self.statusMapBtn = self:StatusRecordParent('p_btn_tab_map')
end

function EarthRevivalMapGroupComponent:OnFeedData(defaultStage)
    self.mapUnlock = ModuleRefer.EarthRevivalModule:CheckSandBoxMapUnlock()
    self.statusMapBtn:ApplyStatusRecord(self.mapUnlock and 0 or 1)
    self:OnClickTimeLineTab(defaultStage)
end

function EarthRevivalMapGroupComponent:OnClickTimeLineTab(defaultStage)
    self.goSelectTimeLineTab:SetActive(true)
    self.goSelectMapTab:SetActive(false)
    self.luagoTimeLine:SetVisible(true)
    self.luagoMap:SetVisible(false)
    self.luagoTimeLine:FeedData(defaultStage)
end

function EarthRevivalMapGroupComponent:OnClickMapTab()
    if not self.mapUnlock then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("WorldStage_shapanjs", ConfigRefer.ConstMain:EarthRevivalMapUnlockStage()))
        return
    end
    self.goSelectTimeLineTab:SetActive(false)
    self.goSelectMapTab:SetActive(true)
    self.luagoTimeLine:SetVisible(false)
    self.luagoMap:SetVisible(true)
    self.luagoMap:FeedData()
end

return EarthRevivalMapGroupComponent