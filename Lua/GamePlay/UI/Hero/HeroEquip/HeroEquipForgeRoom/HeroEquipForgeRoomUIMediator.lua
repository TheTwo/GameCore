local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local HeroEquipQuality = require('HeroEquipQuality')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local BuildEquipParameter = require("BuildEquipParameter")
local HeroUIUtilities = require('HeroUIUtilities')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local TimerUtility = require('TimerUtility')
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local HeroEquipType = require("HeroEquipType")
local DBEntityPath = require("DBEntityPath")
---@class HeroEquipForgeRoomUIMediator:BaseUIMediator
local HeroEquipForgeRoomUIMediator = class('HeroEquipForgeRoomUIMediator', BaseUIMediator)
local UIMediatorNames = require("UIMediatorNames")

local EQUIP_ICON = {ArtResourceUIConsts.sp_hero_icon_equipment_weapon, ArtResourceUIConsts.sp_hero_icon_equipment_head,
        ArtResourceUIConsts.sp_hero_icon_equipment_clothes, ArtResourceUIConsts.sp_hero_icon_equipment_belt, ArtResourceUIConsts.sp_hero_icon_equipment_shoes}

local EQUIP_TYPE = {HeroEquipType.Weapon, HeroEquipType.Head, HeroEquipType.Clothes, HeroEquipType.Belt, HeroEquipType.Shoes}

function HeroEquipForgeRoomUIMediator:ctor()

end


function HeroEquipForgeRoomUIMediator:FindVxNode_zhizao_ani()
    if self.imgVxTubiao then
        return true
    end
    self.goZhizao = self:GameObject("vx_zhizao_ani",true)
    self.imgVxTubiao = self:Image('vx_tubiao',nil,nil,true)
    self.imgVxTubiao1 = self:Image('vx_tubiao_1',nil,nil,true)
    self.imgVxTubiao2 = self:Image('vx_tubiao_2',nil,nil,true)
    self.goImgTv = self:GameObject("img_tv",true)
    return self.imgVxTubiao ~= nil
end

function HeroEquipForgeRoomUIMediator:FindVxNode_vx_effect_xxx()
    if self.goDrawYellow then
        return true
    end
    self.goDrawYellow = self:GameObject("vx_effect_yellow",true)
    self.goDrawPurple = self:GameObject("vx_effect_purple",true)
    self.goDrawBlue = self:GameObject("vx_effect_blue",true)
    return self.goDrawYellow ~= nil
end

function HeroEquipForgeRoomUIMediator:OnCreate()
    self.textName = self:Text('p_text_name')
    self.textBar = self:Text('p_text_bar', I18N.Get("equip_build_quality"))
    self.goProgress = self:GameObject("vx_trigger_progress")
    -- self.goDrawYellow = self:GameObject("vx_effect_yellow")
    -- self.goDrawPurple = self:GameObject("vx_effect_purple")
    -- self.goDrawBlue = self:GameObject("vx_effect_blue")
    self.goDrawSSRYellow = self:GameObject("vx_novice_tv_ssr_change_yellow")
    self.goDrawSSRPruple = self:GameObject("vx_novice_tv_ssr_change_purple")
    self.goDrawSSRBlue = self:GameObject("vx_novice_tv_ssr_change_blue")
    self.aniZhizaoTrigger = self:AnimTrigger("vx_zhizao_ani_ctrl")
    self.btnGroupProgress = self:Button('p_group_progress', Delegate.GetOrCreate(self, self.OnBtnProgressClicked))
    self.imgProgressGold = self:Image('p_progress_gold')
    self.imgProgressPurple = self:Image('p_progress_purple')
    self.imgProgressBlue = self:Image('p_progress_blue')
    self.imgProgressGreen = self:Image('p_progress_green')
    self.imgProgressWhite = self:Image('p_progress_white')
    self.goGroupTv = self:GameObject('group_tv')
    self.imgIconEquipment = self:Image('p_icon_equipment')
    self.tableviewproTableLv = self:TableViewPro('p_table_lv')
    self.compChildCommonQuantityL = self:LuaObject('child_common_quantity_l')
    self.compChildCommonQuantityL1 = self:LuaObject('child_common_quantity_l_1')
    self.compChildCommonQuantityL2 = self:LuaObject('child_common_quantity_l_2')
    self.compChildCommonQuantityL3 = self:LuaObject('child_common_quantity_l_3')
    self.compChildCommonQuantityL4 = self:LuaObject('child_common_quantity_l_4')
    self.compChildCommonQuantityL5 = self:LuaObject('child_common_quantity_l_5')
    self.textChoice = self:Text('p_text_choice', I18N.Get("equip_build_num"))
    self.inputfieldInputQuantity = self:InputField('p_Input_quantity', nil, Delegate.GetOrCreate(self, self.OnEndEdit))
    self.textInput = self:Text('p_text_input')
    self.textQuantity = self:Text('p_text_quantity')
    self.textNeedItem = self:Text('p_text_need_item', I18N.Get("equip_build_require_material"))
    self.goEmpty = self:GameObject("p_empty")
    self.textEmpty = self:Text("p_text_empty", I18N.Get("furniture_process_wood"))

    self.goItemDrawing = self:GameObject('p_item_drawing')
    self.goImgSelect = self:GameObject('p_img_select')
    self.goBase = self:GameObject('base_1')
    self.btnEmpty = self:Button('p_btn_empty', Delegate.GetOrCreate(self, self.OnBtnEmptyClicked))
    self.btnDelete = self:Button('p_btn_delete', Delegate.GetOrCreate(self, self.OnBtnDeleteClicked))
    self.textChoiceDrawing = self:Text('p_text_choice_drawing', I18N.Get("equip_build_blueprint"))
    self.compChildItemStandardSEditor2 = self:LuaBaseComponent('child_item_standard_s_2')
    self.compChildSetBar = self:LuaBaseComponent('child_set_bar')
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.goTable = self:GameObject('p_table')
    self.btnBase = self:Button('p_btn_base', Delegate.GetOrCreate(self, self.OnBtnBaseClicked))
    self.tableviewproTableDrawing = self:TableViewPro('p_table_drawing')
    self.compChildCommonBack = self:LuaBaseComponent('child_common_btn_back')
    self.compChildResource = self:LuaObject('child_resource')
    self.usbItems = {}
    self.usbBtns = {}
    self.usbNImgs = {}
    self.usbNTexts = {}
    self.usbSImgs = {}
    self.usbSTexts = {}
    self.maxNum = 1
    for i = 1, 5 do
        self.usbItems[i] = self:GameObject("p_usb_" .. i)
        self.usbBtns[i] = self:Button("p_btn_usb_" .. i, function() self:OnUsbSelect(i) end)
        self.usbNImgs[i] = self:GameObject("p_img_usb_n_" .. i)
        self.usbNTexts[i] = self:Text("p_text_usb_n_" .. i, HeroUIUtilities.RomanChar[i])
        self.usbSImgs[i] = self:GameObject("p_img_usb_select_" .. i)
        self.usbSTexts[i] = self:Text("p_text_usb_select_" .. i, HeroUIUtilities.RomanChar[i])
    end
    self.qualityBars = {self.imgProgressWhite, self.imgProgressGreen, self.imgProgressBlue, self.imgProgressPurple, self.imgProgressGold}
    self.costItems = {self.compChildCommonQuantityL, self.compChildCommonQuantityL1, self.compChildCommonQuantityL2,
        self.compChildCommonQuantityL3, self.compChildCommonQuantityL4, self.compChildCommonQuantityL5}
    for _, progressImg in ipairs(self.qualityBars) do
        progressImg.gameObject:SetActive(true)
    end
    self.goImgSelect:SetActive(false)
end

function HeroEquipForgeRoomUIMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.HERO_ONCLICK_DRAWING, Delegate.GetOrCreate(self, self.OnSelectDrawing))
    g_Game.EventManager:RemoveListener(EventConst.HERO_SELECT_BUILD, Delegate.GetOrCreate(self, self.ChangeSelectBuild))
    g_Game.ServiceManager:RemoveResponseCallback(BuildEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.ShowBtn))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.RefreshItemCost))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshItemCost))
    g_Game.UIManager:CloseByName('UIFullscreenBlock')

    if self.delayTimer then
        TimerUtility.StopAndRecycle(self.delayTimer)
        self.delayTimer = nil
    end
end

function HeroEquipForgeRoomUIMediator:OnShow()
    self.compChildCommonBack:FeedData({title = I18N.Get("equip_build")})
    local buttonParamStartWork = {}
    buttonParamStartWork.onClick = Delegate.GetOrCreate(self, self.OnBtnCompALU2EditorClicked)
    buttonParamStartWork.buttonText = I18N.Get("equip_build_btn")

    self.compChildCompB:OnFeedData(buttonParamStartWork)
    self.selectUsbIndex = 2
    self:SelectForgeLevel(1)
    g_Game.EventManager:AddListener(EventConst.HERO_ONCLICK_DRAWING, Delegate.GetOrCreate(self, self.OnSelectDrawing))
    g_Game.EventManager:AddListener(EventConst.HERO_SELECT_BUILD, Delegate.GetOrCreate(self, self.ChangeSelectBuild))
    g_Game.ServiceManager:AddResponseCallback(BuildEquipParameter.GetMsgId(), Delegate.GetOrCreate(self,self.ShowBtn))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.RefreshItemCost))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Currency.MsgPath,Delegate.GetOrCreate(self,self.RefreshItemCost))
end

function HeroEquipForgeRoomUIMediator:SelectForgeLevel(selectBuildIndex)
    self.selectBuildIndex = selectBuildIndex
    self:RefreshBaseInfo()
end

function HeroEquipForgeRoomUIMediator:RefreshBaseInfo()
    self.buildIds = {}
    for _, v in ConfigRefer.HeroEquipBuild:ipairs() do
        self.buildIds[#self.buildIds + 1] = v:Id()
    end

    self.tableviewproTableLv:Clear()
    for i = 1, #self.buildIds do
        self.tableviewproTableLv:AppendData(self.buildIds[i])
    end
    self:ChangeSelectBuild(self.buildIds[self.selectBuildIndex])
end

function HeroEquipForgeRoomUIMediator:ChangeSelectBuild(buildId)
    self.buildId = buildId
    self.tableviewproTableLv:SetToggleSelect(buildId)
    local buildCfg = ConfigRefer.HeroEquipBuild:Find(buildId)
    local buildLength = buildCfg:EquipRandBuildIdLength()
    for i = 1, 5 do
        self.usbItems[i]:SetActive(buildLength >= i)
    end
    self.textName.text = I18N.Get(buildCfg:Name())
    self:OnUsbSelect(self.selectUsbIndex)
end

function HeroEquipForgeRoomUIMediator:OnUsbSelect(index)
    self.drawingData = nil
    self.selectUsbIndex = index
    for i = 1, 5 do
        local isShow = index == i
        self.usbNImgs[i]:SetActive(not isShow)
        self.usbSImgs[i]:SetActive(isShow)
    end
    self:RefreshUsbSuits()
end

function HeroEquipForgeRoomUIMediator:RefreshUsbSuits()
    local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
    self.goItemDrawing:SetActive(buildCfg:CanJoinDrawing())
    if self.drawingData then
        local itemDrawingCfg = ConfigRefer.Item:Find(self.drawingData.configCell:Id())
        local drawingCfg = ConfigRefer.Drawing:Find(itemDrawingCfg:DrawingId())
        local fixQuality = drawingCfg:FixQuality()
        self:RefreshQualityProgress(fixQuality)
        self:RefreshDrawingForge(fixQuality)
        self:FindVxNode_vx_effect_xxx()
        if fixQuality then
            self.goProgress:SetActive(true)
            if self:FindVxNode_zhizao_ani() then
                self.goImgTv:SetActive(false)
            end
            self.goGroupTv:SetActive(false)
            self.goZhizao:SetActive(true)
            if fixQuality == HeroEquipQuality.Purple then
                self.goDrawYellow:SetActive(false)
                self.goDrawBlue:SetActive(false)
                self.goDrawPurple:SetActive(true)
                self.goDrawSSRYellow:SetActive(false)
                self.goDrawSSRBlue:SetActive(false)
                self.goDrawSSRPruple:SetActive(true)
                self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom4)
            elseif fixQuality == HeroEquipQuality.Gold then
                self.goDrawYellow:SetActive(true)
                self.goDrawBlue:SetActive(false)
                self.goDrawPurple:SetActive(false)
                self.goDrawSSRYellow:SetActive(true)
                self.goDrawSSRBlue:SetActive(false)
                self.goDrawSSRPruple:SetActive(false)
                self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom2)
            else
                self.goDrawYellow:SetActive(false)
                self.goDrawBlue:SetActive(true)
                self.goDrawPurple:SetActive(false)
                self.goDrawSSRYellow:SetActive(false)
                self.goDrawSSRBlue:SetActive(true)
                self.goDrawSSRPruple:SetActive(false)
                self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom7)
            end
        else
            self.goProgress:SetActive(false)
        end
    else
        self.goProgress:SetActive(false)
        self:RefreshQualityProgress()
        self:RefreshNormalForge()
        if self:FindVxNode_zhizao_ani() then
            self.goImgTv:SetActive(true)
        end
        self.goGroupTv:SetActive(true)
        self.goZhizao:SetActive(false)
    end
    self:RefreshItemCost()
    self:RefreshDrawingItemState()
end

function HeroEquipForgeRoomUIMediator:RefreshQualityProgress(fixQuality)
    if fixQuality and fixQuality > 0 then
        for i = 1, #self.qualityBars do
            if i == fixQuality then
                self.qualityBars[i].fillAmount = 1
            else
                self.qualityBars[i].fillAmount = 0
            end
        end
    else
        local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
        local buildRandomId = buildCfg:EquipRandBuildId(self.selectUsbIndex)
        local randomCfg = ConfigRefer.EquipRandBuild:Find(buildRandomId)
        self.qualityList = {}
        self.weightCount = 0
        for i = 1, randomCfg:QualityRandLength() do
            local qualityRand = randomCfg:QualityRand(i)
            local weight = qualityRand:Weight()
            self.weightCount = self.weightCount + weight
            self.qualityList[qualityRand:Quality()] = weight
        end
        local progress = 0
        for i = 1, #self.qualityBars do
            if  self.qualityList[i] then
                local curProgress = self.qualityList[i] / self.weightCount
                progress = progress + curProgress
                self.qualityBars[i].fillAmount = progress
            else
                self.qualityBars[i].fillAmount = 0
            end
        end
    end
end

function HeroEquipForgeRoomUIMediator:OnBtnProgressClicked()
    local showText = I18N.Get("equip_build_now") .. "\n"
    if self.weightCount > 0 then
        local line = 1
        local totalLine = #self.qualityList
        for quality, weight in pairs(self.qualityList) do
            local qualityText = I18N.Get('equip_quality' .. quality)
            local weightPercent = string.format("%02d", (weight / self.weightCount) * 100) .. "%"
            showText = showText .. I18N.GetWithParams("equip_build_probability", qualityText) .. weightPercent
            if line < totalLine then
                showText = showText .. "\n"
                line = line + 1
            end
        end
    end
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnGroupProgress.transform, content = showText})
end

function HeroEquipForgeRoomUIMediator:RefreshItemCost()
    local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
    local buildRandomId = buildCfg:EquipRandBuildId(self.selectUsbIndex)
    local randomCfg = ConfigRefer.EquipRandBuild:Find(buildRandomId)
    local costItemGroupId = randomCfg:Consume()
    local itemArrays = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(costItemGroupId)
    local maxNum = ConfigRefer.ConstMain:EquipBuildMax()
    for _, costItem in ipairs(itemArrays) do
        local num = ModuleRefer.InventoryModule:GetAmountByConfigId(costItem.configCell:Id())
        local costNum = costItem.count
        local canForgeTimes = math.floor(num / costNum)
        if maxNum > canForgeTimes then
            maxNum = canForgeTimes
        end
    end
    if self.drawingData then
        local drawingNum = ModuleRefer.InventoryModule:GetAmountByConfigId(self.drawingData.configCell:Id())
        maxNum = math.min(maxNum, drawingNum)
    end
    self.maxNum = math.max(maxNum, 1)
    self.textQuantity.text = "/" .. self.maxNum
    local setBarData = {}
    setBarData.minNum = 1
    setBarData.maxNum = self.maxNum
    setBarData.oneStepNum = 1
    setBarData.curNum = 1
    setBarData.intervalTime = 0.1
    setBarData.callBack = function(value)
        self:OnEndEdit(value)
    end
    self.compChildSetBar:FeedData(setBarData)
    self.inputfieldInputQuantity.text = 1
    self.forgeTimes = 1
    self:RefreshCostItems(itemArrays)
end

function HeroEquipForgeRoomUIMediator:OnEndEdit(inputText)
    local inputNum = tonumber(inputText)
    if not inputNum or inputNum < 1 then
        inputNum = 1
    end
    if inputNum > self.maxNum then
        inputNum = self.maxNum
    end
    self.inputfieldInputQuantity.text = inputNum
    self.compChildSetBar.Lua:OutInputChangeSliderValue(inputNum)
    local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
    local buildRandomId = buildCfg:EquipRandBuildId(self.selectUsbIndex)
    local randomCfg = ConfigRefer.EquipRandBuild:Find(buildRandomId)
    local costItemGroupId = randomCfg:Consume()
    local itemArrays = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(costItemGroupId)
    self.forgeTimes = inputNum
    self:RefreshCostItems(itemArrays)
    self:RefreshDrawingItemState()
end

function HeroEquipForgeRoomUIMediator:RefreshCostItems(itemArrays)
    local forgeTimes = self.forgeTimes
    local isEnough = true
    for i = 1, #self.costItems do
        local isShow = i <= #itemArrays
        self.costItems[i]:SetVisible(isShow)
        if isShow then
            local itemId = itemArrays[i].configCell:Id()
            local data = {}
            data.itemId = itemId
            data.num1 = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
            data.num2 = itemArrays[i].count * forgeTimes
            data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
            self.costItems[i]:FeedData(data)
            if data.num1 < data.num2 then
                isEnough = false
            end
        end
    end
    self.compChildCompB:SetEnabled(isEnough)
end

function HeroEquipForgeRoomUIMediator:RefreshDrawingForge(fixQuality)
    local equipCfg = ModuleRefer.HeroModule:GetEquipByQualityAndType(fixQuality,  EQUIP_TYPE[self.selectUsbIndex])
    self.goGroupTv:SetActive(false)
    self:LoadSprite(equipCfg:Icon(), self.imgIconEquipment)

    if self:FindVxNode_zhizao_ani() then
        self:LoadSprite(equipCfg:Icon(), self.imgVxTubiao)
        self:LoadSprite(equipCfg:Icon(), self.imgVxTubiao1)
        self:LoadSprite(equipCfg:Icon(), self.imgVxTubiao2)
    end
    self.goGroupTv:SetActive(true)
end

function HeroEquipForgeRoomUIMediator:RefreshNormalForge()
    local buildCfg = ConfigRefer.HeroEquipBuild:Find(self.buildId)
    local buildRandomId = buildCfg:EquipRandBuildId(self.selectUsbIndex)
    local randomCfg = ConfigRefer.EquipRandBuild:Find(buildRandomId)
    local maxQaulity = randomCfg:QualityRand(1):Quality()
    local equipCfg = ModuleRefer.HeroModule:GetEquipByQualityAndType(maxQaulity,  EQUIP_TYPE[self.selectUsbIndex])
    self.goGroupTv:SetActive(false)
    self:LoadSprite(equipCfg:Icon(), self.imgIconEquipment)
    if self:FindVxNode_zhizao_ani() then
        self:LoadSprite(equipCfg:Icon(), self.imgVxTubiao)
        self:LoadSprite(equipCfg:Icon(), self.imgVxTubiao1)
        self:LoadSprite(equipCfg:Icon(), self.imgVxTubiao2)
    end
    self.goGroupTv:SetActive(true)
end

function HeroEquipForgeRoomUIMediator:OnSelectDrawing(data)
    self.drawingData = data
    self:RefreshDrawingItemState()
    self:RefreshUsbSuits()
end

function HeroEquipForgeRoomUIMediator:RefreshDrawingItemState()
    local isHasDrawing = self.drawingData and self.drawingData.configCell:Id() > 0
    if isHasDrawing then
        if ModuleRefer.InventoryModule:GetAmountByConfigId(self.drawingData.configCell:Id()) <= 0 then
            self:OnBtnDeleteClicked()
            return
        end
    end

    self.btnEmpty.gameObject:SetActive(not isHasDrawing)
    self.btnDelete.gameObject:SetActive(isHasDrawing)
    self.compChildItemStandardSEditor2.gameObject:SetActive(isHasDrawing)
    if isHasDrawing then
        local drawingData = {}
        drawingData.configCell = self.drawingData.configCell
        drawingData.addCount = self.forgeTimes
        drawingData.count = ModuleRefer.InventoryModule:GetAmountByConfigId(self.drawingData.configCell:Id())
        drawingData.showCount = true
        drawingData.showNumPair = true
        drawingData.showTips = true
        self.compChildItemStandardSEditor2:FeedData(drawingData)


        local drawingId = self.drawingData.configCell:DrawingId()
        local drawingCfg = ConfigRefer.Drawing:Find(drawingId)
        local fixQuality = drawingCfg:FixQuality()
        local fixEquipType = drawingCfg:FixEquipType()
        -- local fixSuitId = drawingCfg:FixSuitId()
        -- if fixSuitId > 0 then
        --     self.compChildItemStandardSEditor2.Lua:ChangeSuitIcon(ConfigRefer.Suit:Find(fixSuitId):Icon())
        -- end
        self.compChildItemStandardSEditor2.Lua:ChangeQuality(fixQuality)
        if fixEquipType > 0 then
            self.compChildItemStandardSEditor2.Lua:ChangeIcon(EQUIP_ICON[fixEquipType])
        end
    end
end

function HeroEquipForgeRoomUIMediator:OnBtnDeleteClicked()
    self.drawingData = nil
    self:RefreshUsbSuits()
end

function HeroEquipForgeRoomUIMediator:OnBtnBaseClicked()
    self.goTable:SetActive(false)
end

function HeroEquipForgeRoomUIMediator:OnBtnEmptyClicked()
    self.goTable:SetActive(true)
    local drawingItems = ModuleRefer.HeroModule:GetAllDrawingItems()
    self.tableviewproTableDrawing:Clear()
    for _, drawingItem in ipairs(drawingItems) do
        if drawingItem.count > 0 then
            self.tableviewproTableDrawing:AppendData(drawingItem)
        end
    end
    self.goEmpty:SetActive(#drawingItems == 0)
end

function HeroEquipForgeRoomUIMediator:OnBtnCompALU2EditorClicked()
    g_Game.UIManager:Open('UIFullscreenBlock')

    self.delayTimer = TimerUtility.DelayExecute(function()
        local param = BuildEquipParameter.new()
        param.args.BuildId = self.buildId
        param.args.Num = self.forgeTimes
        param.args.EquipType = EQUIP_TYPE[self.selectUsbIndex]
        if self.drawingData and self.drawingData.configCell:Id() > 0 then
            param.args.DrawingId = self.drawingData.configCell:Id()
        end
        param:Send(self.compChildCompB.transform)
    end, 1.5)
    self.compChildCompB:SetVisible(false)
    if self:FindVxNode_zhizao_ani() then
        self.goImgTv:SetActive(false)
    end
    self.goGroupTv:SetActive(false)
    self.goZhizao:SetActive(true)
    if self.drawingData and self.drawingData.configCell:Id() > 0 then
        local itemDrawingCfg = ConfigRefer.Item:Find(self.drawingData.configCell:Id())
        local drawingCfg = ConfigRefer.Drawing:Find(itemDrawingCfg:DrawingId())
        local fixQuality = drawingCfg:FixQuality()
        if fixQuality == HeroEquipQuality.Purple then
            self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom5)
        elseif fixQuality == HeroEquipQuality.Gold then
            self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
        else
            self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom6)
        end
    else
        self.aniZhizaoTrigger:PlayAll(FpAnimTriggerEvent.Custom6)
    end
end

function HeroEquipForgeRoomUIMediator:ShowBtn()
    g_Game.UIManager:CloseByName('UIFullscreenBlock')
    self.compChildCompB:SetVisible(true)
    self:RefreshUsbSuits()
end

return HeroEquipForgeRoomUIMediator