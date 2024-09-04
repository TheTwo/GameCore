local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIHeroLocalData = require('UIHeroLocalData')
local DBEntityPath = require("DBEntityPath")
local GuideUtils = require("GuideUtils")
local ConfigRefer = require('ConfigRefer')
local LockEquipParameter = require("LockEquipParameter")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local I18N = require('I18N')
local EventConst = require("EventConst")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local FunctionClass = require('FunctionClass')

local Vector3 = CS.UnityEngine.Vector3

---@class CommonItemDetailsParameter
---@field clickTransform CS.UnityEngine.Transform
---@field drawingId number
---@field equipId number
---@field itemId number
---@field itemUid number
---@field itemType CommonItemDetailsDefine.ITEM_TYPE

---@class CommonItemDetails:BaseUIComponent
---@field super BaseUIComponent
local CommonItemDetails = class('CommonItemDetails', BaseUIComponent)

function CommonItemDetails:ctor()

end

function CommonItemDetails:OnCreate()
    self.goRoot = self:GameObject("")
    self.goGroupItem = self:GameObject('p_group_item')
    self.imgBaseQuality = self:Image('p_base_quality')
    self.imgLine = self:Image('p_line')
    self.imgIconItem = self:Image('p_icon_item')
    self.txtTextNum = self:Text("p_text_num")
    self.textItemName = self:Text('p_text_item_name')
    self.goHave = self:GameObject('p_have')
    self.textHave = self:Text('p_text_have')
    self.textHaveNumber = self:Text('p_text_have_number')
    self.goCity = self:GameObject('p_city')
    self.textCity = self:Text('p_text_city')
    self.textCityNumber = self:Text('p_text_city_number')
    self.goEquipment = self:GameObject('p_equipment')
    self.goEquipmentLv = self:GameObject('p_equipment_lv')
    self.textLv = self:Text('p_text_lv')
    self.btnLock = self:Button('p_lock', Delegate.GetOrCreate(self, self.OnBtnLockCLick))
    self.imgIconLock = self:Image('p_icon_lock')
    self.imgIconUnlock = self:Image('p_icon_unlock')
    self.textItemContent = self:Text('p_text_item_content')
    self.goAttribute = self:GameObject('p_attribute')
    self.goTitleAddtion = self:GameObject('p_title_addtion_1')
    self.imgIconAddtion = self:Image('p_icon_addtion')
    self.textTitleAddtion = self:Text('p_title_addtion')
    self.textTitleAddtionNumber = self:Text('p_title_addtion_number')
    self.goTitleAttribute = self:GameObject('title_attribute')
    self.goItem1 = self:GameObject('p_item_1')
    self.goItemAddtion1 = self:GameObject('p_item_addtion_1')
    self.imgIconAddtion1 = self:Image('p_icon_addtion_1')
    self.textAddtion1 = self:Text('p_text_addtion_1')
    self.textAddtionNumber1 = self:Text('p_text_addtion_number_1')
    self.textAddtionUnlock1 = self:Text('p_text_addtion_unlock_1')
    self.goItem2 = self:GameObject('p_item_2')
    self.goItemAddtion2 = self:GameObject('p_item_addtion_2')
    self.imgIconAddtion2 = self:Image('p_icon_addtion_2')
    self.textAddtion2 = self:Text('p_text_addtion_2')
    self.textAddtionNumber2 = self:Text('p_text_addtion_number_2')
    self.textAddtionUnlock2 = self:Text('p_text_addtion_unlock_2')
    self.goItem3 = self:GameObject('p_item_3')
    self.goItemAddtion3 = self:GameObject('p_item_addtion_3')
    self.imgIconAddtion3 = self:Image('p_icon_addtion_3')
    self.textAddtion3 = self:Text('p_text_addtion_3')
    self.textAddtionNumber3 = self:Text('p_text_addtion_number_3')
    self.textAddtionUnlock3 = self:Text('p_text_addtion_unlock_3')
    self.goTableSuit = self:GameObject('p_table_suit')
    self.textTitle = self:Text('p_text_title', I18N.Get("hero_equip_suit_effect"))
    self.textNameSuit1 = self:Text('p_text_name_suit_1')
    self.imgIconSuit1 = self:Image('p_icon_suit_1')
    self.textDetailSuit1 = self:Text('p_text_detail_suit_1')
    self.textDetailSuit2 = self:Text('p_text_detail_suit_2')
    self.goIcon1 = self:GameObject('p_icon_1')
    self.goIcon2 = self:GameObject('p_icon_2')

    self.goTitleGet = self:GameObject('p_title_get')
    self.textGet = self:Text('p_text_get', I18N.Get("backpack_item_getmore"))
    self.goItemGet1 = self:GameObject('p_item_get_1')
    self.textGet1 = self:Text('p_text_get_1')
    self.btnArrow1 = self:Button('p_btn_arrow_1', Delegate.GetOrCreate(self, self.OnBtnArrow1Clicked))
    self.goItemGet2 = self:GameObject('p_item_get_2')
    self.textGet2 = self:Text('p_text_get_2')
    self.btnArrow2 = self:Button('p_btn_arrow_2', Delegate.GetOrCreate(self, self.OnBtnArrow2Clicked))
    self.goItemGet3 = self:GameObject('p_item_get_3')
    self.textGet3 = self:Text('p_text_get_3')
    self.btnArrow3 = self:Button('p_btn_arrow_3', Delegate.GetOrCreate(self, self.OnBtnArrow3Clicked))
    self.goItemGet4 = self:GameObject('p_item_get_4')
    self.textGet4 = self:Text('p_text_get_4')
    self.btnArrow4 = self:Button('p_btn_arrow_4', Delegate.GetOrCreate(self, self.OnBtnArrow4Clicked))
    self.goItemGet5 = self:GameObject('p_item_get_5')
    self.textGet5 = self:Text('p_text_get_5')
    self.btnArrow5 = self:Button('p_btn_arrow_5', Delegate.GetOrCreate(self, self.OnBtnArrow5Clicked))

    --宠物
    self.p_group_pet = self:GameObject('p_group_pet')
    self.p_text_pet = self:Text('p_text_pet', "pet_drone_available_pets_name")
    ---@type UIPossiblePetComp
    self.p_table_pet = self:TableViewPro('p_table_pet')
    
    --宠物标签
    self.p_group_lable = self:GameObject('p_group_lable')
    ---@type PetTagComponent
    self.child_pet_lable_feature = self:LuaObject('child_pet_lable_feature')
    ---@type PetTagComponent
    self.child_pet_lable_feature_1 = self:LuaObject('child_pet_lable_feature_1')

    self.goIcon1:SetActive(false)
    self.goIcon2:SetActive(false)

    self.attrItems = {self.goItem1, self.goItem2, self.goItem3}
    self.attrShows = {self.goItemAddtion1, self.goItemAddtion2, self.goItemAddtion3}
    self.attrIcons = {self.imgIconAddtion1, self.imgIconAddtion2, self.imgIconAddtion3}
    self.attrTexts = {self.textAddtion1, self.textAddtion2, self.textAddtion3}
    self.attrNums = {self.textAddtionNumber1, self.textAddtionNumber2, self.textAddtionNumber3}
    self.attrHides = {self.textAddtionUnlock1, self.textAddtionUnlock2, self.textAddtionUnlock3}
    self.getMoreItems = {self.goItemGet1, self.goItemGet2, self.goItemGet3, self.goItemGet4, self.goItemGet5}
    self.getMoreTexts = {self.textGet1, self.textGet2, self.textGet3, self.textGet4, self.textGet5}
    self.getMoreBtns = {self.btnArrow1, self.btnArrow2, self.btnArrow3, self.btnArrow4, self.btnArrow5}
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshDetails))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LimitInScene))

end

function CommonItemDetails:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshDetails))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LimitInScene))
end

---@param param CommonItemDetailsParameter
function CommonItemDetails:OnFeedData(param)
    if not param then
        return
    end
    if self.p_group_lable then
        self.p_group_lable:SetVisible(false)
    end
    self.param = param
    self:RefreshDetails()
    if self.param.clickTransform then
        LayoutRebuilder.ForceRebuildLayoutImmediate(self.goRoot.transform)
        self:LimitInScene()
    end
end

function CommonItemDetails:RefreshDetails()
    if not self.param then
        return
    end
    if self.param.itemType == CommonItemDetailsDefine.ITEM_TYPE.EQUIP then
        self:ChangeGoByEquipState()
        self:RefreshEquipDetails()
    elseif self.param.itemType == CommonItemDetailsDefine.ITEM_TYPE.DRAWING then
        self:ChangeGoByDrawingState()
        self:RefreshDrawingDetails()
    elseif self.param.itemType == CommonItemDetailsDefine.ITEM_TYPE.ITEM then
        local functionClass = ConfigRefer.Item:Find(self.param.itemId):FunctionClass()
        local isPetEgg = functionClass == FunctionClass.OpenPetEgg
        if isPetEgg then
            self:ChangeGoByPetEggState()
            self:RefreshPetEggDetails()
        else
            self:ChangeGoByItemState()
            self:RefreshItemDetails()
        end
    end
end

function CommonItemDetails:LimitInScene()
    if self.param and self.param.clickTransform then
        TipsRectTransformUtils.TryAnchorTipsNearTargetRectTransform(self.param.clickTransform, self.goRoot.transform)
    end
end
---------------EquipState Start----------------------------------------
function CommonItemDetails:ChangeGoByEquipState()
    self.goHave:SetActive(false)
    --self.textItemContent.gameObject:SetActive(false)
    --self.goTableSuit:SetActive(true)
    self.textItemContent.gameObject:SetActive(true)
    self.goTableSuit:SetActive(false)
    self.goEquipment:SetActive(true)
    self.p_group_pet:SetVisible(false)
end

function CommonItemDetails:RefreshEquipDetails()
    if self.param.itemUid then
        local itemInfo = ModuleRefer.InventoryModule:GetItemInfoByUid(self.param.itemUid) or {}
        local equipInfo = itemInfo.EquipInfo
        if not equipInfo then
            return
        end
        self.goAttribute:SetActive(true)
        self.btnLock.gameObject:SetActive(true)
        local itemCfg = ConfigRefer.Item:Find(itemInfo.ConfigId)
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItem)
        local showMiddleText = not string.IsNullOrEmpty(itemCfg:MiddleI18N())
        self.txtTextNum:SetVisible(showMiddleText)
        if showMiddleText then
            self.txtTextNum.text = I18N.Get(itemCfg:MiddleI18N())
        end
        local equipCfg = ConfigRefer.HeroEquip:Find(equipInfo.ConfigId)
        self.textItemContent.text = I18N.Get(equipCfg:EquipDes())
        g_Game.SpriteManager:LoadSprite("sp_common_frame_pic_0" .. equipCfg:Quality(), self.imgBaseQuality)
        --g_Game.SpriteManager:LoadSprite("sp_common_frame_line_pic_0" .. equipCfg:Quality(), self.imgLine)
        self.textItemName.text = I18N.Get(equipCfg:Name())
        local isShowLv = equipInfo.StrengthenLevel > 0
        self.goEquipmentLv:SetActive(isShowLv)
        if isShowLv then
            self.textLv.text = "+" .. equipInfo.StrengthenLevel
        end
        self.imgIconLock.gameObject:SetActive(equipInfo.IsLock)
        self.imgIconUnlock.gameObject:SetActive(not equipInfo.IsLock)
        local mainAttri = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(self.param.itemUid, UIHeroLocalData.EQUIP_ATTR_INDEX.MAIN)
        if not mainAttri then
            return
        end
        local mainAttrCell = ConfigRefer.AttrElement:Find(mainAttri.type)
        g_Game.SpriteManager:LoadSprite(mainAttrCell:Icon(), self.imgIconAddtion)
        self.textTitleAddtion.text = I18N.Get(mainAttri.name)
        self.textTitleAddtionNumber.text =  ModuleRefer.AttrModule:GetAttrValueShowTextByType(mainAttrCell, mainAttri.value)
        local strengthenLvList = ModuleRefer.HeroModule:GetStrengthenConditionList(equipInfo.ConfigId)
        local strengthCount = #strengthenLvList
        local isCanStrength = strengthCount > 0
        self.goTitleAttribute:SetActive(isCanStrength)
        for i = 1, 3 do
            if i <= strengthCount then
                self.attrItems[i].gameObject:SetActive(true)
                local attr = ModuleRefer.HeroModule:GetEquipAttrInfoByIndex(self.param.itemUid, i + 1)
                local hasAttr = attr ~= nil
                self.attrShows[i]:SetActive(hasAttr)
                self.attrHides[i].gameObject:SetActive(not hasAttr)
                if hasAttr then
                    local attrCell = ConfigRefer.AttrElement:Find(attr.type)
                    g_Game.SpriteManager:LoadSprite(attrCell:Icon(), self.attrIcons[i])
                    self.attrTexts[i].text = I18N.Get(attr.name)
                    self.attrNums[i].text = ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrCell, attr.value)
                else
                    self.attrHides[i].text = I18N.GetWithParams("equip_newattr", strengthenLvList[i])
                end
            else
                self.attrShows[i]:SetActive(false)
                self.attrHides[i].gameObject:SetActive(false)
                self.attrItems[i].gameObject:SetActive(false)
            end
        end
        local suitId = equipCfg:SuitId()
        local suitCfg = ConfigRefer.Suit:Find(suitId)
        if suitCfg then
            self.textNameSuit1.text = I18N.Get(suitCfg:Name())
            self:LoadSprite(suitCfg:Icon(), self.imgIconSuit1)
            self.textDetailSuit1.text = I18N.Get(suitCfg:SuitEffect(1):Desc())
            self.textDetailSuit2.text = I18N.Get(suitCfg:SuitEffect(2):Desc())
        end
    elseif self.param.equipId then
        self.goEquipmentLv:SetActive(false)
        self.goAttribute:SetActive(false)
        self.btnLock.gameObject:SetActive(false)
        local equipCfg = ConfigRefer.HeroEquip:Find(self.param.equipId)
        self:LoadSprite(equipCfg:Icon(), self.imgIconItem)
        self.txtTextNum:SetVisible(false)
        self.textItemContent.text = I18N.Get(equipCfg:EquipDes())
        g_Game.SpriteManager:LoadSprite("sp_common_frame_pic_0" .. equipCfg:Quality(), self.imgBaseQuality)
        --g_Game.SpriteManager:LoadSprite("sp_common_frame_line_pic_0" .. equipCfg:Quality(), self.imgLine)
        self.textItemName.text = I18N.Get(equipCfg:Name())
        local suitId = equipCfg:SuitId()
        local suitCfg = ConfigRefer.Suit:Find(suitId)
        if suitCfg then
            self.textNameSuit1.text = I18N.Get(suitCfg:Name())
            self:LoadSprite(suitCfg:Icon(), self.imgIconSuit1)
            self.textDetailSuit1.text = I18N.Get(suitCfg:SuitEffect(1):Desc())
            self.textDetailSuit2.text = I18N.Get(suitCfg:SuitEffect(2):Desc())
        end
    end
end

function CommonItemDetails:OnBtnLockCLick()
    local param = LockEquipParameter.new()
    local equipInfo = ModuleRefer.InventoryModule:GetItemInfoByUid(self.param.itemUid).EquipInfo
    param.args.EquipItemId = self.param.itemUid
    param.args.IsLock = not equipInfo.IsLock
    param:Send(self.btnLock.transform)
end
---------------EquipState End----------------------------------------
---------------DrawingState Start----------------------------------------
function CommonItemDetails:ChangeGoByDrawingState()
    self.goHave:SetActive(false)
    self.textItemContent.gameObject:SetActive(false)
    self.goAttribute:SetActive(false)
    self.goEquipment:SetActive(false)
    self.p_group_pet:SetVisible(false)
end

function CommonItemDetails:RefreshDrawingDetails()
    local drawingCfg = ConfigRefer.Drawing:Find(self.param.drawingId)
    self.textItemName.text = I18N.Get(drawingCfg:Name())
    self:LoadSprite(drawingCfg:Icon(), self.imgIconItem)
    self.txtTextNum:SetVisible(false)
    local fixSuitId = drawingCfg:FixSuitId()
    if fixSuitId > 0 then
        self.goTableSuit:SetActive(true)
        local suitCfg = ConfigRefer.Suit:Find(fixSuitId)
        if suitCfg then
            self.textNameSuit1.text = I18N.Get(suitCfg:Name())
            self:LoadSprite(suitCfg:Icon(), self.imgIconSuit1)
            self.textDetailSuit1.text = I18N.Get(suitCfg:SuitEffect(1):Desc())
            self.textDetailSuit2.text = I18N.Get(suitCfg:SuitEffect(2):Desc())
        end
    else
        self.goTableSuit:SetActive(false)
    end
end

---------------DrawingState End----------------------------------------
---------------ItemState Start-----------------------------------------
function CommonItemDetails:ChangeGoByItemState()
    self.goEquipment:SetActive(false)
    self.textItemContent.gameObject:SetActive(true)
    self.goTableSuit:SetActive(false)
    self.goAttribute:SetActive(false)
    self.goHave:SetActive(false)
    
	if self.p_group_pet then
		self.p_group_pet:SetVisible(false)
	end
end

function CommonItemDetails:RefreshItemDetails()
    local itemCfg = ConfigRefer.Item:Find(self.param.itemId)
    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItem)
    local showMiddleText = not string.IsNullOrEmpty(itemCfg:MiddleI18N())
    self.txtTextNum:SetVisible(showMiddleText)
    if showMiddleText then
        self.txtTextNum.text = I18N.Get(itemCfg:MiddleI18N())
    end
    if UNITY_EDITOR then
        self.textItemName.text = I18N.Get(itemCfg:NameKey()) .. string.format("(%s)" ,self.param.itemId)
    else
        self.textItemName.text = I18N.Get(itemCfg:NameKey())
    end
    if itemCfg:NeedPieceNum() > 0 then
        self.textItemContent.text = I18N.GetWithParams(itemCfg:DescKey(), itemCfg:NeedPieceNum())
    else
        self.textItemContent.text = I18N.Get(itemCfg:DescKey())
    end
    g_Game.SpriteManager:LoadSprite("sp_common_frame_pic_0" .. itemCfg:Quality(), self.imgBaseQuality)
    local getMoreId = itemCfg:GetMoreConfig()
    if getMoreId <= 0 then
        self.goTitleGet:SetActive(false)
        for i = 1, 5 do
            self.getMoreItems[i]:SetActive(false)
        end
        return
    end
    local getMoreCfg = ConfigRefer.GetMore:Find(getMoreId)
    local hasGetMore = getMoreCfg:GotoLength() > 0
    self.goTitleGet:SetActive(hasGetMore)
    local gotoList = {}
    for i = 1, getMoreCfg:GotoLength() do
        local isOpend = true
        local sysEntry = getMoreCfg:Goto(i):UnlockSystem()
        if sysEntry > 0 then
            isOpend = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysEntry)
        end
        if isOpend then
            gotoList[#gotoList + 1] = {index = i, gotoId = getMoreCfg:Goto(i):Goto()}
        end
    end
    table.sort(gotoList, function(a, b)
        return a.index < b.index
    end)
    self.gotoList = gotoList
    for i = 1, 5 do
        local info = gotoList[i]
        self.getMoreItems[i]:SetActive(info ~= nil)
        if info then
            self.getMoreBtns[i].gameObject:SetActive(not self:NeedHideGetMore() and info.gotoId > 0)
            self.getMoreTexts[i].text = I18N.Get(getMoreCfg:Goto(info.index):Desc())
        end
    end
end

function CommonItemDetails:NeedHideGetMore()
    if g_Game.StateMachine:IsCurrentState(require('SeState').Name) then
        return true
    end
    return false
end

function CommonItemDetails:OnBtnArrow1Clicked(args)
    self:GetParentBaseUIMediator():CloseSelf()
    GuideUtils.GotoItemAccess(self.param.itemId, self.gotoList[1].index)
end

function CommonItemDetails:OnBtnArrow2Clicked(args)
    self:GetParentBaseUIMediator():CloseSelf()
    GuideUtils.GotoItemAccess(self.param.itemId, self.gotoList[2].index)
end

function CommonItemDetails:OnBtnArrow3Clicked(args)
    self:GetParentBaseUIMediator():CloseSelf()
    GuideUtils.GotoItemAccess(self.param.itemId, self.gotoList[3].index)
end

function CommonItemDetails:OnBtnArrow4Clicked(args)
    self:GetParentBaseUIMediator():CloseSelf()
    GuideUtils.GotoItemAccess(self.param.itemId, self.gotoList[4].index)
end

function CommonItemDetails:OnBtnArrow5Clicked(args)
    self:GetParentBaseUIMediator():CloseSelf()
    GuideUtils.GotoItemAccess(self.param.itemId, self.gotoList[5].index)
end
---------------ItemState End-------------------------------------------
---------------PetEgg Start--------------------------------------------
function CommonItemDetails:ChangeGoByPetEggState()
    self.goEquipment:SetActive(false)
    self.textItemContent.gameObject:SetActive(true)
    self.goTableSuit:SetActive(false)
    self.goAttribute:SetActive(false)
    self.goHave:SetActive(false)
    self.p_group_pet:SetVisible(true)
end

function CommonItemDetails:RefreshPetEggDetails()
    local itemCfg = ConfigRefer.Item:Find(self.param.itemId)
    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItem)
    local showMiddleText = not string.IsNullOrEmpty(itemCfg:MiddleI18N())
    self.txtTextNum:SetVisible(showMiddleText)
    if showMiddleText then
        self.txtTextNum.text = I18N.Get(itemCfg:MiddleI18N())
    end
    if UNITY_EDITOR then
        self.textItemName.text = I18N.Get(itemCfg:NameKey()) .. string.format("(%s)" ,self.param.itemId)
    else
        self.textItemName.text = I18N.Get(itemCfg:NameKey())
    end
    if itemCfg:NeedPieceNum() > 0 then
        self.textItemContent.text = I18N.GetWithParams(itemCfg:DescKey(), itemCfg:NeedPieceNum())
    else
        self.textItemContent.text = I18N.Get(itemCfg:DescKey())
    end
    g_Game.SpriteManager:LoadSprite("sp_common_frame_pic_0" .. itemCfg:Quality(), self.imgBaseQuality)
    self.goTitleGet:SetVisible(false)
    for i = 1, 5 do
        self.getMoreItems[i]:SetVisible(false)
    end
    local functionClass = itemCfg:FunctionClass()
    if functionClass ~= FunctionClass.OpenPetEgg then
        g_Logger.Error("道具 FunctionClass 不是宠物蛋类型"..self.param.itemId)
        return
    end
    local petPool = ConfigRefer.PetEggRewardPool:Find(tonumber(itemCfg:UseParam(1)))

    --找到对应宠物池
    local poolCfg = petPool:RandomCfg(petPool:RandomCfgLength()):RandomPool()
    local randomPool = ConfigRefer.PetEggRewardRandomPool:Find(poolCfg)

    --宠物蛋标签
    if self.p_group_lable then
        if petPool:TagLength() > 0 then
            self.p_group_lable:SetVisible(true)
            self.child_pet_lable_feature:FeedData(petPool:Tag(1))
            local hasSecondLabel = petPool:TagLength() > 1
            if hasSecondLabel then
                self.child_pet_lable_feature_1:FeedData(petPool:Tag(2))
            end
            self.child_pet_lable_feature_1:SetVisible(hasSecondLabel)
        else
            self.p_group_lable:SetVisible(false)
        end
    end
    
    --添加宠物
    local sortData = {}
    for i = 1, randomPool:RandomWeightLength() do
        local petCfgId = randomPool:RandomWeight(i):RefPet()
        local quality = ConfigRefer.Pet:Find(petCfgId):Quality()
        ---@type UIPetIconData
        local data = {
            cfgId = petCfgId,
            quality = quality,
            -- onClick = function()
            --     ModuleRefer.PetModule:ShowPetPreview(petCfgId, "sss")
            -- end
        }

        local isContain = false
        for k,v in pairs(sortData) do
            if v.cfgId == petCfgId then
                isContain = true
                break
            end
        end
        if not isContain then
            table.insert(sortData,data)
        end
    end

    --按品质排序
    table.sort(sortData,function(a,b)
        return a.quality > b.quality
    end)

    self.p_table_pet:Clear()
    for k,v in pairs(sortData)do
        self.p_table_pet:AppendData(v)
    end

    self.p_table_pet:RefreshAllShownItem()
end


---------------PetEgg End--------------------------------------------

return CommonItemDetails
