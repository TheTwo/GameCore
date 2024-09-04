local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AdornmentType = require('AdornmentType')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local PersonaliseDefine = require('PersonaliseDefine')
local AdornmentQuality = require('AdornmentQuality')
local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')
local WearAdornmentParameter = require('WearAdornmentParameter')
local ConvertPieceToAdornmentParameter = require('ConvertPieceToAdornmentParameter')
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')
local CommonChooseHelper = require('CommonChooseHelper')
local TimerUtility = require('TimerUtility')
local Utils = require('Utils')
local CityFurnitureTypeNames = require('CityFurnitureTypeNames')


---@class PersonaliseChangeParam
---@field typeIndex number
---@field defaultChoosonItemID number


---@class PersonaliseChangeMediator : BaseUIMediator
local PersonaliseChangeMediator = class('PersonaliseChangeMediator', BaseUIMediator)


function PersonaliseChangeMediator:OnCreate()
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')

    --groupLeft
    self.tableproviewType = self:TableViewPro('p_table_type')
    self.tableproviewItem = self:TableViewPro('p_table_item')
    self.tableproviewTitle = self:TableViewPro('p_table_name')
    self.btnFilterCondition = self:Button('p_btn_screen', Delegate.GetOrCreate(self, self.OnClickFilterCondition))
    self.textFilter = self:Text('p_text_screen', 'skincollection_screen')
    self.textSchedule = self:Text('p_text_number')

    self.goBaseContent = self:GameObject('base_content')

    --headFrame
    self.goHeadFrame = self:GameObject('p_head')
    ---@type PlayerInfoComponent
    self.luaGoPlayerHead = self:LuaObject('child_ui_head_player')

    --castleSkin
    self.goCastleSkin = self:GameObject('p_city')
    self.imgCastleBase = self:Image('p_base_city')
    self.imgCastle = self:Image('p_img_city')
    self.textCastleSkinName = self:Text('p_text_city')
    self.goCastleSkinChildPading = self:GameObject('child_pading')
    -- self.animCastleSkinChildPading = self:AnimTrigger('child_pading')
    self.btnLeft = self:Button('p_btn_left', Delegate.GetOrCreate(self, self.OnBtnChangeKingdomCastleType))
    self.goSelectLeft = self:GameObject('p_select_left')
    self.btnRight = self:Button('p_btn_right', Delegate.GetOrCreate(self, self.OnBtnChangeCityCastleType))
    self.goSelectRight = self:GameObject('p_select_right')

    --title
    self.goTitle = self:GameObject('p_btn_name')
    self.imgTitleCastleBase = self:Image('img_city')
    self.imgTitleCastle = self:Image('p_img_city_name')
    self.luagoTitle = self:LuaObject('p_personalise_title')
    self.textLv = self:Text('p_text_lvl')
    self.textCityName = self:Text('p_text_city_name')

    --contentRight
    self.goContentRight = self:GameObject('content_right')
    self.textQuality = self:Text('p_text_quality')
    self.textName = self:Text('p_text_name_item')
    self.textDesc = self:Text('p_text_description')
    self.goPropertyParent = self:GameObject('p_property_vertical')
    self.textPropertyTitle = self:Text('p_text_title_property', 'skincollection_attrbonus')
    self.goPropertyItem = self:LuaBaseComponent('p_property')
    self.textTimeLimitTitle = self:Text('p_text_title_time', 'skincollection_remainder')
    self.textTimeLimitStatus = self:Text('p_text_time_status')
    self.textTimeScoreReward = self:Text('p_text_time')
    self.goChildTime = self:GameObject('child_time')
    self.childTime = self:LuaObject('child_time')
    self.btnAddMore = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnClickAddMore))
    self.btnUse = self:Button('p_btn_use', Delegate.GetOrCreate(self, self.OnClickUse))
    self.textUse = self:Text('p_text_use', 'skincollection_obtain')
    self.btnChange = self:Button('p_btn_change', Delegate.GetOrCreate(self, self.OnClickChange))
    self.textChange = self:Text('p_text_change', 'skincollection_changeadornment')
    self.goBtnUnbale = self:GameObject('p_btn_d')
    self.textChangeUnable = self:Text('p_text', 'skincollection_changeadornment')
    self.btnUnlock = self:Button('p_btn_unlock', Delegate.GetOrCreate(self, self.OnClickUnlock))
    self.textUnlock = self:Text('p_text_unlock', 'skincollection_unlockwithitem')
end

-- function PersonaliseChangeMediator:OnAllVxObjectLoaded()
-- end

---@param param PersonaliseChangeParam
function PersonaliseChangeMediator:OnOpened(param)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("skincollection_changeadornment"),
        onClose = Delegate.GetOrCreate(self, self.OnBackBtnClick)
    })
    self.defaultFilterCode = -1
    self.curFilterCode = -1
    self.hasFilter = false
    self.attrCache = {}
    self.defaultChoosonItemID = -1
    self:InitType(param)
    ModuleRefer.PersonaliseModule:RefreshRedPoint()
    self.animCastleSkinChildPading = self:AnimTrigger('child_pading')
end


function PersonaliseChangeMediator:OnClose(param)
    self:ClearAttrCache()
    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
end

---@param param PersonaliseChangeParam
function PersonaliseChangeMediator:InitType(param)
    local defaultTypeIndex = param.typeIndex and param.typeIndex or 1
    local defaultChoosonItemID = param.defaultChoosonItemID and param.defaultChoosonItemID or -1
    self.tableproviewType:Clear()
    local typeList = ModuleRefer.PersonaliseModule:GetTypeList()
    for i = 1, #typeList do
        if typeList[i]:IsShow() then
            self.tableproviewType:AppendData(typeList[i]:Id())
        end
    end
    self:OnClickChangeType(defaultTypeIndex, defaultChoosonItemID)
end

function PersonaliseChangeMediator:ShowTypeChoosenItem(typeIndex)
    self.selectType = typeIndex
    if typeIndex == AdornmentType.CastleSkin then
        self.goCastleSkin:SetActive(true)
        self.goHeadFrame:SetActive(false)
        self.goTitle:SetActive(false)
        self.goBaseContent:SetActive(false)
    elseif typeIndex == AdornmentType.PortraitFrame then
        self.goCastleSkin:SetActive(false)
        self.goHeadFrame:SetActive(true)
        self.goTitle:SetActive(false)
        self.goBaseContent:SetActive(true)
    elseif typeIndex == AdornmentType.Titles then
        self.goCastleSkin:SetActive(false)
        self.goHeadFrame:SetActive(false)
        self.goTitle:SetActive(true)
        self.goBaseContent:SetActive(false)
    end
end

function PersonaliseChangeMediator:InitTypeItem(filterData)
    local needFilter =  false
    if type(filterData) == "table" then
        needFilter = filterData and true or false
    elseif type(filterData) == "number" then
        needFilter = filterData and filterData > 0 and true or false
    end
    self.tableproviewItem:Clear()
    self.tableproviewTitle:Clear()
    self.ItemDataList = {}
    local itemList = ModuleRefer.PersonaliseModule:GetItemListByType(self.selectType, true)
    self:CheckFilterStatus(filterData)
    if needFilter then
        itemList = CommonChooseHelper.GetItemListWithFilterData(itemList, filterData)
    end
    for i = 1, #itemList do
        if self.selectType == AdornmentType.Titles then
            self.tableproviewItem.gameObject:SetActive(false)
            self.tableproviewTitle.gameObject:SetActive(true)
            table.insert(self.ItemDataList, itemList[i]:Id())
            self.tableproviewTitle:AppendData(itemList[i]:Id())
        else
            self.tableproviewItem.gameObject:SetActive(true)
            self.tableproviewTitle.gameObject:SetActive(false)
            table.insert(self.ItemDataList, itemList[i]:Id())
            self.tableproviewItem:AppendData(itemList[i]:Id())
        end
    end
    if #itemList == 0 then
        self:SelectNullItem()
        return
    end
    local usingData = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(self.selectType)
    if usingData then
        if self.defaultChoosonItemID > 0 then
            self:OnSelectItem(self.defaultChoosonItemID)
        else
            self:OnSelectItem(usingData.ConfigID)
        end
        self.curUsingItemID = usingData.ConfigID
    else
        --若无可用皮肤，则默认选中第一个
        if self.defaultChoosonItemID > 0 then
            self:OnSelectItem(self.defaultChoosonItemID)
        else
            self:OnSelectItem(itemList[1]:Id())
        end
        self.curUsingItemID = -1
    end
    self:UpdateTypeSchedule(itemList)
end

function PersonaliseChangeMediator:InitChooseItem(configID)
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return
    end
    if self.selectType == AdornmentType.CastleSkin then
        self.goBaseContent:SetActive(false)
        self:ChooseCastleSkin(configInfo)
    elseif self.selectType == AdornmentType.PortraitFrame then
        self.goBaseContent:SetActive(true)
        self:ChooseHeadFrame(configInfo)
    elseif self.selectType == AdornmentType.Titles then
        self.goBaseContent:SetActive(false)
        self:ChooseTitle(configInfo)
    end
end

function PersonaliseChangeMediator:HideChooseItem()
    self.goCastleSkin:SetActive(false)
    self.goHeadFrame:SetActive(false)
    self.goTitle:SetActive(false)
end

function PersonaliseChangeMediator:UpdateTypeSchedule(itemList)
    local have, total = ModuleRefer.PersonaliseModule:GetItemListScheduleByType(itemList)
    self.textSchedule.text = string.format("%d/%d", have, total)
end

function PersonaliseChangeMediator:RefreshRightContent(configID)
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return
    end
    if not self.goContentRight.activeSelf then
        self.goContentRight:SetActive(true)
    end
    local quality = configInfo:Quality()
    local colorStr = PersonaliseDefine.QUALITY_COLOR[quality + 1]
    self.textQuality.text = UIHelper.GetColoredText(I18N.Get(PersonaliseDefine.QUALITY_NAME[quality + 1]), colorStr)
    self.textName.text = I18N.Get(configInfo:Name())
    self.textDesc.text = I18N.Get(configInfo:Desc())

    self:InitItemAttr(configInfo)

    local timeStatus = ModuleRefer.PersonaliseModule:GetItemTimeStatus(configID)
    self.textTimeLimitStatus.text = I18N.Get(PersonaliseDefine.TIME_STATUS_NAME[timeStatus])
    if timeStatus == PersonaliseDefine.TIME_STATUS.Locked then
        self.textTimeScoreReward.gameObject:SetActive(true)
        self.textTimeScoreReward.text = I18N.GetWithParams("skincollection_increpoints", configInfo:CollectAddValue())
        self.goChildTime:SetActive(false)
        self.btnAddMore.gameObject:SetActive(false)
    elseif timeStatus == PersonaliseDefine.TIME_STATUS.TimeLimited then
        self.textTimeScoreReward.gameObject:SetActive(true)
        self.textTimeScoreReward.text = I18N.GetWithParams("skincollection_increpoints", configInfo:CollectAddValue())
        self.goChildTime:SetActive(true)
        self.btnAddMore.gameObject:SetActive(true)

        local finishTime = ModuleRefer.PersonaliseModule:GetItemEndTime(configID)
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        if curTime >= finishTime then
            return
        end
        local callback = function()
            -- self:UpdateSelectedItem()
            self.delayTimer = TimerUtility.DelayExecute(function()
                self:InitTypeItem(self:GetCurFilterData())
                if self.selectType == AdornmentType.CastleSkin then
                    local city = ModuleRefer.CityModule.myCity
                    local furnitureManager = city.furnitureManager
                    if furnitureManager then
                        ---@type CityFurniture
                        local baseFurniture = furnitureManager:GetFurnitureByTypeCfgId(CityFurnitureTypeNames["1000101"])
                        if baseFurniture then
                            g_Game.EventManager:TriggerEvent(EventConst.CITY_UPDATE_FURNITURE, city, baseFurniture, true)
                        end
                    end
                end
            end, 1, -1)
        end
        self.childTime:FeedData({endTime = finishTime, needTimer = true, callBack = callback})
    elseif timeStatus == PersonaliseDefine.TIME_STATUS.Forever then
        self.textTimeScoreReward.gameObject:SetActive(false)
        self.goChildTime:SetActive(false)
        self.btnAddMore.gameObject:SetActive(false)
    end

    self:InitContentBtn()
end

function PersonaliseChangeMediator:OnClickChangeType(typeIndex, defaultChoosonItemID)
    self.selectType = typeIndex
    self.defaultChoosonItemID = defaultChoosonItemID and defaultChoosonItemID or -1
    self.tableproviewType:SetToggleSelect(self.selectType)
    self:InitTypeItem()
end

function PersonaliseChangeMediator:OnSelectItem(configID)
    self.curSelectItemID = configID
    if self.selectType == AdornmentType.Titles then
        self.tableproviewTitle:SetToggleSelect(configID)
    else
        self.tableproviewItem:SetToggleSelect(configID)
    end

    self:InitChooseItem(configID)
    self:RefreshRightContent(configID)
end

function PersonaliseChangeMediator:SelectNullItem()
    self.curSelectItemID = nil
    self:HideChooseItem()
    self.goContentRight:SetActive(false)
end

function PersonaliseChangeMediator:ChooseCastleSkin(configInfo)
    self:ShowTypeChoosenItem(AdornmentType.CastleSkin)

    self.textCastleSkinName.text = I18N.Get(configInfo:Name())
    self.imgCastle.gameObject:SetActive(false)
    self.imgCastleBase.gameObject:SetActive(false)

    self.curCastleType = PersonaliseDefine.CASTLE_TYPE.Kingdom
    self:RefreshCastleSkinChildPading(configInfo)
end

function PersonaliseChangeMediator:ChooseHeadFrame(configInfo)
    self:ShowTypeChoosenItem(AdornmentType.PortraitFrame)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    ---@type wds.PortraitInfo
    local portraitInfo = wds.PortraitInfo.New()
    portraitInfo.PlayerPortrait = player.Basics.PortraitInfo.PlayerPortrait
    portraitInfo.PortraitFrameId = configInfo:Id()
    portraitInfo.CustomAvatar = player.Basics.PortraitInfo.CustomAvatar
    self.luaGoPlayerHead:FeedData(portraitInfo)
end

function PersonaliseChangeMediator:ChooseTitle(configInfo)
    self:ShowTypeChoosenItem(AdornmentType.Titles)
    self:Show3DModel(configInfo, PersonaliseDefine.CASTLE_TYPE.Kingdom)
    self.imgTitleCastleBase.gameObject:SetActive(false)
    self.imgTitleCastle.gameObject:SetActive(false)
    -- g_Game.SpriteManager:LoadSprite(PersonaliseDefine.KingdomBaseIcon, self.imgTitleCastleBase)
    if configInfo:Id() == PersonaliseDefine.DefaultTitleID then
        self.luagoTitle:SetVisible(false)
    else
        self.luagoTitle:SetVisible(true)
        ---@type PlayerTitleParam
        local param = {configID = tonumber(configInfo:Icon()), name = I18N.Get(configInfo:Name())}
        self.luagoTitle:FeedData(param)
    end
    self.textLv.text =  ModuleRefer.MapBuildingTroopModule:GetStrongholdLevel(ModuleRefer.PlayerModule:GetCastle())
    self.textCityName.text = ModuleRefer.PlayerModule:MyFullName()
end

function PersonaliseChangeMediator:RefreshCastleSkinChildPading(configInfo)
    self:Show3DModel(configInfo, PersonaliseDefine.CASTLE_TYPE.Kingdom)
    if self.animCastleSkinChildPading then
        self.animCastleSkinChildPading:PlayAll(FpAnimTriggerEvent.Custom1)
    end
    self.goSelectLeft:SetActive(true)
    self.goSelectRight:SetActive(false)
    self.curCastleType = PersonaliseDefine.CASTLE_TYPE.Kingdom
    -- g_Game.SpriteManager:LoadSprite(PersonaliseDefine.KingdomBaseIcon, self.imgCastleBase)
    -- if not string.IsNullOrEmpty(configInfo:BigWOrldModel()) then
    --     g_Game.SpriteManager:LoadSprite(configInfo:BigWOrldModel(), self.imgCastle)
    -- end
end

function PersonaliseChangeMediator:UpdateSelectedItem()
    if self.ItemDataList then
        for k, v in ipairs(self.ItemDataList) do
            if v == self.curSelectItemID then
                if self.selectType == AdornmentType.Titles then
                    self.tableproviewTitle:UpdateData(v)
                else
                    self.tableproviewItem:UpdateData(v)
                end
            end
            if v == self.curUsingItemID then
                if self.selectType == AdornmentType.Titles then
                    self.tableproviewTitle:UpdateData(v)
                else
                    self.tableproviewItem:UpdateData(v)
                end
            end
        end
    end
    self:OnSelectItem(self.curSelectItemID)
    local usingData = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(self.selectType)
    if usingData then
        self.curUsingItemID = usingData.ConfigID
    end
end

function PersonaliseChangeMediator:InitItemAttr(configInfo)
    self:ClearAttrCache()
    local attrList = {}
    local attrGroupConfig = ConfigRefer.AttrGroup:Find(configInfo:CollectAttr())
    if not attrGroupConfig then
        table.insert(attrList, {
            type = -1,
            value = -1
        })
        local attrComp = UIHelper.DuplicateUIComponent(self.goPropertyItem, self.goPropertyParent.transform)
        attrComp.Lua:OnFeedData(attrList[1])
        attrComp.gameObject:SetActive(true)
        table.insert(self.attrCache, attrComp.gameObject)
        return
    end
    local attrTypeAndValue = nil
    for i = 1, attrGroupConfig:AttrListLength() do
        attrTypeAndValue = attrGroupConfig:AttrList(i)
        if attrTypeAndValue:TypeId() ~= PersonaliseDefine.IgnoreAttrTypeID then
            table.insert(attrList, {
                type = attrTypeAndValue:TypeId(),
                value = attrTypeAndValue:Value()
            })
        end
    end
    if #attrList > 0 then
        for i = 1, #attrList do
            local attrComp = UIHelper.DuplicateUIComponent(self.goPropertyItem, self.goPropertyParent.transform)
            attrComp.Lua:OnFeedData(attrList[i])
            attrComp.gameObject:SetActive(true)
            table.insert(self.attrCache, attrComp.gameObject)
        end
    end
end

function PersonaliseChangeMediator:InitContentBtn()
    local data = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(self.selectType)
    if data then
        if data.ConfigID == self.curSelectItemID then
            self:ShowButtonByBtnType(PersonaliseDefine.BTN_STATUS.Using)
            return
        end
    end
    if ModuleRefer.PersonaliseModule:IsAdornmentUnlocked(self.curSelectItemID) then
        self:ShowButtonByBtnType(PersonaliseDefine.BTN_STATUS.CanChange)
        return
    end
    if ModuleRefer.PersonaliseModule:IsCanUnlock(self.curSelectItemID) then
        self:ShowButtonByBtnType(PersonaliseDefine.BTN_STATUS.CanUnlock)
    else
        self:ShowButtonByBtnType(PersonaliseDefine.BTN_STATUS.CannotUnlock)
    end
end

function PersonaliseChangeMediator:ShowButtonByBtnType(type)
    if type == PersonaliseDefine.BTN_STATUS.Using then
        self.btnUse.gameObject:SetActive(false)
        self.btnChange.gameObject:SetActive(false)
        self.btnUnlock.gameObject:SetActive(false)
        self.goBtnUnbale:SetActive(true)
    elseif type == PersonaliseDefine.BTN_STATUS.CanChange then
        self.btnUse.gameObject:SetActive(false)
        self.btnChange.gameObject:SetActive(true)
        self.btnUnlock.gameObject:SetActive(false)
        self.goBtnUnbale:SetActive(false)
    elseif type == PersonaliseDefine.BTN_STATUS.CanUnlock then
        self.btnUse.gameObject:SetActive(false)
        self.btnChange.gameObject:SetActive(false)
        self.btnUnlock.gameObject:SetActive(true)
        self.goBtnUnbale:SetActive(false)
    elseif type == PersonaliseDefine.BTN_STATUS.CannotUnlock then
        self.btnUse.gameObject:SetActive(true)
        self.btnChange.gameObject:SetActive(false)
        self.btnUnlock.gameObject:SetActive(false)
        self.goBtnUnbale:SetActive(false)
    end
end

function PersonaliseChangeMediator:OnClickFilterCondition()
    if self:GetHasFilter() then
        self:OpenChoosePopupByFilter()
    else
        self:OpenChoosePopup()
    end
end

function PersonaliseChangeMediator:OnClickAddMore()
    local configInfo = ConfigRefer.Adornment:Find(self.curSelectItemID)
    if not configInfo then
        return
    end
    local items = ModuleRefer.PersonaliseModule:GetUnlockAdornmentItems(self.curSelectItemID)
    local provider = require('AdornmentGetMoreProvider').new()
    provider:SetItemList(items)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function PersonaliseChangeMediator:OnClickUse()
    local configInfo = ConfigRefer.Adornment:Find(self.curSelectItemID)
    if not configInfo then
        return
    end
    local items = ModuleRefer.PersonaliseModule:GetUnlockAdornmentItems(self.curSelectItemID)
    local provider = require('AdornmentGetMoreProvider').new()
    provider:SetItemList(items)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function PersonaliseChangeMediator:OnClickChange()
    local parameter = WearAdornmentParameter.new()
    parameter.args.AdornmentId = self.curSelectItemID
    parameter.args.IsWear = true
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            -- self:UpdateSelectedItem()
            self:InitTypeItem(self:GetCurFilterData())
            if self.selectType == AdornmentType.CastleSkin then
                local city = ModuleRefer.CityModule.myCity
                local furnitureManager = city.furnitureManager
                if furnitureManager then
                    ---@type CityFurniture
                    local baseFurniture = furnitureManager:GetFurnitureByTypeCfgId(CityFurnitureTypeNames["1000101"])
                    if baseFurniture then
                        g_Game.EventManager:TriggerEvent(EventConst.CITY_UPDATE_FURNITURE, city, baseFurniture, true)
                    end
                end
            end
        end
    end)
end

function PersonaliseChangeMediator:OnClickUnlock()
    local configInfo = ConfigRefer.Adornment:Find(self.curSelectItemID)
    if not configInfo then
        return
    end
    local items = ModuleRefer.PersonaliseModule:GetUnlockAdornmentItems(self.curSelectItemID)
    local provider = require('AdornmentGetMoreProvider').new()
    provider:SetItemList(items)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function PersonaliseChangeMediator:OnBtnChangeCityCastleType()
    local configInfo = ConfigRefer.Adornment:Find(self.curSelectItemID)
    if not configInfo then
        return
    end
    if self.curCastleType == PersonaliseDefine.CASTLE_TYPE.Kingdom then
        self.curCastleType = PersonaliseDefine.CASTLE_TYPE.City
        self.goSelectLeft:SetActive(false)
        self.goSelectRight:SetActive(true)
        self:Show3DModel(configInfo, PersonaliseDefine.CASTLE_TYPE.City)
    end
end

function PersonaliseChangeMediator:OnBtnChangeKingdomCastleType()
    local configInfo = ConfigRefer.Adornment:Find(self.curSelectItemID)
    if not configInfo then
        return
    end
    if self.curCastleType == PersonaliseDefine.CASTLE_TYPE.City then
        self.curCastleType = PersonaliseDefine.CASTLE_TYPE.Kingdom
        self.goSelectLeft:SetActive(true)
        self.goSelectRight:SetActive(false)
        -- g_Game.SpriteManager:LoadSprite(PersonaliseDefine.KingdomBaseIcon, self.imgCastleBase)
        -- if not string.IsNullOrEmpty(configInfo:BigWOrldModel()) then
        --     g_Game.SpriteManager:LoadSprite(configInfo:BigWOrldModel(), self.imgCastle)
        -- end
        self:Show3DModel(configInfo, PersonaliseDefine.CASTLE_TYPE.Kingdom)
    end
end

function PersonaliseChangeMediator:GetSelectType()
    return self.selectType
end

---@param data table<number, number>
function PersonaliseChangeMediator:OnConfirmFilter(data)
    self:SetCurFilterCode(CommonChooseHelper.GetFilterCode(data))
    self:InitTypeItem(data)
end

function PersonaliseChangeMediator:CheckFilterStatus(filterData)
    local hasFilter = false
    if filterData then
        local filterCode = CommonChooseHelper.GetFilterCode(filterData)
        if filterCode ~= self:GetDefaultFilterCode() then
            hasFilter = true
        end
    end
    if hasFilter then
        self.textFilter.text = I18N.Get("skincollection_screened")
    else
        self.textFilter.text = I18N.Get("skincollection_screen")
    end
    self:SetHasFilter(hasFilter)
end

function PersonaliseChangeMediator:SetDefaultFilterCode(filterCode)
    self.defaultFilterCode = filterCode
end

function PersonaliseChangeMediator:GetDefaultFilterCode()
    return self.defaultFilterCode
end

function PersonaliseChangeMediator:SetCurFilterCode(filterCode)
    self.curFilterCode = filterCode
end

function PersonaliseChangeMediator:GetCurFilterCode()
    return self.curFilterCode
end

function PersonaliseChangeMediator:SetHasFilter(hasFilter)
    self.hasFilter = hasFilter
end

function PersonaliseChangeMediator:GetHasFilter()
    return self.hasFilter
end

function PersonaliseChangeMediator:GetCurFilterData()
    return CommonChooseHelper.GetFilterDataByCode(self.curFilterCode)
end

function PersonaliseChangeMediator:OpenChoosePopup()
    ---@type FilterParam[]
    local filterType = {}
    local filterCode = 0
    table.insert(filterType, {
        typeIndex = CommonChoosePopupDefine.FilterType.Own,
        name = I18N.Get("skincollection_ownstate"),
        chooseType = CommonChoosePopupDefine.ChooseType.Single,
        subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.Own),
    })
    filterCode = filterCode | CommonChooseHelper.GetDefaultFilterCodeByType(CommonChoosePopupDefine.FilterType.Own)
    table.insert(filterType, {
        typeIndex = CommonChoosePopupDefine.FilterType.Quality,
        name = I18N.Get("skincollection_rarity"),
        chooseType = CommonChoosePopupDefine.ChooseType.Multiple,
        subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.Quality),
    })
    filterCode = filterCode | CommonChooseHelper.GetDefaultFilterCodeByType(CommonChoosePopupDefine.FilterType.Quality)
    self:SetDefaultFilterCode(filterCode)
    g_Game.UIManager:Open(UIMediatorNames.CommonChoosePopupMediator, {
        title = I18N.Get("skincollection_screen"),
        filterType = filterType,
        confirmCallBack = function(data)
            self:OnConfirmFilter(data)
        end,
        defaultFilterCode = filterCode,
    })
end

function PersonaliseChangeMediator:OpenChoosePopupByFilter()
    ---@type FilterParam[]
    local filterType = {}
    local filterCode = self:GetCurFilterCode()
    table.insert(filterType, {
        typeIndex = CommonChoosePopupDefine.FilterType.Own,
        name = I18N.Get("skincollection_ownstate"),
        chooseType = CommonChoosePopupDefine.ChooseType.Single,
        subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.Own, filterCode),
    })
    table.insert(filterType, {
        typeIndex = CommonChoosePopupDefine.FilterType.Quality,
        name = I18N.Get("skincollection_rarity"),
        chooseType = CommonChoosePopupDefine.ChooseType.Multiple,
        subFilterType = CommonChooseHelper.GetSubFilterTypeListByType(CommonChoosePopupDefine.FilterType.Quality, filterCode),
    })
    g_Game.UIManager:Open(UIMediatorNames.CommonChoosePopupMediator, {
        title = I18N.Get("skincollection_screen"),
        filterType = filterType,
        confirmCallBack = function(data)
            self:OnConfirmFilter(data)
        end,
        defaultFilterCode = self:GetDefaultFilterCode(),
    })
end

---@param configInfo AdornmentConfigCell
function PersonaliseChangeMediator:Show3DModel(configInfo, type)
    if (configInfo) then
        local artConf = nil
        local usingCastleSkin = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(AdornmentType.CastleSkin)
        local usingCastleSkinConfig = ConfigRefer.Adornment:Find(usingCastleSkin.ConfigID)
        if type == PersonaliseDefine.CASTLE_TYPE.Kingdom then
            if configInfo:BigWOrldModel() > 0 then
                artConf = ConfigRefer.ArtResource:Find(configInfo:BigWOrldModel())
            else
                artConf = ConfigRefer.ArtResource:Find(usingCastleSkinConfig:BigWOrldModel())
            end
        else
            if configInfo:InnerModel() > 0 then
                artConf = ConfigRefer.ArtResource:Find(configInfo:InnerModel())
            else
                artConf = ConfigRefer.ArtResource:Find(usingCastleSkinConfig:InnerModel())
            end
        end
        g_Game.UIManager:CloseUI3DView()
        g_Game.UIManager:SetupUI3DModelView(self:GetRuntimeId(),artConf:Path(),
                ConfigRefer.ArtResource:Find(PersonaliseDefine.DefaultModelBackgroundConfigID):Path(),
				nil, function(viewer)
            if not viewer then
                return
            end
            self.ui3dModel = viewer
            local scale = artConf:ModelScale()
			if (not scale or scale <= 0) then scale = 1 end
            self.ui3dModel:SetModelScale(CS.UnityEngine.Vector3.one * scale)
            self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30,322.46,0))
            self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(artConf:ModelPosition(1), artConf:ModelPosition(2), artConf:ModelPosition(3)))
			self.ui3dModel:InitVirtualCameraSetting(self:Get3DCameraSettings())
			self.ui3dModel:SetModelAngles(CS.UnityEngine.Vector3(artConf:ModelRotation(1), artConf:ModelRotation(2), artConf:ModelRotation(3)))
            self.ui3dModel:RefreshEnv()
			-- self:Play3DModelBgAnim()
			-- if configInfo:ShowAnimationLength() >= 1 then
			-- 	local maxNum = configInfo:ShowAnimationLength()
			-- 	local index = math.random(1, maxNum)
			-- 	self.aniName = configInfo:ShowAnimation(index)
			-- 	self.ui3dModel:PlayAnim(self.aniName)
			-- 	self.isPlayAni = true
			-- 	self.aniTimer = TimerUtility.IntervalRepeat(function() self:CheckIsCompleteShow() end, 0.2, -1)
			-- end
        end)
    end
end

function PersonaliseChangeMediator:Get3DCameraSettings()
    local cameraSetting = {}
    for i = 1, 2 do
        local setting = {}
        setting.fov = 3
        setting.nearCp = 40
        setting.farCp = 48
		setting.localPos = CS.UnityEngine.Vector3(0.065423, 3.751282, -43.87342)
        cameraSetting[i] = setting
    end
    return cameraSetting
end

function PersonaliseChangeMediator:OnBackBtnClick()
    local runtimeId = self:GetRuntimeId()
    TimerUtility.DelayExecute(function()
        g_Game.UIManager:CloseUI3DView(runtimeId)
        self:BackToPrevious()
    end, 0.1)
end

function PersonaliseChangeMediator:ClearAttrCache()
    if not self.attrCache then
        return
    end
    for _, attrGO in pairs(self.attrCache) do
        if (Utils.IsNotNull(attrGO)) then
            CS.UnityEngine.Object.Destroy(attrGO)
        end
    end
    self.attrCache = {}
end

function PersonaliseChangeMediator:GetCurSelectItemID()
    return self.curSelectItemID
end

function PersonaliseChangeMediator:GetDefaultChoosonItemID()
    return self.defaultChoosonItemID
end

return PersonaliseChangeMediator