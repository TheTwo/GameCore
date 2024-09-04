local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ModuleRefer = require("ModuleRefer")
local I18N = require('I18N')
local ConfigRefer = require('ConfigRefer')
local ReceivePowerProgressRewardParameter = require('ReceivePowerProgressRewardParameter')
local UIHelper = require('UIHelper')
local PowerType = require('PowerType')
local UIStrengthenMediator = class('UIStrengthenMediator',BaseUIMediator)

local DEFAULT_MIN_SHOW = 5
local MAX_PREVIEW = 2

function UIStrengthenMediator:OnCreate()
    self.goTop = self:GameObject('p_top')
    self.compChildPopupBaseL = self:LuaObject('child_popup_base_l')
    self.tableviewproTableReward = self:TableViewPro('p_table_reward')
    self.textPowerNum = self:Text('p_text_power_num')
    self.textPowerRecommend = self:Text('p_text_power_recommend')
    self.imgIconPower = self:Image('p_icon_power')
    self.btnHero = self:Button('p_btn_hero', Delegate.GetOrCreate(self, self.OnBtnHeroClicked))
    self.textHero = self:Text('p_text_hero', I18N.Get("player_power_hero_name"))
    self.goImgSelectHero = self:GameObject('p_img_select_hero')
    self.animtriggerImgSelect = self:AnimTrigger('img_select')
    self.textSelectHero = self:Text('p_text_select_hero', I18N.Get("player_power_hero_name"))
    self.btnPet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnPetClicked))
    self.textPet = self:Text('p_text_pet', I18N.Get("player_power_pet_name"))
    self.goImgSelectPet = self:GameObject('p_img_select_pet')
    self.textSelectPet = self:Text('p_text_select_pet', I18N.Get("player_power_pet_name"))
    self.btnCity = self:Button('p_btn_city', Delegate.GetOrCreate(self, self.OnBtnCityClicked))
    self.textCity = self:Text('p_text_city', I18N.Get("player_power_city_name"))
    self.goImgSelectCity = self:GameObject('p_img_select_city')
    self.textSelectCity = self:Text('p_text_select_city', I18N.Get("player_power_city_name"))
    self.btnOther = self:Button('p_btn_other', Delegate.GetOrCreate(self, self.OnBtnOtherClicked))
    self.textOther = self:Text('p_text_other', I18N.Get("player_power_others_name"))
    self.goImgSelectOther = self:GameObject('p_img_select_other')
    self.textSelectOther = self:Text('p_text_select_other', I18N.Get("player_power_others_name"))
    self.tableviewproTable = self:TableViewPro('p_table')
    self.animtriggerVfxTrigger = self:AnimTrigger('vfxTrigger')

    self.selectTabs = {
       [PowerType.Hero] = self.goImgSelectHero,
       [PowerType.Pet] = self.goImgSelectPet,
       [PowerType.City] = self.goImgSelectCity,
    }
    self.btnOther.gameObject:SetActive(false)
end

function UIStrengthenMediator:OnOpened(param)
    local showTitle = false
    if param and param.isFromMain then
        showTitle = true
    end
    self.goTop:SetActive(showTitle)
    self.compChildPopupBaseL:FeedData({title = I18N.Get("power_dev_sys_name")})
    self.selectTabIndex = PowerType.Hero
    self:BuildTypeMap()
    self:RefreshAll()
    self:GetPriority()
    g_Game.ServiceManager:AddResponseCallback(ReceivePowerProgressRewardParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshAll))
end

function UIStrengthenMediator:RefreshAll()
    self:RefreshBasicInfo()
    self:RefreshRewardList()
    self:RefreshItems()
end

function UIStrengthenMediator:RefreshBasicInfo()
    local playerData =  ModuleRefer.PlayerModule:GetPlayer()
    local curPower = playerData.PlayerWrapper2.PlayerPower.TotalPower
    self.playerPower = curPower
    self.strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    self.textPowerNum.text = tostring(self.playerPower)
    local recommendCfg = ConfigRefer.RecommendPowerTable:Find(self.strongHoldLv)
    self.textPowerRecommend.text = I18N.Get("power_dev_rec_name") .. tostring(recommendCfg:TotalPower())
    if recommendCfg:TotalPower() > self.playerPower then
        g_Game.SpriteManager:LoadSprite("sp_slg_icon_medium", self.imgIconPower)
        self.textPowerRecommend.color = UIHelper.TryParseHtmlString("#ffa800")
    else
        g_Game.SpriteManager:LoadSprite("sp_slg_icon_easy", self.imgIconPower)
        self.textPowerRecommend.color = UIHelper.TryParseHtmlString("#97E750")
    end
end

function UIStrengthenMediator:RefreshRewardList()
    self.tableviewproTableReward:Clear()
    local playerData =  ModuleRefer.PlayerModule:GetPlayer()
    local curPowerIndex = playerData.PlayerWrapper2.PowerProgress.ReachedMaxPowerProgressId or 0
    local showCount = curPowerIndex + MAX_PREVIEW
    if showCount < DEFAULT_MIN_SHOW then
        showCount = DEFAULT_MIN_SHOW
    end
    local num = 0
    local focusIndex = 0

    local canRewardIndexs = playerData.PlayerWrapper2.PowerProgress.CanReceiveRewardProgressIds
    for _, config in ConfigRefer.PowerProgress:ipairs() do
        if num <= showCount then
            num = num + 1
            if focusIndex == 0 and curPowerIndex >= config:Id() and table.ContainsValue(canRewardIndexs, config:Id()) then
                focusIndex = config:Id()
            elseif focusIndex == 0 and curPowerIndex == num then
                focusIndex = config:Id()
            end
            self.tableviewproTableReward:AppendData(config:Id())
        end
    end

    self.tableviewproTableReward:RefreshAllShownItem(false)
    if focusIndex > 0 then
        self.tableviewproTableReward:SetFocusData(focusIndex)
    end
end

function UIStrengthenMediator:BuildTypeMap()
    self.typeMap = {}
    for _, config in ConfigRefer.PowerTypeMap:ipairs() do
        for i = 1, config:PowerSubTypesLength() do
            self.typeMap[#self.typeMap + 1] = config:PowerSubTypes(i)
        end
    end
end

function UIStrengthenMediator:RefreshItems()
    for index, select in pairs(self.selectTabs) do
        select:SetActive(index == self.selectTabIndex)
    end
    local showTypes = self.typeMap
    local showIndexs = {}
    local strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    local recommendCfg = ConfigRefer.RecommendPowerTable:Find(strongHoldLv)
    for i = 1, recommendCfg:SubTypePowersLength() do
        local subTypePower = recommendCfg:SubTypePowers(i)
        local config = self:GetProviderConfig(subTypePower)
        if config then
            local subType = subTypePower:SubType()
            if table.ContainsValue(showTypes, subType) then
                showIndexs[#showIndexs + 1] = {index = i, config = config}
            end
        end
    end
    local playerData =  ModuleRefer.PlayerModule:GetPlayer()
    local subTypePowers = playerData.PlayerWrapper2.PlayerPower.SubTypePowers
    local minSubType = nil
    local minPriority = nil
    local minPercent = math.maxinteger
    local results = {}
    local priorityIndex = self:GetPriority()
    for _, info in ipairs(showIndexs) do
        local index = info.index
        local subTypePower = recommendCfg:SubTypePowers(index)
        local subType = subTypePower:SubType()
        local subPower = subTypePower:PowerValue()
        local curPower = subTypePowers[subType] or 0
        if subPower <= 0 then
            subPower = 1
        end
        local percent = curPower / subPower
        if percent < minPercent and percent < 1 then
            minPercent = percent
            minSubType = subType
            minPriority = info.config:Priority(priorityIndex)
        end
        if percent == minPercent and minPriority > info.config:Priority(priorityIndex) then
            minSubType = subType
            minPriority = info.config:Priority(priorityIndex)
        end
        results[#results + 1] = {index = index, percent = math.floor(percent * 1000), config = info.config}
    end
    local sortfunc = function(a, b)
        if a.config:Priority(priorityIndex) ~ b.config:Priority(priorityIndex) then
            return a.config:Priority(priorityIndex) < b.config:Priority(priorityIndex)
        else
            return a.index < b.index
        end
    end
    table.sort(results, sortfunc)
    self.tableviewproTable:Clear()
    for _, info in ipairs(results) do
        self.tableviewproTable:AppendData({index = info.index, minSubType = minSubType, config = info.config})
    end
end

function UIStrengthenMediator:GetPriority()
    local priorityIndex = 1
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local payNumber = player.PlayerWrapper2.PlayerPay.AccPay or 0
    local payConstNumber = ConfigRefer.ConstMain:PlayerPaymentTierParamLength()
    for i = 1, payConstNumber do
        local curPay = ConfigRefer.ConstMain:PlayerPaymentTierParam(i)
        if i < payConstNumber then
            local nextPay = ConfigRefer.ConstMain:PlayerPaymentTierParam(i + 1)
            if payNumber >= nextPay and payNumber < curPay then
                priorityIndex = i + 1
            elseif payNumber >= curPay then
                priorityIndex = 1
            end
        elseif i == payConstNumber then
            if payNumber <= curPay then
                priorityIndex = payConstNumber + 1
            end
        end
    end
    return priorityIndex
end

function UIStrengthenMediator:GetProviderConfig(subTypePower)
    for _, config in ConfigRefer.PowerProgressResource:ipairs() do
        if config:PowerSubTypes() == subTypePower:SubType() then
            local sysIndex = config:Unlock()
            if sysIndex and sysIndex > 0 then
                local isOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex)
                if isOpen then
                    return config
                end
            else
                return config
            end
        end
    end
    return nil
end

function UIStrengthenMediator:OnClose(param)
    g_Game.ServiceManager:RemoveResponseCallback(ReceivePowerProgressRewardParameter.GetMsgId(), Delegate.GetOrCreate(self,self.RefreshAll))
end

function UIStrengthenMediator:OnBtnHeroClicked(args)
    self.selectTabIndex = PowerType.Hero
    self:RefreshItems()
end
function UIStrengthenMediator:OnBtnPetClicked(args)
    self.selectTabIndex = PowerType.Pet
    self:RefreshItems()
end
function UIStrengthenMediator:OnBtnCityClicked(args)
    self.selectTabIndex = PowerType.City
    self:RefreshItems()
end
function UIStrengthenMediator:OnBtnOtherClicked(args)
    -- body
end

return UIStrengthenMediator
