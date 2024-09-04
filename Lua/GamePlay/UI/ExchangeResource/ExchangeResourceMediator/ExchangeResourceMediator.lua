---scene: scene_getmore_popup_resources
local BaseUIMediator = require('BaseUIMediator')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local EventConst = require('EventConst')
local ExchangeResourceStatic = require('ExchangeResourceStatic')
local DoNotShowAgainHelper = require('DoNotShowAgainHelper')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require('UIMediatorNames')
local Utils = require('Utils')
local PetCollectionEnum = require("PetCollectionEnum")

---@class ExchangeResourceMediator : BaseUIMediator
local ExchangeResourceMediator = class('ExchangeResourceMediator', BaseUIMediator)

---@class ExchangeResourceMediatorItemInfo
---@field id number
---@field num number

---@class ExchangeResourceMediatorParam
---@field itemInfos ExchangeResourceMediatorItemInfo[]
---@field selectItemId number
---@field isFromHUD boolean

function ExchangeResourceMediator:ctor()
    self.itemInfos = {}
    self.isFromHUD = false
    self.selectItemId = 0
    self.neededNum = {}
    self.directExchangeList = {}

    self.price = 0
    self.exchangeCount = 0
    self.exchangeCurrency = 0
end

function ExchangeResourceMediator:OnCreate()
    self.compChildPopupBaseM = self:LuaBaseComponent('child_popup_base_m')
    self.textDetail = self:Text('p_text_detail', I18N.Get("getmore_text_02"))
    self.textNum = self:Text('p_text_num')
    self.imgIconResource = self:Image('p_icon_resource')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.goChildCompB = self:GameObject('child_comp_btn_b')
    self.tableviewproTableResources = self:TableViewPro('p_table_resources')
    self.tableviewproTableWay = self:TableViewPro('p_table_way')

    self.goProgressBar = self:GameObject('p_progressbar')
    self.sliderProgress = self:Slider('p_progress')
    self.goProgressIconBase = self:GameObject('p_btn_base')
    self.imgProgressIcon = self:Image('p_icon_base')
    self.textProgress = self:Text('p_text_time')
    ---@see ExchangeResourceGiftComponet
    self.luaGift = self:LuaObject("p_group_gift")

    self.btnSupplyAll = self:Button('p_btn_all', Delegate.GetOrCreate(self, self.OnSupplyAllClick))
    self.textBtnSupplyAll = self:Text('p_text', 'btn_getmore_all')
    self.p_group_base = self:GameObject("p_group_base")
    self.p_text_base = self:Text("p_text_base")
    self.p_text_base_1 = self:Text("p_text_base_1")
    self.p_btn_base_goto = self:Button("p_btn_base_goto", Delegate.GetOrCreate(self, self.OnClickGotoBase))
end

---@param param ExchangeResourceMediatorParam | ExchangeResourceMediatorItemInfo[]
function ExchangeResourceMediator:OnShow(param)
    self.itemInfos = param.itemInfos or param
    self.isFromHUD = param.isFromHUD
    self.selectItemId = param.selectItemId
    if not self.itemInfos then
        return
    end
    self.goProgressBar:SetActive(not self.isFromHUD)
    self.compChildPopupBaseM:FeedData({title = I18N.Get("backpack_item_getmore")})
    self:Refresh(self.itemInfos)
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshByItemChange))
    g_Game.EventManager:AddListener(EventConst.EXCHANGE_RESOURCE_SELECT_ITEM, Delegate.GetOrCreate(self, self.OnSelectItem))
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.RefreshByItemChange))
    g_Game.ServiceManager:AddResponseCallback(ExchangeMultiItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnExchange))
end

function ExchangeResourceMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshByItemChange))
    g_Game.EventManager:RemoveListener(EventConst.EXCHANGE_RESOURCE_SELECT_ITEM, Delegate.GetOrCreate(self, self.OnSelectItem))
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.RefreshByItemChange))
    g_Game.ServiceManager:RemoveResponseCallback(ExchangeMultiItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnExchange))
end

function ExchangeResourceMediator:RefreshByItemChange()
    self:Refresh(self.itemInfos)
end

---@param itemInfos ExchangeResourceMediatorItemInfo[]
function ExchangeResourceMediator:Refresh(itemInfos)
    self.tableviewproTableResources:Clear()
    if #itemInfos > 1 and not itemInfos[1].isPet then
        for _, itemInfo in ipairs(itemInfos) do
            self.tableviewproTableResources:AppendData(itemInfo, 0)
        end
        self.tableviewproTableResources:SetToggleSelectIndex(0)
    elseif itemInfos[1].isPet then
        for _, itemInfo in ipairs(itemInfos) do
            self.tableviewproTableResources:AppendData(itemInfo, 2)
        end
        self.tableviewproTableResources:SetToggleSelectIndex(0)
    else
        self:OnSelectItem(itemInfos[1])
    end
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:RefreshProgressBar(itemInfo)
    if itemInfo.isPet then
        self.goProgressBar:SetVisible(false)
    end
    local curNum = ModuleRefer.InventoryModule:GetAmountByConfigId(itemInfo.id)
    local neededNum = itemInfo.num + curNum
    if not self.neededNum[itemInfo.id] then
        self.neededNum[itemInfo.id] = neededNum
    end
    self.sliderProgress.value = curNum / self.neededNum[itemInfo.id]
    self.textProgress.text = string.format("%d/%d", curNum, self.neededNum[itemInfo.id])
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(itemInfo.id):Icon(), self.imgProgressIcon)
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:RefreshRightContent(itemInfo)
    self.tableviewproTableWay:Clear()
    self.luaGift:SetVisible(false)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    local exchangeCfg = getMoreCfg:Exchange()
    local city = ModuleRefer.CityModule.myCity
    if city:IsResAutoGenStock(itemInfo.id) then
        self:AppendHarvestCell(itemInfo)
    end
    if not self.isFromHUD then
        self:AppendOneKeySupplyCell(itemInfo)
    end
    if exchangeCfg and exchangeCfg:Currency() > 0 then
        self:AppendPayCell(itemInfo)
        self.price = exchangeCfg:CurrencyCount()
        self.exchangeCount = exchangeCfg:Count()
        self.exchangeCurrency = exchangeCfg:Currency()
    end
    self:AppendUsingItemCell(itemInfo)
    self:AppendTitleCell(itemInfo)
    self:AppendGotoCell(itemInfo)
    self:AppendPayAndUseCell(itemInfo)
    self:ShowGiftPart(itemInfo)

    if itemInfo.isPet then
        self.btnSupplyAll.gameObject:SetActive(false)
    else
        self.btnSupplyAll.gameObject:SetActive(getMoreCfg:SupplyItemLength() > 0 and not self.isFromHUD)
    end
end

function ExchangeResourceMediator:ShowGiftPart(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return end
    local pGroupId = getMoreCfg:RefPayGoods(1)
    if not ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(pGroupId) or
    not ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(pGroupId) or
    (itemInfo.isPet and itemInfo.status == PetCollectionEnum.PetStatus.Lock) then
        self.luaGift:SetVisible(false)
        return
    end

    self.luaGift:SetVisible(true)
    self.luaGift:FeedData(pGroupId)
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendTitleCell(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    ---@type TitleItemCellData
    local data = {}
    if itemInfo.isPet and itemInfo.status == PetCollectionEnum.PetStatus.Lock then
        self:ShowPetGotoBaseText(itemInfo.petTypeId)
        data.itemName = I18N.Get("? ? ?")
    else
        data.itemName = I18N.Get(itemCfg:NameKey())
        self.p_group_base:SetVisible(false)
        self.tableviewproTableWay:SetVisible(true)
    end
    data.itemNum = itemInfo.num
    data.hideNum = self.isFromHUD
    self.tableviewproTableWay:AppendData(data, 0)
end

---@param itemInfo ExchangeResourceMediatorItemInfo
---@param type number
function ExchangeResourceMediator:AppendFunctionCell(itemInfo, type)
    ---@type ItemUseOrPayCellData
    local data = {}
    data.type = type
    data.info = itemInfo
    data.isFromHUD = self.isFromHUD
    self.tableviewproTableWay:AppendData(data, 2)
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendUsingItemCell(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return end
    for i = 1, getMoreCfg:SupplyItemLength() do
        local id = getMoreCfg:SupplyItem(i)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(id) > 0 then
            local num = itemInfo.num
            local data = {id = id, num = num}
            self:AppendFunctionCell(data, ExchangeResourceStatic.CellType.Supply)
        end
    end
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendPayCell(itemInfo)
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendPayAndUseCell(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return end
    for i = 1, getMoreCfg:SupplyItemLength() do
        local id = getMoreCfg:SupplyItem(i)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(id) <= 0 then
            local num = itemInfo.num
            local data = {id = id, num = num}
            self:AppendFunctionCell(data, ExchangeResourceStatic.CellType.PayAndUse)
        end
    end
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendOneKeySupplyCell(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    if not getMoreCfg then return end
    local has = false
    for i = 1, getMoreCfg:SupplyItemLength() do
        local id = getMoreCfg:SupplyItem(i)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(id) > 0 then
            has = true
            break
        end
    end
    if has then
        self:AppendFunctionCell(itemInfo, ExchangeResourceStatic.CellType.OneKeySupply)
    end
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendHarvestCell(itemInfo)
    self:AppendFunctionCell(itemInfo, ExchangeResourceStatic.CellType.Harvest)
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:AppendGotoCell(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
    local gotoList = {}
    for i = 1, getMoreCfg:GotoLength() do
        local sysEntry = getMoreCfg:Goto(i):UnlockSystem()
        local isOpend = true
        if sysEntry > 0 then
            isOpend = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysEntry)
        end
        if isOpend then
            gotoList[#gotoList + 1] = {index = i, isOpend = isOpend}
        end
    end
    table.sort(gotoList, function(a, b)
        if a.isOpend ~= b.isOpend then
            return a.isOpend
        else
            return a.index < b.index
        end
    end)
    for _, info in ipairs(gotoList) do
        ---@type GotoItemCellData
        local data = {}
        data.gotoIndex = info.index
        data.itemId = itemInfo.id
        data.isOpend = info.isOpend
        data.gotoId = getMoreCfg:Goto(info.index):Goto()
        data.desc = I18N.Get(getMoreCfg:Goto(info.index):Desc())
        data.lockedDesc = I18N.Get(getMoreCfg:Goto(info.index):UnlockText())
        data.getMoreCfg = getMoreCfg
        local hideTask = getMoreCfg:Goto(info.index):HideTask()
        local hide = hideTask > 0 and ModuleRefer.QuestModule:GetQuestFinishedState(hideTask) >= wds.TaskState.TaskStateFinished
        local hideLock = Utils.IsNullOrEmpty(data.lockedDesc)
        if not hide or not hideLock then
            self.tableviewproTableWay:AppendData(data, 1)
        end
    end
end

function ExchangeResourceMediator:OnClickBtn()
    local parameter = ExchangeMultiItemParameter.new()
    for _, item in ipairs(self.directExchangeList) do
        parameter.args.TargetItemConfigId:Add(item.id)
        parameter.args.TargetItemCount:Add(item.num)
    end
    parameter:Send()
end

---@param itemInfo ExchangeResourceMediatorItemInfo
function ExchangeResourceMediator:OnSelectItem(itemInfo)
    self:RefreshProgressBar(itemInfo)
    self:RefreshRightContent(itemInfo)
    self.selectItemId = itemInfo.id
end

function ExchangeResourceMediator:OnExchange(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    local request = rpc.request
    local exchangeItems = request.TargetItemConfigId
    local exchangeValues = request.TargetItemCount
    local list = {}
    for index, exchangeItemId in ipairs(exchangeItems) do
        local originValue = self:GetOriginValue(exchangeItemId)
        if originValue and originValue > 0 then
            local lastValue = originValue - exchangeValues[index]
            list[exchangeItemId] = lastValue
        end
    end
    local result = {}
    for _, item in ipairs(self.itemInfos) do
        if item.num and item.num > 0 then
            if list[item.id] then
                if list[item.id] > 0 then
                    result[#result + 1] = {id = item.id, num = list[item.id]}
                end
            else
                result[#result + 1] = item
            end
        else
            result[#result + 1] = {id = item.id, num = 0}
        end
    end
    if #result > 0 then
        self:Refresh(result, true)
    else
        self:CloseSelf()
    end
end

function ExchangeResourceMediator:OnSupplyAllClick()
    local neededNum = self.neededNum[self.selectItemId] - ModuleRefer.InventoryModule:GetAmountByConfigId(self.selectItemId)
    local neededCurrency = math.ceil(neededNum / self.exchangeCount) * self.price
    local shouldDoubleCheck = DoNotShowAgainHelper.CanShowAgain("SupplyAll", DoNotShowAgainHelper.Cycle.Daily)
    local currencyCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.exchangeCurrency)
    if shouldDoubleCheck and neededCurrency <= currencyCount then
        ---@type CommonConfirmPopupMediatorParameter
        local data = {}
        data.title = I18N.Get("btn_getmore_all")
        data.content = I18N.GetWithParams("popup_getmore_all_desc", neededCurrency)
        data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn | CommonConfirmPopupMediatorDefine.Style.Toggle
        data.toggleDescribe = I18N.Get("alliance_battle_confirm2")
        data.toggleClick = function(_, check)
            if check then
                DoNotShowAgainHelper.SetDoNotShowAgain("SupplyAll")
                return true
            else
                DoNotShowAgainHelper.RemoveDoNotShowAgain("SupplyAll")
                return false
            end
        end
        data.onConfirm = function()
            if currencyCount < neededCurrency then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("getmore_text_04"))
                return true
            end
            self:SupplyAll()
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
    else
        self:SupplyAll()
    end
end

function ExchangeResourceMediator:SupplyAll()
    local neededNum = self.neededNum[self.selectItemId] - ModuleRefer.InventoryModule:GetAmountByConfigId(self.selectItemId)
    local neededCurrency = math.ceil(neededNum / self.exchangeCount) * self.price
    neededNum = math.ceil(neededNum / self.exchangeCount) * self.exchangeCount
    local currencyCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.exchangeCurrency)
    if currencyCount < neededCurrency then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("getmore_text_04"))
        return
    end
    local parameter = ExchangeMultiItemParameter.new()
    parameter.args.TargetItemConfigId:Add(self.selectItemId)
    parameter.args.TargetItemCount:Add(neededNum)
    parameter:Send()
end

function ExchangeResourceMediator:GetOriginValue(itemId)
    for _, item in ipairs(self.itemInfos) do
        if item.id == itemId then
            return item.num
        end
    end
end

function ExchangeResourceMediator:ShowPetGotoBaseText(petTypeId)
    self.p_group_base:SetVisible(true)
    self.tableviewproTableWay:SetVisible(false)
    local petTypeCfg = ConfigRefer.PetType:Find(petTypeId)
    local level = ConfigRefer.PetResearch:Find(petTypeCfg:PetResearchId()):UnlockCondMainCityLevel()
    local furniture = ConfigRefer.CityFurnitureTypes:Find(ConfigRefer.CityConfig:MainFurnitureType())
    local name = I18N.Get(furniture:Name())
    local icon = I18N.Get(furniture:Image())
    -- g_Game.SpriteManager:LoadSprite(icon, self.img_city)
    self.p_text_base.text = I18N.GetWithParams("petguide_unlock_tip01", name, level)
    self.p_text_base_1.text = I18N.GetWithParams("petguide_unlock_tip02", name)
end

function ExchangeResourceMediator:OnClickGotoBase()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        self:CloseSelf()
        ModuleRefer.GuideModule:CallGuide(1001)
    else
        self:CloseSelf()
        scene:ReturnMyCity(function()
            ModuleRefer.GuideModule:CallGuide(1001)
        end)
    end
end

return ExchangeResourceMediator