local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityPath = require("DBEntityPath")
local NpcServiceObjectType = require("NpcServiceObjectType")

---@class StoryPopupTradeMediatorParameter
---@field cityElementTid number
---@field serviceId number
---@field objectType number @NpcServiceObjectType
---@field objectId number

---@class StoryPopupTradeMediator : BaseUIMediator
local StoryPopupTradeMediator = class('StoryPopupTradeMediator', BaseUIMediator)

function StoryPopupTradeMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_m')
    self.textHint = self:Text('p_text_hint', I18N.Get("npc_give_item_des"))
    self.tableviewproTableItem = self:TableViewPro('p_table_item')
    self.goGroupDetail = self:GameObject('p_group_detail')
    self.textGive = self:Text('p_text_give', I18N.Get("npc_give_item_title"))
    self.inputfieldInputBoxClick = self:InputField('p_input_box_click', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.textInputQuantity = self:Text('p_text_input_quantity')
    self.compChildSetBar = self:LuaBaseComponent('child_set_bar')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.goGroupFinish = self:GameObject('p_group_finish')
    self.textFinish = self:Text('p_text_finish', I18N.Get("npc_give_item_complete"))
    g_Game.EventManager:AddListener(EventConst.ON_SELECT_TRADE_COST_CELL, Delegate.GetOrCreate(self, self.SetSelectId))
end

---@param param StoryPopupTradeMediatorParameter
function StoryPopupTradeMediator:OnOpened(param)
    if not param then
        return
    end
    self.needSubmitAll = 0
    self.serviceId = param.serviceId
    self.objectType = param.objectType or NpcServiceObjectType.CityElement
    self.objectId = param.cityElementTid or param.objectId
    self.compChildPopupBaseM:FeedData({title = I18N.Get("npc_give_item_title")})
    self:RefreshItems()
    ModuleRefer.PlayerServiceModule:AddServicesChanged(self.objectType, Delegate.GetOrCreate(self, self.RefreshItems))
end

function StoryPopupTradeMediator:GetServicesInfo()
    return ModuleRefer.StoryPopupTradeModule:GetServicesInfo(self.objectType, self.serviceId, self.serviceId)
end

function StoryPopupTradeMediator:GetNeedCount(itemId)
    return ModuleRefer.StoryPopupTradeModule:GetNeedCount(self.serviceId, itemId)
end

function StoryPopupTradeMediator:RefreshItems()
    if ModuleRefer.StoryPopupTradeModule:CheckServiceFinished(self.objectType, self.serviceId, self.serviceId) then
       -- self:CloseSelf()
        return
    end
    local curItemInfos = self:GetServicesInfo()
    local itemIds = ModuleRefer.StoryPopupTradeModule:GetNeedItems(self.serviceId)
    self.tableviewproTableItem:Clear()
    for _, item in ipairs(itemIds) do
        self.tableviewproTableItem:AppendData(item.id)
    end
    self.tableviewproTableItem:RefreshAllShownItem(false)
    local isSubmitAll = false
    if self.selectId then
        local submitCount = curItemInfos[self.selectId] or 0
        local needCount = self:GetNeedCount(self.selectId)
        isSubmitAll = submitCount >= needCount
    end
    if self.selectId and not isSubmitAll then
        self:SetSelectId(self.selectId)
    else
        self.selectId = itemIds[1].id
        self.needSubmitAll = 0
        for _, item in ipairs(itemIds) do
            local submitCount = curItemInfos[item.id] or 0
            local needCount = self:GetNeedCount(item.id)
            local curHaveNum = ModuleRefer.InventoryModule:GetAmountByConfigId(item.id)
            if submitCount < needCount then
                self.needSubmitAll = self.needSubmitAll + 1
                if curHaveNum >= (needCount - submitCount) then
                    if not self.selectId then
                        self.selectId = item.id
                    end
                end
            end
        end
        self:SetSelectId(self.selectId)
    end
end

function StoryPopupTradeMediator:SetSelectId(selectId)
    self.selectId = selectId
    self.tableviewproTableItem:SetToggleSelect(selectId)
    self:RefreshItemDetails()
end

function StoryPopupTradeMediator:RefreshItemDetails()
    self.lackList = {}
    local curItemInfos = self:GetServicesInfo()
    local submitCount = curItemInfos[self.selectId] or 0
    local needCount = self:GetNeedCount(self.selectId)
    local isSubmitAll = submitCount >= needCount
    self.goGroupDetail:SetActive(not isSubmitAll)
    self.goGroupFinish:SetActive(isSubmitAll)
    self.compChildCompB:SetVisible(not isSubmitAll)
    if not isSubmitAll then
        local haveNum = ModuleRefer.InventoryModule:GetAmountByConfigId(self.selectId)
        local needSubmit = needCount - submitCount
        self.textInputQuantity.text = "/" .. needSubmit
        local maxCount = math.min(haveNum, needSubmit)
        self.inputfieldInputBoxClick.text = maxCount
        local setBarData = {}
        setBarData.minNum = 0
        setBarData.maxNum = needSubmit
        setBarData.oneStepNum = 1
        setBarData.curNum = maxCount
        setBarData.intervalTime = 0.1
        setBarData.ignoreNum = 0
        setBarData.limitNum = haveNum
        setBarData.callBack = function(value)
            self:OnEndEdit(value)
        end
        self.compChildSetBar:FeedData(setBarData)
        local buttonParamStartWork = {}
        buttonParamStartWork.onClick = Delegate.GetOrCreate(self, self.OnBtnCompALU2EditorClicked)
        buttonParamStartWork.disableClick = Delegate.GetOrCreate(self, self.OnBtnCompDisableClicked)
        buttonParamStartWork.buttonText =  I18N.Get("npc_give_item_button")

        self.compChildCompB:OnFeedData(buttonParamStartWork)
        self.compChildCompB:SetEnabled(maxCount > 0)
        if maxCount == 0 then
            self.lackList[#self.lackList + 1] = {id = self.selectId}
        end
    end
end

function StoryPopupTradeMediator:OnBtnCompDisableClicked()
    ModuleRefer.InventoryModule:OpenExchangePanel(self.lackList)
end

function StoryPopupTradeMediator:OnBtnCompALU2EditorClicked()
    local submitNum = tonumber(self.inputfieldInputBoxClick.text)
    local curItemInfos = self:GetServicesInfo()
    local submitCount = curItemInfos[self.selectId] or 0
    local needCount = self:GetNeedCount(self.selectId)
    if submitNum == needCount - submitCount then
        self.needSubmitAll = self.needSubmitAll - 1
    end
    ModuleRefer.PlayerServiceModule:RequestNpcService(nil, self.objectType, self.objectId, self.serviceId, {
        [self.selectId] = submitNum
    })
    if self.needSubmitAll == 0 then
        self:CloseSelf()
    end
end

function StoryPopupTradeMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.ON_SELECT_TRADE_COST_CELL, Delegate.GetOrCreate(self, self.SetSelectId))
    if self.objectType then
        ModuleRefer.PlayerServiceModule:RemoveServicesChanged(self.objectType, Delegate.GetOrCreate(self, self.RefreshItems))
    end
    self.objectType = nil
end

function StoryPopupTradeMediator:OnEndEdit(inputText)
    self.lackList = {}
    local inputNum = tonumber(inputText)
    if not inputNum or inputNum < 0 then
        inputNum = 0
    end
    local curItemInfos = self:GetServicesInfo()
    local submitCount = curItemInfos[self.selectId] or 0
    local needCount = self:GetNeedCount(self.selectId)
    local haveNum = ModuleRefer.InventoryModule:GetAmountByConfigId(self.selectId)
    local needSubmit = needCount - submitCount
    if inputNum > needSubmit then
        inputNum = needSubmit
    end
    if inputNum > haveNum then
        inputNum = haveNum
    end
    self.inputfieldInputBoxClick.text = inputNum
    self.compChildSetBar.Lua:OutInputChangeSliderValue(inputNum)
    self.compChildCompB:SetEnabled(inputNum > 0 and inputNum <= haveNum)
    if inputNum == 0 then
        self.lackList[#self.lackList + 1] = {id = self.selectId}
    end
end

return StoryPopupTradeMediator

