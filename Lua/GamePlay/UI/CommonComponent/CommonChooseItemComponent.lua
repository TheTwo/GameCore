local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')
local CommonChooseHelper = require('CommonChooseHelper')

---@class CommonChooseItemComponent : BaseUIComponent
local CommonChooseItemComponent = class('CommonChooseItemComponent', BaseUIComponent)


function CommonChooseItemComponent:OnCreate()
    self.goContentParent = self:GameObject('')
    self.goTitleStatus = self:GameObject('p_title_status')
    self.textTitleStatus = self:Text('p_text_title_status')
    self.goToggleItem = self:LuaBaseComponent('p_toggle_status')

    g_Game.EventManager:AddListener(EventConst.CHOOSE_TOGGLE_DOT_CLICK, Delegate.GetOrCreate(self, self.OnChooseToggleDotClick))
end

function CommonChooseItemComponent:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.CHOOSE_TOGGLE_DOT_CLICK, Delegate.GetOrCreate(self, self.OnChooseToggleDotClick))
end

---@param param FilterParam
function CommonChooseItemComponent:OnFeedData(param)
    if not param then
        return
    end

    self.filterData = param
    local subFilterData = param.subFilterType
    if #subFilterData <= 0 then
        return
    end
    self.textTitleStatus.text = self.filterData.name
    self.goToggleItem.gameObject:SetActive(false)
    self.toggleCache = {}
    for i = 1, #subFilterData do
        local toggleComp = UIHelper.DuplicateUIComponent(self.goToggleItem, self.goContentParent.transform)
        ---@type CommonChooseToggleItemParam
        local data = {filterType = self.filterData.typeIndex, chooseType = self.filterData.chooseType, subFilterData = subFilterData[i]}
        toggleComp.Lua:OnFeedData(data)
        toggleComp.gameObject:SetActive(true)
        table.insert(self.toggleCache, toggleComp.Lua)
    end
end

function CommonChooseItemComponent:ResetByDefaultFilterCode(filterCode)
    if self.toggleCache and filterCode >= 0 then
        -- local subFilterCode = CommonChooseHelper.GetSubFilterCodeByFilterCode(self.filterData.typeIndex, filterCode)
        for i = 1, #self.toggleCache do
            self.toggleCache[i]:SetSelectState(filterCode & self.toggleCache[i]:GetSubFilterType() > 0)
        end
    end
end

function CommonChooseItemComponent:OnChooseToggleDotClick(filterType, subFilterType)
    if not self.filterData then
        return
    end
    if filterType ~= self.filterData.typeIndex or self.filterData.chooseType ~= CommonChoosePopupDefine.ChooseType.Single then
        return
    end
    if self.toggleCache then
        for i = 1, #self.toggleCache do
            self.toggleCache[i]:SetSelectState(self.toggleCache[i]:GetSubFilterType() == subFilterType)
        end
    end
end

function CommonChooseItemComponent:GetChoosenSubFilterCode()
    local code = 0
    if self.toggleCache then
        for i = 1, #self.toggleCache do
            if self.toggleCache[i]:IsSelected() then
                code = code | (1 << (i - 1))
            end
        end
    end
    return code
end

function CommonChooseItemComponent:GetFilterType()
    if not self.filterData then
        return -1
    end
    return self.filterData.typeIndex
end

return CommonChooseItemComponent