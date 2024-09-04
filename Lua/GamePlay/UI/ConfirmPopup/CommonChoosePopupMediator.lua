local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')
local UIHelper = require('UIHelper')

---@class CommonChoosePopupMediator : BaseUIMediator
local CommonChoosePopupMediator = class('CommonChoosePopupMediator', BaseUIMediator)

---@class CommonChoosePopupParam
---@field title string
---@field filterType FilterParam[]
---@field confirmCallBack fun()
---@field defaultFilterCode number

---@class FilterParam
---@field name string
---@field typeIndex number
---@field chooseType CommonChoosePopupDefine.ChooseType
---@field subFilterType SubFilterParam[]

---@class SubFilterParam
---@field name string
---@field subTypeIndex number
---@field chooseStyle CommonChoosePopupDefine.ChooseStyle       --选中框样式
---@field color string
---@field isSelect boolean
---@field icon string

---@class ChoosenFilterData
---@field subSelectList number[]


function CommonChoosePopupMediator:OnCreate()
    self.compChildPopupBaseS = self:LuaObject('child_popup_base_s')

    self.goContentParent = self:GameObject('Content')
    self.goChooseItem = self:LuaBaseComponent('p_status')

    self.btnConfirm = self:Button('p_btn_b', Delegate.GetOrCreate(self, self.OnBtnConfirmClick))
    self.textConfirm = self:Text('p_text', 'playerinfo_confirm')
    self.btnReset = self:Button('p_btn_reset', Delegate.GetOrCreate(self, self.OnBtnResetClick))
    self.textReset = self:Text('p_text_reset', 'skincollection_screen_reset')
end

---@param param CommonChoosePopupParam
function CommonChoosePopupMediator:OnOpened(param)
    if not param then
        return
    end
    local baseData = {}
    baseData.title = param.title and param.title or I18N.Get("skincollection_screen")
    self.compChildPopupBaseS:FeedData(baseData)

    if #param.filterType <= 0 then
        return
    end
    
    self.filterCache = {}
    self.goChooseItem.gameObject:SetActive(false)
    for i = 1, #param.filterType do
        local itemComp = UIHelper.DuplicateUIComponent(self.goChooseItem, self.goContentParent.transform)
        itemComp.Lua:OnFeedData(param.filterType[i])
        itemComp.gameObject:SetActive(true)
        table.insert(self.filterCache, itemComp.Lua)
    end
    
    if param.confirmCallBack then
        self.onConfirmCallBack = param.confirmCallBack
    end
    self.defaultFilterCode = param.defaultFilterCode and param.defaultFilterCode or -1
end


function CommonChoosePopupMediator:OnClose(param)
    --TODO
end

function CommonChoosePopupMediator:OnBtnConfirmClick()
    if self.onConfirmCallBack then
        self.onConfirmCallBack(self:GetChoosenFilterData())
    end
    self:CloseSelf()
end

function CommonChoosePopupMediator:OnBtnResetClick()
    if self.filterCache and self.defaultFilterCode >= 0 then
        for i = 1, #self.filterCache do
            self.filterCache[i]:ResetByDefaultFilterCode(self.defaultFilterCode)
        end
    end
end

---@return table<number, number>, number filterTypeIndex, number subFilterCode
function CommonChoosePopupMediator:GetChoosenFilterData()
    local data = {}
    if self.filterCache then
        for i = 1, #self.filterCache do
            data[self.filterCache[i]:GetFilterType()] = self.filterCache[i]:GetChoosenSubFilterCode()
        end
    end
    return data
end


return CommonChoosePopupMediator