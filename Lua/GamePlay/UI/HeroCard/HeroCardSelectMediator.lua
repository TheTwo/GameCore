local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")
local FunctionClass = require('FunctionClass')
local UIMediatorNames = require('UIMediatorNames')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local GachaConfigType = require('GachaConfigType')
local DBEntityPath = require('DBEntityPath')
local TimerUtility = require('TimerUtility')
local TimeFormatter = require('TimeFormatter')
local AttackDistanceType = require('AttackDistanceType')
local HeroUIUtilities = require('HeroUIUtilities')
local ChooseGachaItemParameter = require('ChooseGachaItemParameter')
local HeroCardSelectMediator = class('HeroCardSelectMediator',BaseUIMediator)

function HeroCardSelectMediator:OnCreate()
    BaseUIMediator.OnCreate(self)
    self.textTitle = self:Text('p_text_title', I18N.Get("gacha_select_title"))
    self.textHint = self:Text('p_text_hint')
    self.sliderProgress = self:Slider('p_progress')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.textNum = self:Text('p_text_num')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.goGroupSkill = self:GameObject('p_group_skill')
    self.goProgressFull = self:GameObject('p_progress_full')
    self.btnSkill = self:Button('p_btn_skill', Delegate.GetOrCreate(self, self.OnBtnSkillClicked))
    self.imgImgSkill = self:Image('p_img_skill')
    self.btnDetailSkill = self:Button('p_btn_detail_skill', Delegate.GetOrCreate(self, self.OnBtnDetailSkillClicked))
    self.goHaveSkill = self:GameObject('p_have_skill')
    self.textHaveSkill = self:Text('p_text_have_skill', I18N.Get("gacha_select_got"))
    self.goSelectedSkill = self:GameObject('p_selected_skill')
    self.goGroupHero = self:GameObject('p_group_hero')
    self.btnHero = self:Button('p_btn_hero', Delegate.GetOrCreate(self, self.OnBtnHeroClicked))
    self.imgImgHero = self:Image('p_img_hero')
    self.btnDetailHero = self:Button('p_btn_detail_hero', Delegate.GetOrCreate(self, self.OnBtnDetailHeroClicked))
    self.goHaveHero = self:GameObject('p_have_hero')
    self.textHaveHero = self:Text('p_text_have_hero', I18N.Get("gacha_select_got"))
    self.goSelectedHero = self:GameObject('p_selected_hero')
    self.goGroupPet = self:GameObject('p_group_pet')
    self.btnPet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnPetClicked))
    self.imgImgPet = self:Image('p_img_pet')
    self.btnDetailPet = self:Button('p_btn_detail_pet', Delegate.GetOrCreate(self, self.OnBtnDetailPetClicked))
    self.goHavePet = self:GameObject('p_have_pet')
    self.textHavePet = self:Text('p_text_have_pet', I18N.Get("gacha_select_got"))
    self.goSelectedPet = self:GameObject('p_selected_pet')
    self.textFrush = self:Text('p_text_frush', I18N.Get("gacha_select_refresh"))
    self.textTime = self:Text('p_text_time')
    self.textFrush1 = self:Text('p_text_frush_1', I18N.Get("gacha_select_refresh_tips"))

    self.imgSelectPet = self:Image('p_img_selected_pet')
    self.imgSelectHero = self:Image('p_img_selected_hero')
    self.goEmpty = self:GameObject('p_img_empty')

    self.textNameSkill = self:Text('p_text_name_skill')
    self.imgIconTypeSkill = self:Image('p_icon_type_skill')
    self.textQuantitySkill = self:Text('p_text_quantity_skill')
    self.textNameHero = self:Text('p_text_name')
    self.imgIconTypeHero = self:Image('p_icon_type_hero')
    self.textQuantityHero = self:Text('p_text_quantity_hero')
    self.textNamePet = self:Text('p_text_name_pet')
    self.imgIconTypePet = self:Image('p_icon_type_pet')
    self.textQuantityPet = self:Text('p_text_quantity_pet')
    self.goBaseTypeSkill = self:GameObject('p_base_type_skill')
    self.goBaseTypeHero = self:GameObject('p_base_type')
    self.goBaseTypePet = self:GameObject('p_base_type_pet')

    self.goHintSelectedSkill = self:GameObject('p_hint_selected_skill')
    self.textSelectedSkill = self:Text('p_text_selected_skill', I18N.Get("gacha_select_already"))
    self.goHintSelectedHero = self:GameObject('p_hint_selected_hero')
    self.textSelected = self:Text('p_text_selected', I18N.Get("gacha_select_already"))
    self.goHintSelectedPet = self:GameObject('p_hint_selected_pet')
    self.textSelectedPet = self:Text('p_text_selected_pet', I18N.Get("gacha_select_already"))
    self.btnCompB = self:Button('p_comp_btn_b', Delegate.GetOrCreate(self, self.OnBtnCompBClicked))
    self.textText = self:Text('p_text', I18N.Get("gacha_select_btn"))

    self.goGroupSkill:SetActive(false)
    self.goGroupHero:SetActive(false)
    self.goGroupPet:SetActive(false)
    self.chosenItems = {self.goGroupSkill, self.goGroupHero, self.goGroupPet}
    self.chosenIcons = {self.imgImgSkill, self.imgImgHero, self.imgImgPet}
    self.chosenHavas = {self.goHaveSkill, self.goHaveHero, self.goHavePet}
    self.choseSelects = {self.goSelectedSkill, self.goSelectedHero, self.goSelectedPet}
    self.choseItemNames = {self.textNameSkill, self.textNameHero, self.textNamePet}
    self.choseIconTypes = {self.imgIconTypeSkill, self.imgIconTypeHero, self.imgIconTypePet}
    self.choseQuantitys = {self.textQuantitySkill, self.textQuantityHero, self.textQuantityPet}
    self.goBaseTypes = {self.goBaseTypeSkill, self.goBaseTypeHero, self.goBaseTypePet}
    self.goHints = {self.goHintSelectedSkill, self.goHintSelectedHero, self.goHintSelectedPet}
end

function HeroCardSelectMediator:OnOpened(selectType)
    self.selectType = selectType
    self:RefreshDetails()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Gacha.MsgPath, Delegate.GetOrCreate(self, self.RefreshDetails))
    g_Game.ServiceManager:AddResponseCallback(ChooseGachaItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.RefreshChosenItems))
    self:RefreshSelectBtnState()
end

function HeroCardSelectMediator:RefreshDetails()
    if not self.selectType then
        return
    end
    local gachaTypeCfg = ConfigRefer.GachaType:Find(self.selectType)
    if gachaTypeCfg:Type() ~= GachaConfigType.Advanced then
        self:CloseSelf()
    end
    local maxSelect = gachaTypeCfg:ChosenLoopTimes()
    local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
    local gachaPoolInfo = (gachaInfo.Data or {})[self.selectType]
    self.customSSRTimes = gachaPoolInfo and gachaPoolInfo.SSRCount or 0
    self.textNum.text = self.customSSRTimes .. "/" .. maxSelect
    local isMax = self.customSSRTimes >= maxSelect
    self.goProgressFull:SetActive(isMax)
    if isMax then
        self.textHint.text = maxSelect .. I18N.Get("gacha_select_next_tips_1")
    else
        self.textHint.text = I18N.GetWithParams("gacha_select_subtitle", maxSelect)
    end
    self.sliderProgress.value = self.customSSRTimes / maxSelect
    local chosenCfgId = gachaTypeCfg:ChosenConfigId()
    local chosenCfg = ConfigRefer.GachaChosenConfig:Find(chosenCfgId)
    local curPeriodIndex = gachaPoolInfo and gachaPoolInfo.ChosenPeriodIndex or 0
    local gachaChosenPeriodItems = chosenCfg:Period(curPeriodIndex + 1)
    self.choseItemIds = {}
    for i = 1, gachaChosenPeriodItems:ItemIdLength() do
        self.choseItemIds[#self.choseItemIds + 1] = gachaChosenPeriodItems:ItemId(i)
    end
    local curSelectItemId = gachaPoolInfo and gachaPoolInfo.ChosenItem or 0
    local isHasSelect = curSelectItemId > 0
    self.imgSelectPet.gameObject:SetActive(isHasSelect)
    self.imgSelectHero.gameObject:SetActive(isHasSelect)
    self.goEmpty:SetActive(not isHasSelect)
    for i = 1, #self.chosenItems do
        local itemId = self.choseItemIds[i]
        local isShow = itemId and itemId > 0
        self.chosenItems[i]:SetActive(isShow)
        if isShow then
            local itemCfg = ConfigRefer.Item:Find(itemId)
            local isSelect = curSelectItemId == itemId
            if itemCfg:FunctionClass() == FunctionClass.AddHero then
                local heroId = tonumber(itemCfg:UseParam(1))
                local heroCfg = ConfigRefer.Heroes:Find(heroId)
                local heroResCfg = heroCfg and ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg()) or nil
                self:LoadSprite(heroResCfg:BodyPaint(), self.chosenIcons[i])
                self.choseQuantitys[i].text = I18N.Get(HeroUIUtilities.GetQualityTextColorless(heroCfg:Quality()))
                self.choseItemNames[i].text = I18N.Get(heroCfg:Name())
                self.goBaseTypes[i]:SetActive(true)
                if heroCfg:AttackDistance() == AttackDistanceType.Short then
                    g_Game.SpriteManager:LoadSprite("sp_icon_survivor_type_1", self.choseIconTypes[i])
                else
                    g_Game.SpriteManager:LoadSprite("sp_icon_survivor_type_3", self.choseIconTypes[i])
                end
                if isSelect then
                    self.imgSelectPet.gameObject:SetActive(false)
                    self:LoadSprite(heroResCfg:BodyPaint(), self.imgSelectHero)
                end
            elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
                local petId = tonumber(itemCfg:UseParam(1))
                local petCfg = ConfigRefer.Pet:Find(petId)
                self:LoadSprite(petCfg:ShowPortrait(), self.chosenIcons[i])
                self.choseQuantitys[i].text = I18N.Get(HeroUIUtilities.GetQualityTextColorless(petCfg:Quality() - 1))
                self.choseItemNames[i].text = I18N.Get(petCfg:Name())
                self.goBaseTypes[i]:SetActive(false)
                if isSelect then
                    self.imgSelectHero.gameObject:SetActive(false)
                    self:LoadSprite(petCfg:ShowPortrait(), self.imgSelectPet)
                end
            else
                g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.chosenIcons[i])
                self.choseQuantitys[i].text = I18N.Get(HeroUIUtilities.GetQualityTextColorless(itemCfg:Quality() - 2))
                self.choseItemNames[i].text = I18N.Get(itemCfg:NameKey())
                self.goBaseTypes[i]:SetActive(false)
                if isSelect then
                    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgSelect)
                end
            end
            local isHave = self:CheckIsHave(itemId)
            self.chosenHavas[i]:SetActive(isHave)
            self.choseSelects[i]:SetActive(isSelect)
            self.goHints[i]:SetActive(isSelect)
        end
    end
    local endTime = gachaPoolInfo and gachaPoolInfo.ChosenPeriodEndTime.timeSeconds or 0
    local lastTime = endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    self.textFrush.gameObject:SetActive(lastTime > 0)
    if lastTime > 0 then
        self.textTime.text = TimeFormatter.SimpleFormatTimeWithDay(lastTime)
        self:StopTimer()
        self.timer = TimerUtility.IntervalRepeat(function()
            local last = endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
            if last > 0 then
                self.textTime.text = TimeFormatter.SimpleFormatTimeWithDay(last)
            else
                self:StopTimer()
            end
        end, 1, -1)
    end
end

function HeroCardSelectMediator:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

function HeroCardSelectMediator:OnClose()
    self:StopTimer()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Gacha.MsgPath, Delegate.GetOrCreate(self, self.RefreshDetails))
    g_Game.ServiceManager:RemoveResponseCallback(ChooseGachaItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.RefreshChosenItems))
end

function HeroCardSelectMediator:CheckIsHave(itemId)
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(itemCfg:UseParam(1))
        local heroCfg = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
        return heroCfg and heroCfg:HasHero()
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        local petId = tonumber(itemCfg:UseParam(1))
        return ModuleRefer.PetModule:HasPetByCfgId(petId)
    else
        return false
    end
end

function HeroCardSelectMediator:RefreshChosenItems(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    local request = rpc.request
    local curSelectItemId = request.ItemId
    for i = 1, #self.chosenItems do
        local itemId = self.choseItemIds[i]
        if itemId and itemId > 0 then
            local isSelect = curSelectItemId == itemId
            self.goHints[i]:SetActive(isSelect)
        end
    end
    for i = 1, #self.chosenItems do
        self.choseSelects[i]:SetActive(false)
    end
    self:RefreshSelectBtnState()
end

function HeroCardSelectMediator:RefreshChoseSelect(index)
    for i = 1, #self.chosenItems do
        self.choseSelects[i]:SetActive(i == index)
    end
    self:RefreshSelectBtnState()
end

function HeroCardSelectMediator:RefreshSelectBtnState()
    local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
    local gachaPoolInfo = (gachaInfo.Data or {})[self.selectType]
    local curSelectItemId = gachaPoolInfo and gachaPoolInfo.ChosenItem or 0
    self.btnCompB.gameObject:SetActive(self.choseItemId and curSelectItemId ~= self.choseItemId)
end

function HeroCardSelectMediator:OnBtnDetailClicked(args)
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnDetail.transform, content = I18N.Get("gacha_select_info")})
end

function HeroCardSelectMediator:OnBtnCloseClicked(args)
    self:BackToPrevious()
end

function HeroCardSelectMediator:OnBtnSkillClicked(args)
    self.choseItemId = self.choseItemIds[1]
    self:RefreshChoseSelect(1)
end

function HeroCardSelectMediator:OnBtnDetailSkillClicked(args)
    local itemId = self.choseItemIds[1]
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(itemCfg:UseParam(1))
        g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = heroId})
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        local petId = tonumber(itemCfg:UseParam(1))
    end
end

function HeroCardSelectMediator:OnBtnHeroClicked(args)
    self.choseItemId = self.choseItemIds[2]
    self:RefreshChoseSelect(2)
end

function HeroCardSelectMediator:OnBtnDetailHeroClicked(args)
    local itemId = self.choseItemIds[2]
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(itemCfg:UseParam(1))
        g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = heroId})
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        local petId = tonumber(itemCfg:UseParam(1))
    end
end

function HeroCardSelectMediator:OnBtnPetClicked(args)
    self.choseItemId = self.choseItemIds[3]
    self:RefreshChoseSelect(3)
end

function HeroCardSelectMediator:OnBtnDetailPetClicked(args)
    local itemId = self.choseItemIds[3]
    local itemCfg = ConfigRefer.Item:Find(itemId)
    if itemCfg:FunctionClass() == FunctionClass.AddHero then
        local heroId = tonumber(itemCfg:UseParam(1))
        g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = heroId})
    elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
        local petId = tonumber(itemCfg:UseParam(1))
    end
end

function HeroCardSelectMediator:CheckConfirm(itemId)
    if self.customSSRTimes > 0 then
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("gacha_select_re_tips_1")
        dialogParam.content = I18N.GetWithParams("gacha_select_re_tips_1_des")
        dialogParam.onConfirm = function()
            self:DoChoose(itemId)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        self:DoChoose(itemId)
    end
end

function HeroCardSelectMediator:DoChoose(itemId)
    local param = ChooseGachaItemParameter.new()
    param.args.GachaTypeTid = self.selectType
    param.args.ItemId = itemId
    param:SendWithFullScreenLock()
end


function HeroCardSelectMediator:OnBtnCompBClicked(args)
    if not self.choseItemId then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("gacha_select_tips_2"))
        return
    end
    self:CheckConfirm(self.choseItemId)
end

return HeroCardSelectMediator