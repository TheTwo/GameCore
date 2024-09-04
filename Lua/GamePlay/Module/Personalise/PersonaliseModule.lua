local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local PersonaliseDefine = require('PersonaliseDefine')
local AdornmentType = require('AdornmentType')
local CommonChoosePopupDefine = require('CommonChoosePopupDefine')
local NotificationType = require('NotificationType')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local UIMediatorNames = require('UIMediatorNames')
local UseItemParameter = require('UseItemParameter')
local ItemType = require('ItemType')
local NewFunctionUnlockIdDefine = require('NewFunctionUnlockIdDefine')
local ConvertPieceToAdornmentParameter = require('ConvertPieceToAdornmentParameter')
local SyncAdornmentRedDotParameter = require('SyncAdornmentRedDotParameter')


---@class PersonaliseModule : BaseModule
local PersonaliseModule = class('PersonaliseModule', BaseModule)


function PersonaliseModule:ctor()
    --TODO
end


function PersonaliseModule:OnRegister()
    ---@type AdornmentTypesConfigCell[]
    self.adornmentTypeListCache = {}
    self.adornmentItemListCache = {} 
    self.adornmentNewItemListCache = {}         --{type:ItemList}
    g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.CheckSysOpen))
end


function PersonaliseModule:OnRemove()
    self.adornmentTypeListCache = {}
    self.adornmentItemListCache = {}
    self.adornmentNewItemListCache = {}
    g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.CheckSysOpen))
end

--region GainBuff
function PersonaliseModule:GetGainBuffList()
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    local gainBuffList = {}
    self:MergeGainBuffList(self:GetCollectGainBuffListByData(appearance.Adornments, AdornmentType.PortraitFrame), gainBuffList)
    self:MergeGainBuffList(self:GetCollectGainBuffListByData(appearance.Adornments, AdornmentType.CastleSkin), gainBuffList)
    self:MergeGainBuffList(self:GetCollectGainBuffListByData(appearance.Adornments, AdornmentType.Title), gainBuffList)
    self:MergeGainBuffList(self:GetWearGainBuffListByData(appearance.CurWardrobe), gainBuffList)
    return gainBuffList
end

--获取头像框的收藏属性加成
function PersonaliseModule:GetHeadFrameGainBuffList()
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    return self:GetCollectGainBuffListByData(appearance.Adornments, AdornmentType.PortraitFrame)
end

--获取城堡皮肤的收藏属性加成
function PersonaliseModule:GetCastleSkinsGainBuffList()
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    return self:GetCollectGainBuffListByData(appearance.Adornments, AdornmentType.CastleSkin)
end

--获取称号的收藏属性加成
function PersonaliseModule:GetTitlesGainBuffList()
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    return self:GetCollectGainBuffListByData(appearance.Adornments, AdornmentType.Title)
end

--获取当前穿戴的装扮属性加成
function PersonaliseModule:GetCurWardrobeGainBuffList()
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    return self:GetWearGainBuffListByData(appearance.CurWardrobe)
end

function PersonaliseModule:GetCollectGainBuffListByData(table, typeIndex)
    if not table then
        return
    end
    typeIndex = typeIndex or -1
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    local gainBuffList = {}
    local adorbmentConfig = nil
    local attrGroupConfig = nil
    local attrTypeAndValue = nil
    for k, v in pairs(table) do
        if typeIndex ~= -1 and v.Type ~= typeIndex then
            goto continue
        end
        adorbmentConfig = ConfigRefer.Adornment:Find(v.ConfigID)
        if not adorbmentConfig then
            goto continue
        end
        attrGroupConfig = ConfigRefer.AttrGroup:Find(adorbmentConfig:CollectAttr())
        if attrGroupConfig then
            for i = 1, attrGroupConfig:AttrListLength() do
                attrTypeAndValue = attrGroupConfig:AttrList(i)
                if attrTypeAndValue:TypeId() ~= PersonaliseDefine.IgnoreAttrTypeID then
                    self:AddAttrInfo(attrTypeAndValue, gainBuffList)
                end
                -- ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, gainBuffList, true)
            end
        end
        ::continue::
    end
    return gainBuffList
end

function PersonaliseModule:GetWearGainBuffListByData(table, typeIndex)
    if not table then
        return
    end
    typeIndex = typeIndex or -1
    local appearance = self:GetAppearanceData()
    if not appearance then
        return
    end
    local gainBuffList = {}
    local adorbmentConfig = nil
    local attrGroupConfig = nil
    local attrTypeAndValue = nil
    for k, v in pairs(table) do
        if typeIndex ~= -1 and v.Type ~= typeIndex then
            goto continue
        end
        adorbmentConfig = ConfigRefer.Adornment:Find(v.ConfigID)
        if not adorbmentConfig then
            goto continue
        end
        attrGroupConfig = ConfigRefer.AttrGroup:Find(adorbmentConfig:WearAttr())
        if attrGroupConfig then
            for i = 1, attrGroupConfig:AttrListLength() do
                attrTypeAndValue = attrGroupConfig:AttrList(i)
                if attrTypeAndValue:TypeId() ~= PersonaliseDefine.IgnoreAttrTypeID then
                    self:AddAttrInfo(attrTypeAndValue, gainBuffList)
                end
                -- ModuleRefer.VillageModule.ParseAttrInfo(attrTypeAndValue, gainBuffList, true)

            end
        end
        ::continue::
    end
    return gainBuffList
end

---@param attrTypeAndValue AttrTypeAndValue
function PersonaliseModule:AddAttrInfo(attrTypeAndValue, gainBuffList)
    for i = 1, #gainBuffList do
        if gainBuffList[i].type == attrTypeAndValue:TypeId() then
            gainBuffList[i].value = gainBuffList[i].value + attrTypeAndValue:Value()
            return
        end
    end
    table.insert(gainBuffList, {type = attrTypeAndValue:TypeId(), value = attrTypeAndValue:Value()})
end

--endregion

--region CommonFunc
---@return wds.Appearance
function PersonaliseModule:GetAppearanceData()
    if not self.appearance then
        self.appearance = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper3.Appearance
    end
    return self.appearance
end

function PersonaliseModule:GetUsingAdornmentDataByType(type)
    local appearance = self:GetAppearanceData()
    if not appearance then
        return nil
    end
    for k, v in pairs(appearance.CurWardrobe) do
        if v.Type == type then
            return v
        end
    end
    return nil
end

function PersonaliseModule:IsAdornmentUnlocked(configID)
    local appearance = self:GetAppearanceData()
    if not appearance then
        return false
    end
    for k, v in pairs(appearance.Adornments) do
        if v.ConfigID == configID then
            return true
        end
    end
    return false
end

function PersonaliseModule:IsAdornmentPermanent(configID)
    local appearance = self:GetAppearanceData()
    if not appearance then
        return false
    end
    for k, v in pairs(appearance.Adornments) do
        if v.ConfigID == configID then
            return v.Permanent
        end
    end
    return false
 end

function PersonaliseModule:IsCanUnlock(configID)
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return false
    end
    if self:IsAdornmentUnlocked(configID) then
        return false
    end
    local pieceCount = ModuleRefer.InventoryModule:GetAmountByConfigId(configInfo:PieceId())
    local needCount = configInfo:ComposeNeedPieceNum()
    if needCount > 0 and pieceCount >= needCount then
        return true
    end
    for i = 1, configInfo:GetItemIdsLength() do
        local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(configInfo:GetItemIds(i))
        if itemCount > 0 then
            return true
        end
    end
    return false
end

function PersonaliseModule:IsCanPermanentUnlock(configID)
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return false
    end
    if self:IsAdornmentUnlocked(configID) then
        return false
    end
    local pieceCount = ModuleRefer.InventoryModule:GetAmountByConfigId(configInfo:PieceId())
    local needCount = configInfo:ComposeNeedPieceNum()
    if needCount > 0 and pieceCount >= needCount then
        return true
    end
    for i = 1, configInfo:GetItemIdsLength() do
        local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(configInfo:GetItemIds(i))
        local isPermanent = false
        local itemConfig = ConfigRefer.Item:Find(configInfo:GetItemIds(i))
        if itemConfig and tonumber(itemConfig:UseParam(2)) == 0 then
            isPermanent = true
        end
        if itemCount > 0 and isPermanent then
            return true
        end
    end
    return false
end

---@return AdornmentTypesConfigCell[]
function PersonaliseModule:GetTypeList()
    -- if self.adornmentTypeListCache and #self.adornmentTypeListCache > 0 then
    --     return self.adornmentTypeListCache
    -- end
    local typeList = {}
    for k, v in ConfigRefer.AdornmentTypes:ipairs() do
        if v:IsShow() then
            table.insert(typeList, v)
        end
    end
    if #typeList > 0 then
        table.sort(typeList, function(l, r)
            return l:Priority() < r:Priority()
        end)
        self.adornmentTypeListCache = typeList
    end
    return typeList
end

---@return AdornmentConfigCell[]
function PersonaliseModule:GetItemListByType(type, needSort)
    -- if self.adornmentItemListCache and self.adornmentItemListCache[type] then
    --     return self.adornmentItemListCache[type]
    -- end
    needSort = needSort or false
    local itemList = {}
    if #self.adornmentItemListCache > 0 then
        for i = 1, #self.adornmentItemListCache do
            if self.adornmentItemListCache[i]:AdornmentType() == type and self.adornmentItemListCache[i]:IsShow() then
                table.insert(itemList, self.adornmentItemListCache[i])
            end
        end
    else
        for k, v in ConfigRefer.Adornment:ipairs() do
            table.insert(self.adornmentItemListCache, v)
            if v:AdornmentType() == type and v:IsShow() then
                table.insert(itemList, v)
            end
        end
    end
    if #itemList > 0 and needSort then
        table.sort(itemList, function(l, r)
            local l_configID = l:Id()
            local r_configID = r:Id()
            local defaultAdornmentConfigID = self:GetDefaultAdornmentConfigID(type)
            local l_isDefault = l_configID == defaultAdornmentConfigID
            local r_isDefault = r_configID == defaultAdornmentConfigID
            local l_isUsing = self:CheckIsUsingAdornment(l_configID, type)
            local r_isUsing = self:CheckIsUsingAdornment(r_configID, type)
            local l_isUnLocked = self:IsAdornmentUnlocked(l_configID)
            local r_isUnLocked = self:IsAdornmentUnlocked(r_configID)
            local l_isCanUnlock = self:IsCanUnlock(l_configID)
            local r_isCanUnlock = self:IsCanUnlock(r_configID)
            local l_isPermanent = self:IsAdornmentPermanent(l_configID)
            local r_isPermanent = self:IsAdornmentPermanent(r_configID)
            local l_quality = l:Quality()
            local r_quality = r:Quality()
            --默认的排前面
            if l_isDefault ~= r_isDefault then
                return l_isDefault
            end
            --使用中的排前面
            if l_isUsing ~= r_isUsing then
                return l_isUsing
            end
            --已解锁的排前面
            if l_isUnLocked ~= r_isUnLocked then
                return l_isUnLocked
                --已解锁的限时的排前面
            elseif l_isUnLocked and r_isUnLocked then
                if l_isPermanent ~= r_isPermanent then
                    return r_isPermanent
                end
            end
            --可解锁的排前面
            if l_isCanUnlock ~= r_isCanUnlock then
                return l_isCanUnlock
            end
            --高品质的排前面
            if l_quality ~= r_quality then
                return l_quality > r_quality
            else
                --品质相同的id小的排前面
                return l_configID < r_configID
            end

        end)
        -- self.adornmentItemListCache[type] = itemList
    end
    return itemList
end

function PersonaliseModule:GetScheduleByType(type)
    return self:GetHaveItemCountByType(type), #self:GetItemListByType(type)
end

---@param itemList AdornmentConfigCell[]
function PersonaliseModule:GetItemListScheduleByType(itemList)
    if #itemList == 0 then
        return 0, 0
    end
    local haveCount = 0
    for i = 1, #itemList do
        if self:IsAdornmentUnlocked(itemList[i]:Id()) then
            haveCount = haveCount + 1
        end
    end
    return haveCount, #itemList
end

function PersonaliseModule:GetHaveItemCountByType(type)
    local count = 0
    local appearance = self:GetAppearanceData()
    if not appearance then
        return count
    end
    for k, v in pairs(appearance.Adornments) do
        if v.Type == type then
            count = count + 1
        end
    end
    return count
end

---@return PersonaliseDefine.TIME_STATUS
function PersonaliseModule:GetItemTimeStatus(configID)
    if not self:IsAdornmentUnlocked(configID) then
        return PersonaliseDefine.TIME_STATUS.Locked
    end
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return PersonaliseDefine.TIME_STATUS.None
    end
    if self:IsAdornmentPermanent(configID) then
        return PersonaliseDefine.TIME_STATUS.Forever
    else
        return PersonaliseDefine.TIME_STATUS.TimeLimited
    end
end

function PersonaliseModule:GetItemEndTime(configID)
    local appearance = self:GetAppearanceData()
    if not appearance then
        return -1
    end
    for k, v in pairs(appearance.Adornments) do
        if v.ConfigID == configID and not v.Permanent then
            return v.ExpireTime.Seconds
        end
    end
    return -1
end

---@param itemList AdornmentConfigCell[]
---@param subFilterCode number
---@return AdornmentConfigCell[]
function PersonaliseModule:GetItemListWithOwnFilter(itemList, subFilterCode)
    if subFilterCode & CommonChoosePopupDefine.OwnSubFilterType.Owned > 0 then
        local tempList = {}
        for i = 1, #itemList do
            if self:IsAdornmentUnlocked(itemList[i]:Id()) then
                table.insert(tempList, itemList[i])
            end
        end
        return tempList
    elseif subFilterCode & CommonChoosePopupDefine.OwnSubFilterType.NotOwned > 0 then
        local tempList = {}
        for i = 1, #itemList do
            if not self:IsAdornmentUnlocked(itemList[i]:Id()) then
                table.insert(tempList, itemList[i])
            end
        end
        return tempList
    else
        --All
        return itemList
    end
end

---@param itemList AdornmentConfigCell[]
---@param subFilterCode number
---@return AdornmentConfigCell[]
function PersonaliseModule:GetItemListWithQualityFilter(itemList, subFilterCode)
    --没有筛选条件，则返回原列表
    if subFilterCode == 0 then
        return itemList
    end
    local tempList = {}
    local subFilterTypeList = {}
    local quality = 3
    local maxCount = 4      --防止死循环
    while subFilterCode > 0 and maxCount > 0 do
        if subFilterCode & 1 > 0 then
            table.insert(subFilterTypeList, quality)
        end
        quality = quality - 1
        maxCount = maxCount - 1
        subFilterCode = subFilterCode >> 1
    end
    for i = 1, #itemList do
        if table.ContainsValue(subFilterTypeList, itemList[i]:Quality()) then
            table.insert(tempList, itemList[i])
        end
    end
    return tempList
end

--获取背包中已有的可以解锁装扮的道具id
---@return number[]
function PersonaliseModule:GetUnlockAdornmentItems(configID)
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return {}
    end
    local itemList = {}
    table.insert(itemList, configInfo:PieceId())
    for i = 1, configInfo:GetItemIdsLength() do
        local itemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(configInfo:GetItemIds(i))
        if itemCount > 0 then
            table.insert(itemList, configInfo:GetItemIds(i))
        end
    end

    return itemList
end

function PersonaliseModule:CheckCastleUsingSkin()
    local usingCastleSkin = self:GetUsingAdornmentDataByType(AdornmentType.CastleSkin)
    return usingCastleSkin.ConfigID ~= PersonaliseDefine.DefaultCastleSkinID
end

function PersonaliseModule:GetUsingCastleInnerSkin()
    local usingCastleSkin = self:GetUsingAdornmentDataByType(AdornmentType.CastleSkin)    
    local configInfo = ConfigRefer.Adornment:Find(usingCastleSkin.ConfigID)
    if configInfo then
        return configInfo:InnerRealModel()
    end
    return nil
end

function PersonaliseModule:CheckIsUsingAdornment(configID, type)
    local usingAdornment = self:GetUsingAdornmentDataByType(type)
    if usingAdornment then
        return usingAdornment.ConfigID == configID
    end
    return false
end

function PersonaliseModule:GetDefaultAdornmentConfigID(type)
    if type == AdornmentType.CastleSkin then
        return PersonaliseDefine.DefaultCastleSkinID
    elseif type == AdornmentType.PortraitFrame then
        return PersonaliseDefine.DefaultHeadFrameID
    elseif type == AdornmentType.Titles then
        return PersonaliseDefine.DefaultTitleID
    end
    return -1
end

function PersonaliseModule:CheckSysOpen(systemEntryIds)
    local sysPersonaliseIndex = NewFunctionUnlockIdDefine.Personalise
    if table.ContainsValue(systemEntryIds, sysPersonaliseIndex) then
        self.sysPersonaliseOpenFlag = true
    end
    local sysHeadChangeIndex = NewFunctionUnlockIdDefine.Head_Change
    if table.ContainsValue(systemEntryIds, sysHeadChangeIndex) then
        self.sysHeadChangeOpenFlag = true
    end
end

function PersonaliseModule:CheckIsPersonaliseOpen()
    return self.sysPersonaliseOpenFlag and true or false
end

function PersonaliseModule:CheckIsHeadChangeOpen()
    return self.sysHeadChangeOpenFlag and true or false
end

function PersonaliseModule:ResetPersonaliseOpenFlag()
    self.sysPersonaliseOpenFlag = false
end

function PersonaliseModule:ResetHeadChangeOpenFlag()
    self.sysHeadChangeOpenFlag = false
end

function PersonaliseModule:InitRedDotLogicTree()
    if self.createRedDot then
        return
    end
    --入口红点
    local personaliseBtnNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseBtnNode", NotificationType.PERSONALISE)

    --外观主界面红点
    local mainHeadFrameNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseMainHeadFrameNode", NotificationType.PERSONALISE_MAIN_HEAD_FRAME)
    local mainCastleSkinNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseMainCastleSkinNode", NotificationType.PERSONALISE_MAIN_CASTLE_SKIN)
    local mainTitleNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseMainTitleNode", NotificationType.PERSONALISE_MAIN_TITLE)
    -- ModuleRefer.NotificationModule:AddToParent(mainHeadFrameNode, personaliseBtnNode)
    -- ModuleRefer.NotificationModule:AddToParent(mainCastleSkinNode, personaliseBtnNode)
    -- ModuleRefer.NotificationModule:AddToParent(mainTitleNode, personaliseBtnNode)

    --外观界面左侧分类页签红点
    local tabHeadFrameNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseTabHeadFrameNode", NotificationType.PERSONALISE_TAB_HEAD_FRAME)
    local tabCastleSkinNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseTabCastleSkinNode", NotificationType.PERSONALISE_TAB_CASTLE_SKIN)
    local tabTitleNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseTabTitleNode", NotificationType.PERSONALISE_TAB_TITLE)
    -- ModuleRefer.NotificationModule:AddToParent(tabHeadFrameNode, mainHeadFrameNode)
    -- ModuleRefer.NotificationModule:AddToParent(tabCastleSkinNode, mainCastleSkinNode)
    -- ModuleRefer.NotificationModule:AddToParent(tabTitleNode, mainTitleNode)

    --外观界面item红点
    local headFrameItemList = self:GetItemListByType(AdornmentType.PortraitFrame)
    if #headFrameItemList > 0 then
        for i = 1, #headFrameItemList do
            local itemHeadFrameNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseItemHeadFrameNode"..headFrameItemList[i]:Id(), NotificationType.PERSONALISE_ITEM_HEAD_FRAME)
            -- ModuleRefer.NotificationModule:AddToParent(itemHeadFrameNode, tabHeadFrameNode)
        end
    end

    local castleSkinItemList = self:GetItemListByType(AdornmentType.CastleSkin)
    if #castleSkinItemList > 0 then
        for i = 1, #castleSkinItemList do
            local itemCastleSkinNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseItemCastleSkinNode"..castleSkinItemList[i]:Id(), NotificationType.PERSONALISE_ITEM_CASTLE_SKIN)
            -- ModuleRefer.NotificationModule:AddToParent(itemCastleSkinNode, tabCastleSkinNode)
        end
    end

    local titleItemList = self:GetItemListByType(AdornmentType.Titles)
    if #titleItemList > 0 then
        for i = 1, #titleItemList do
            local itemTitleNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("PersonaliseItemTitleNode"..titleItemList[i]:Id(), NotificationType.PERSONALISE_ITEM_TITLE)
            -- ModuleRefer.NotificationModule:AddToParent(itemTitleNode, tabTitleNode)
        end
    end

    self.createRedDot = true
end

function PersonaliseModule:RefreshRedPoint()
    if not self.createRedDot then
        self:InitRedDotLogicTree()
    end
    local isHasCanUnlockHeadFrame = self:isHasCanUnlock(AdornmentType.PortraitFrame)
    local isHasCanUnlockCastleSkin = self:isHasCanUnlock(AdornmentType.CastleSkin)
    local isHasCanUnlockTitle = self:isHasCanUnlock(AdornmentType.Titles)
    local isHasCanPermanentUnlockHeadFrame = self:isHasCanPermanentUnlock(AdornmentType.PortraitFrame)
    local isHasCanPermanentUnlockCastleSkin = self:isHasCanPermanentUnlock(AdornmentType.CastleSkin)
    local isHasCanPermanentUnlockTitle = self:isHasCanPermanentUnlock(AdornmentType.Titles)
    local isHasCanPermanentUnlock = isHasCanPermanentUnlockHeadFrame or isHasCanPermanentUnlockCastleSkin or isHasCanPermanentUnlockTitle
    local isHasNewHeadFrame = self:IsHasNew(AdornmentType.PortraitFrame)
    local isHasNewCastleSkin = self:IsHasNew(AdornmentType.CastleSkin)
    local isHasNewTitle = self:IsHasNew(AdornmentType.Titles)
    local isHasNew = isHasNewHeadFrame or isHasNewCastleSkin or isHasNewTitle
    
    --入口红点
    local personaliseRedDot = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseBtnNode", NotificationType.PERSONALISE)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(personaliseRedDot, (isHasNew or isHasCanPermanentUnlock) and 1 or 0)

    --外观主界面红点
    local mainHeadFrameNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseMainHeadFrameNode", NotificationType.PERSONALISE_MAIN_HEAD_FRAME)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(mainHeadFrameNode, (isHasNewHeadFrame or isHasCanPermanentUnlockHeadFrame) and 1 or 0)
    local mainCastleSkinNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseMainCastleSkinNode", NotificationType.PERSONALISE_MAIN_CASTLE_SKIN)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(mainCastleSkinNode, (isHasNewCastleSkin or isHasCanPermanentUnlockCastleSkin) and 1 or 0)
    local mainTitleNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseMainTitleNode", NotificationType.PERSONALISE_MAIN_TITLE)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(mainTitleNode, (isHasNewTitle or isHasCanPermanentUnlockTitle) and 1 or 0)

    --外观界面左侧分类页签红点
    local tabHeadFrameNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseTabHeadFrameNode", NotificationType.PERSONALISE_TAB_HEAD_FRAME)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(tabHeadFrameNode, (isHasNewHeadFrame or isHasCanUnlockHeadFrame) and 1 or 0)
    local tabCastleSkinNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseTabCastleSkinNode", NotificationType.PERSONALISE_TAB_CASTLE_SKIN)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(tabCastleSkinNode, (isHasNewCastleSkin or isHasCanUnlockCastleSkin) and 1 or 0)
    local tabTitleNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseTabTitleNode", NotificationType.PERSONALISE_TAB_TITLE)
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(tabTitleNode, (isHasNewTitle or isHasCanUnlockTitle) and 1 or 0)

end

function PersonaliseModule:isHasCanUnlock(type)
    ---@type AdornmentConfigCell[]
    local allItemList = {}
    if not type then
        self:TableCopy(self:GetItemListByType(AdornmentType.PortraitFrame), allItemList)
        self:TableCopy(self:GetItemListByType(AdornmentType.CastleSkin), allItemList)
        self:TableCopy(self:GetItemListByType(AdornmentType.Titles), allItemList)
    else
        allItemList = self:GetItemListByType(type)
    end
    for k, v in pairs(allItemList) do
        if type then
            if v:AdornmentType() == type and self:IsCanUnlock(v:Id()) then
                return true
            end
        else
            if self:IsCanUnlock(v:Id()) then
                return true
            end
        end
    end
    return false
end

function PersonaliseModule:isHasCanPermanentUnlock(type)
    ---@type AdornmentConfigCell[]
    local allItemList = {}
    if not type then
        self:TableCopy(self:GetItemListByType(AdornmentType.PortraitFrame), allItemList)
        self:TableCopy(self:GetItemListByType(AdornmentType.CastleSkin), allItemList)
        self:TableCopy(self:GetItemListByType(AdornmentType.Titles), allItemList)
    else
        allItemList = self:GetItemListByType(type)
    end
    for k, v in pairs(allItemList) do
        if type then
            if v:AdornmentType() == type and self:IsCanPermanentUnlock(v:Id()) then
                return true
            end
        else
            if self:IsCanPermanentUnlock(v:Id()) then
                return true
            end
        end
    end
    return false
end

function PersonaliseModule:IsHasNew(type)
    local appearance = self:GetAppearanceData()
    if not appearance then
        return false
    end
    local isHasNew = false
    for k, v in pairs(appearance.Adornments) do
        if type then
            if v.Type == type and v.IsNew then
                isHasNew = true
                break
            end
        else
            if v.IsNew then
                isHasNew = true
                break
            end
        end
    end
    return isHasNew

end

function PersonaliseModule:CheckIsNewUnlockItem(type, configID)
    local appearance = self:GetAppearanceData()
    if not appearance then
        return false
    end
    for k, v in pairs(appearance.Adornments) do
        if v.Type == type and v.ConfigID == configID then
            return v.IsNew
        end
    end
    return false
end

function PersonaliseModule:SyncAdornmentRedDot(configID)
    local param = SyncAdornmentRedDotParameter.new()
    param.args.AdornCfgId = configID
    param:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            self:RefreshRedPoint()
        end
    end)
end

function PersonaliseModule:OnUseAdornmentItem(uid)
    local itemConfig = ModuleRefer.InventoryModule:GetConfigByUid(uid)
    if not itemConfig then
        return
    end
    local sysIndex = NewFunctionUnlockIdDefine.Personalise
	if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex) then
		ModuleRefer.ToastModule:AddSimpleToast(ModuleRefer.NewFunctionUnlockModule:BuildLockedTip(sysIndex))
		return
	end
    local configID = tonumber(itemConfig:UseParam(1))
    if self:IsAdornmentPermanent(configID) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_use_ownpermanent"))
        return
    end

    if itemConfig:Type() == ItemType.AdornmentPiece then
        local pieceCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemConfig:Id())
        local needCount = itemConfig:NeedPieceNum()
        if not (needCount > 0 and pieceCount >= needCount) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_use_piecenotenough"))
            return
        end
    end

    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    if itemConfig:Type() == ItemType.AdornmentPiece then
        dialogParam.title = I18N.Get("skincollection_fragmentsplice")
    else
        dialogParam.title = I18N.Get("skincollection_unlockwithitem")
    end
    local nameStr = string.format("<b>%s</b>", I18N.Get(itemConfig:NameKey()))
    if itemConfig:Type() == ItemType.AdornmentPiece then
        dialogParam.content = I18N.GetWithParams("skincollection_fragmentsplice_makesure", nameStr)
        dialogParam.onConfirm = function()
            self:OnConfirmPieceConvertAdornmentItem(configID, uid)
            return true
        end
    else
        dialogParam.content = I18N.GetWithParams("skincollection_use_makesure", nameStr)
        dialogParam.onConfirm = function()
            self:OnConfirmUseAdornmentItem(uid)
            return true
        end
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

function PersonaliseModule:OnConfirmUseAdornmentItem(uid)
    local msg = UseItemParameter.new()
    msg.args.ComponentID = uid
    msg.args.Num = 1
    msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)
            local itemConfig = ModuleRefer.InventoryModule:GetConfigByUid(uid)
            if not itemConfig then
                return
            end
            local configID = tonumber(itemConfig:UseParam(1))
            ---@type CommonConfirmPopupMediatorParameter
            local dialogParam = {}
            dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            dialogParam.title = I18N.Get("skincollection_changeadornment")
            dialogParam.confirmLabel = I18N.Get("skincollection_use_changeadornment_makesure_btn")
            dialogParam.cancelLabel = I18N.Get("tech_btn_cancel")
            local nameStr = string.format("<b>%s</b>", I18N.Get(itemConfig:NameKey()))
            dialogParam.content = I18N.GetWithParams("skincollection_use_changeadornment_makesure_desc", nameStr)
            dialogParam.onConfirm = function()
                self:onConfirmChangeAdornmentItem(configID)
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
        end
    end)
end

function PersonaliseModule:OnConfirmPieceConvertAdornmentItem(configID, uid)
    local parameter = ConvertPieceToAdornmentParameter.new()
    parameter.args.AdornmentCfgId = configID
    parameter.args.Use = true
    parameter:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
            g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)
            local itemConfig = ModuleRefer.InventoryModule:GetConfigByUid(uid)
            if not itemConfig then
                return
            end
            local configInfo = ConfigRefer.Adornment:Find(configID)
            if not configInfo then
                return
            end
            ---@type CommonConfirmPopupMediatorParameter
            local dialogParam = {}
            dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            dialogParam.title = I18N.Get("skincollection_changeadornment")
            dialogParam.confirmLabel = I18N.Get("skincollection_use_changeadornment_makesure_btn")
            dialogParam.cancelLabel = I18N.Get("tech_btn_cancel")
            local nameStr = string.format("<b>%s</b>", I18N.Get(configInfo:Name()))
            dialogParam.content = I18N.GetWithParams("skincollection_use_changeadornment_makesure_desc", nameStr)
            dialogParam.onConfirm = function()
                self:onConfirmChangeAdornmentItem(configID)
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
        end
    end)
end

function PersonaliseModule:onConfirmChangeAdornmentItem(configID)
    local configInfo = ConfigRefer.Adornment:Find(configID)
    if not configInfo then
        return
    end
    local adornmentType = configInfo:AdornmentType()
    ---@param param PersonaliseChangeParam
    g_Game.UIManager:Open(UIMediatorNames.PersonaliseChangeMediator, {typeIndex = adornmentType, defaultChoosonItemID = configID})
    self:AdornmentOpenBILog(true, 1, adornmentType)
end

function PersonaliseModule:TableCopy(src, dest)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function PersonaliseModule:MergeGainBuffList(src, dest)
    if not src or not dest then
        return
    end
    for i = 1, #src do
        local isExist = false
        for j = 1, #dest do
            if src[i].type == dest[j].type then
                dest[j].value = dest[j].value + src[i].value
                isExist = true
                break
            end
        end
        if not isExist then
            table.insert(dest, src[i])
        end
    end
end

--外观界面BI打点
function PersonaliseModule:AdornmentOpenBILog(isEnterSubPage, enterType, subPageType)
    local FPXSDKBIDefine = require("FPXSDKBIDefine")
    local key = FPXSDKBIDefine.ExtraKey.adornment_page
    local extraParam = {}
    extraParam[key.ador_sub] = isEnterSubPage
    extraParam[key.enter_type] = enterType
    extraParam[key.sub_type] = subPageType
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.adornment_page, extraParam)
end


--endregion


return PersonaliseModule