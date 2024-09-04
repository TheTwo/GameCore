local BaseModule = require('BaseModule')
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local KingdomMapUtils = require('KingdomMapUtils')
local HeroQuality = require('HeroQuality')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local FunctionClass = require('FunctionClass')
local ModuleRefer = require('ModuleRefer')
local DrawGachaParameter = require('DrawGachaParameter')
local BehaviourManager = require('BehaviourManager')
local TimerUtility = require("TimerUtility")
local PackType = require('PackType')
local ExchangeMultiItemParameter = require('ExchangeMultiItemParameter')
local GachaConfigType = require('GachaConfigType')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
---@class HeroCardModule
local HeroCardModule = class('HeroCardModule',BaseModule)

local HERO_GET_TIMELINE = {
    "timeline_dog_pulls_cart_02_men_lv",
    "timeline_dog_pulls_cart_02_men_lan",
    "timeline_dog_pulls_cart_02_men_zi",
    "timeline_dog_pulls_cart_02_men_jin",
}

local PET_GET_TIMELINE = {
    "timeline_dog_pulls_cart_02_xiangzi_lv",
    "timeline_dog_pulls_cart_02_xiangzi_lan",
    "timeline_dog_pulls_cart_02_xiangzi_zi",
    "timeline_dog_pulls_cart_02_xiangzi_jin",
}

local TEN_GACHA_TIMELINE= {
    "",
    "",
    "timeline_dog_pulls_10_cart_03_zi",
    "timeline_dog_pulls_10_cart_02_jin",
}

function HeroCardModule:ctor()
    self.isShowSelect = true
    self.isTen = false
    self.waitingForResult = false
    self.otherDogIndex = nil
    self.companionItems = {}
    self.showResultList = {}

    self.createHelper = nil
    self.handle = nil
    self.timelineGo = nil
    self.timelineDirector = nil
    self.timelineWrapper = nil
    self.plotDirector = nil

    self.loadTimelineFailed = false
    self.curHeroPopRuntimeId = nil
end

function HeroCardModule:OnRegister()
    self.isShowSelect = true
    self.createHelper = PooledGameObjectCreateHelper.Create("GachaHero")
    g_Game.ServiceManager:AddResponseCallback(DrawGachaParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetGachaResults))
end

function HeroCardModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(DrawGachaParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnGetGachaResults))
end

function HeroCardModule:IsShowSelect()
    return self.isShowSelect
end

function HeroCardModule:SetIsShowSelect(isShow)
    self.isShowSelect = isShow
end

function HeroCardModule:GetSkipState()
    return g_Game.PlayerPrefsEx:GetIntByUid("GachaIsSkip") == 1
end

function HeroCardModule:SetSkipState(isSkip)
    g_Game.PlayerPrefsEx:SetIntByUid("GachaIsSkip", isSkip and 1 or 0)
end

function HeroCardModule:CheckIsOpenGacha()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.Global_gacha)
end

function HeroCardModule:GetFreeGachaType()
    local freeType = nil
    for _, config in ConfigRefer.GachaType:ipairs() do
        if config:Type() == GachaConfigType.Advanced then
            freeType = config:Id()
        end
    end
    return freeType
end

function HeroCardModule:GetTenDrawCostItemId()
    local freeType = self:GetFreeGachaType()
    local gachaId = ConfigRefer.GachaType:Find(freeType):GachaId()
    local tenDrawCost = ConfigRefer.Gacha:Find(gachaId):TenDrawCost()
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(tenDrawCost)[1]
    return costItem.configCell:Id()
end

function HeroCardModule:GetTenDrawCostItemNum()
    return ModuleRefer.InventoryModule:GetAmountByConfigId(self:GetTenDrawCostItemId())
end

function HeroCardModule:GetFreeTime()
    local freeType = self:GetFreeGachaType()
    local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
    local gachaPoolInfo = (gachaInfo.Data or {})[freeType]
    local freeTime = gachaPoolInfo and gachaPoolInfo.NextFreeTime or 0
    return freeTime
end

function HeroCardModule:CheckIsFirstGacha()
    local freeType = self:GetFreeGachaType()
    local gachaInfo = ModuleRefer.HeroCardModule:GetGachaInfo()
    local gachaPoolInfo = (gachaInfo.Data or {})[freeType]
    local recordList = gachaPoolInfo and gachaPoolInfo.Record or {}
    return #recordList == 0
end

---@return wds.Gacha
function HeroCardModule:GetGachaInfo()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if player then
	    return player.PlayerWrapper2.Gacha
    end
    return {}
end

function HeroCardModule:LoadTimeline(timelineName, callback)
    local parent = KingdomMapUtils.GetMapSystem().Parent
    self.handle = self.createHelper:Create(timelineName, parent, function(go)
        if go then
            self.loadTimelineFailed = false
            self.timelineGo = go
            self.timelineGo.transform.position = CS.UnityEngine.Vector3(500, 0, 500)
            go:SetActive(false)
            self.timelineDirector = go:GetComponentInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
            self.timelineWrapper = self.timelineDirector.gameObject:AddComponent(typeof(CS.PlayableDirectorListenerWrapper))
            self.timelineWrapper.targetDirector = self.timelineDirector
	        self:ShowTimeline(callback)
            local cardMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardMediator)
            if cardMediator then
                cardMediator:SetVisible(false)
                if cardMediator.ui3dModel then
                    cardMediator.ui3dModel:ChangeEnvState(false)
                end
            end
            g_Game.UIManager:Open(UIMediatorNames.HeroCardSkipMediator)
            local camera = go:GetComponentInChildren(typeof(CS.UnityEngine.Camera), true)
            camera.enabled = true

            local behaviourManager = BehaviourManager.Instance()
            self.plotDirector = self.timelineGo:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector), true)
            self.plotDirector.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
            self.plotDirector.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
            self.plotDirector.OnBehaviourPause = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourPause)
            self.plotDirector.OnBehaviourResume = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourResume)
            self.plotDirector.OnBehaviourTick = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourTick)
        else
            self.loadTimelineFailed = true
            callback()
        end
    end)
    if self.loadTimelineFailed then
        self.handle = nil
    end
end

function HeroCardModule:ShowTimeline(callback)
    g_Game.EventManager:TriggerEvent(EventConst.CHANGE_CAMERA_STATE, false)
    self.timelineWrapper.stoppedCallback = Delegate.GetOrCreate(self, callback)
    self.timelineWrapper:AddStoppedListener()
    self.timelineGo:SetActive(true)
end

function HeroCardModule:OnTimelineComplete()
    BehaviourManager.Instance():CleanUp()
    self.timelineWrapper.stoppedCallback = nil
	self.timelineWrapper:RemoveStoppedListener()
    self.timelineGo:SetActive(false)
    if self.handle then
        self.createHelper:Delete(self.handle)
    end
    self.handle = nil
    local quality = self:GetTopQuality()
    if self:IsTenGacha() then
        quality = math.max(quality, 3)
        self:LoadTimeline(TEN_GACHA_TIMELINE[quality], function() self:OnAllTimelineComplete() end)
    else
        if self:HasHero() or self:HasPet() then
            self:LoadTimeline(HERO_GET_TIMELINE[quality], function() self:OnAllTimelineComplete() end)
        else
            self:LoadTimeline(PET_GET_TIMELINE[quality], function() self:OnAllTimelineComplete() end)
        end
    end
end

function HeroCardModule:OnAllTimelineComplete()
    BehaviourManager.Instance():CleanUp()
    self.timelineWrapper.stoppedCallback = nil
	self.timelineWrapper:RemoveStoppedListener()
    self.timelineGo:SetActive(false)
    if self.handle then
        self.createHelper:Delete(self.handle)
    end
    self.handle = nil
    self:ShowResult()
    local cardSkipMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardSkipMediator)
    if cardSkipMediator then
        cardSkipMediator:ShowBase()
    end
    local cardMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HeroCardMediator)
    if cardMediator then
        cardMediator:SetVisible(true)
        if cardMediator.ui3dModel then
            cardMediator.ui3dModel:ChangeEnvState(true)
        end
    end
    ModuleRefer.ToastModule:IngoreBlockToast()
    ModuleRefer.ToastModule:TriggerCacheMarqueeToast()
    g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_DOG_INIT)
    g_Game.EventManager:TriggerEvent(EventConst.CHANGE_CAMERA_STATE, true)
end

function HeroCardModule:CloseSkipCg()
    g_Game.UIManager:CloseByName(UIMediatorNames.HeroCardSkipMediator)
end

function HeroCardModule:SkipTimeline()
    self.plotDirector:Stop()
    self.timelineDirector:Stop()
end

function HeroCardModule:DoGacha(costItem, drawType, selectType, isFree)
    ModuleRefer.ToastModule:BlockPower()
    local costItemId = costItem.configCell:Id()
    local costItemCount = costItem.count
    local curHaveCount = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
    if costItemCount > curHaveCount and not isFree then
        local lackNum = costItemCount - curHaveCount
        local itemCfg = costItem.configCell
        local getMoreCfg = ConfigRefer.GetMore:Find(itemCfg:GetMoreConfig())
        local coinId = getMoreCfg:Exchange():Currency()
        --local coinName = I18N.Get(ConfigRefer.Item:Find(coinId):NameKey())
        local coinCostNum = getMoreCfg:Exchange():CurrencyCount() * lackNum
        local coinInventoryNum = ModuleRefer.InventoryModule:GetAmountByConfigId(coinId)
        g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
        local dialogParam = {}
        dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        dialogParam.title = I18N.Get("getmore_title_c")
        --晶珀不足
        if coinCostNum > coinInventoryNum then
            dialogParam.onConfirm = function()
                local unlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(21)
                if not unlocked then
                    ModuleRefer.NewFunctionUnlockModule:ShowLockedTipToast(21)
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.ActivityShopMediator, {tabId = 9})
                return true
            end
            local content = UIHelper.GetColoredText("[a02]x" .. coinCostNum, ColorConsts.warning)
            dialogParam.content = I18N.GetWithParams("gacha_costandbuy", content, "[a05]" .. lackNum)
            dialogParam.confirmLabel = I18N.Get("gacha_gotobuy")
        else
            dialogParam.onConfirm = function()
                local parameter = ExchangeMultiItemParameter.new()
                parameter.args.TargetItemConfigId:Add(costItemId)
                parameter.args.TargetItemCount:Add(lackNum)
                parameter:Send()
                return true
            end
            dialogParam.content = I18N.GetWithParams("gacha_costandbuy", "[a02]x" .. coinCostNum, "[a05]" .. lackNum)
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
    else
        g_Game.UIManager:Open(UIMediatorNames.HeroCardFeedMediator, {selectType = selectType, isOne = drawType == wrpc.GachaDrawType.GachaDrawType_ONE})
        g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, false)
        g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_FEED_DRAG_START, drawType == wrpc.GachaDrawType.GachaDrawType_ONE)
        local param = DrawGachaParameter.new()
        param.args.GachaTypeTid = selectType
        param.args.Typo = drawType
        param:SendWithFullScreenLock()
        self.result = nil
    end
end

function HeroCardModule:OnGetGachaResults(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    self.isTen = rpc.request.Typo == wrpc.GachaDrawType.GachaDrawType_TEN
    self.result = reply.Result
    if self.waitingForResult then
        self.waitingForResult = false
        self:PlayGachaResults()
    end
end

function HeroCardModule:PlayGachaResults()
    if not self.result then
        self.waitingForResult = true
        return
    end
    self.waitingForResult = false
    local isSkip = self:GetSkipState()
    if isSkip then
        local quality = self:GetTopQuality()
        if self:HasHero() or self:HasPet() then
            self:LoadTimeline(HERO_GET_TIMELINE[quality], function() self:OnAllTimelineComplete() end)
        else
            self:LoadTimeline(PET_GET_TIMELINE[quality], function() self:OnAllTimelineComplete() end)
        end
        return
    end
    if self.handle then
        return
    end
    if self.isTen then
        self:LoadTimeline("timeline_dog_pulls_10_cart_01", function() self:OnTimelineComplete() end)
    else
        self:LoadTimeline("timeline_dog_pulls_cart_01", function() self:OnTimelineComplete() end)
    end
end

function HeroCardModule:GetOtherDogIndex()
    return self.otherDogIndex
end

function HeroCardModule:IsTenGacha()
    return self.isTen
end

function HeroCardModule:ChooseOtherDog()
    self.otherDogIndex = nil
    if self.result then
        local quality = self:GetTopQuality() + 1
        local hasHero = self:HasHero()
        local hasPet = self:HasPet()
        local randomList = {}
        for _, config in ConfigRefer.GachaDogAction:ipairs() do
            randomList[#randomList + 1] = {cfg = config, weight = config:Priority()}
        end
        local sortfunc = function(a, b)
            return a.weight < b.weight
        end
        table.sort(randomList, sortfunc)
        for _, randomInfo in ipairs(randomList) do
            if not self.otherDogIndex then
                if hasHero and randomInfo.cfg:GachaPackType() == PackType.Hero then
                    if quality == randomInfo.cfg:GachaQuality() then
                        self.otherDogIndex = self:RandomIndex(randomInfo.cfg)
                    end
                elseif hasPet and randomInfo.cfg:GachaPackType() == PackType.Pet then
                    if quality == randomInfo.cfg:GachaQuality() then
                        self.otherDogIndex = self:RandomIndex(randomInfo.cfg)
                    end
                elseif not hasHero and not hasPet and randomInfo.cfg:GachaPackType() == PackType.Other then
                    if quality == randomInfo.cfg:GachaQuality() then
                        self.otherDogIndex = self:RandomIndex(randomInfo.cfg)
                    end
                end
            end
        end
    end
    if not self.otherDogIndex then
        self.otherDogIndex = math.random(1, 4)
    end
end

function HeroCardModule:RandomIndex(cfg)
    local per = math.random(0, 100)
    local sectionEnd = 0
    for i = 1, cfg:ActionInfoLength() do
        local info = cfg:ActionInfo(i)
        sectionEnd = sectionEnd + info:Weight()
        if sectionEnd >= per then
            return tonumber(info:Action())
        end
    end
    return nil
end

function HeroCardModule:HasHero()
    for index = 1, #self.result.items do
        local single = self.result.items[index]
        local itemId = single.itemId
        local itemCfg = ConfigRefer.Item:Find(itemId)
        if itemCfg:FunctionClass() == FunctionClass.AddHero then
            return true
        end
    end
    return false
end

function HeroCardModule:HasPet()
    for index = 1, #self.result.items do
        local single = self.result.items[index]
        local itemId = single.itemId
        local itemCfg = ConfigRefer.Item:Find(itemId)
        if itemCfg:FunctionClass() == FunctionClass.AddPet then
            return true
        end
    end
    return false
end

function HeroCardModule:GetTopQuality()
    local quality = 1
    if self.result then
        for index = 1, #self.result.items do
            local single = self.result.items[index]
            local itemId = single.itemId
            local itemCfg = ConfigRefer.Item:Find(itemId)
            if itemCfg:FunctionClass() == FunctionClass.AddHero then
                local heroId = tonumber(itemCfg:UseParam(1))
                local heroDb = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
                local heroCfg = heroDb.configCell
                local heroQuality = heroCfg:Quality() + 1
                if heroQuality > quality then
                    quality = heroQuality
                end
            elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
                local petId = tonumber(itemCfg:UseParam(1))
                local petCfg = ConfigRefer.Pet:Find(petId)
                local petQuality = petCfg:Quality()
                if petQuality > quality then
                    quality = petQuality
                end
            end
        end
    end
    return quality
end

function HeroCardModule:ShowResult()
    self.companionItems = {}
    self.showResultList = {}
    if self.isTen then
        for index = 1, #self.result.items do
            local single = self.result.items[index]
            if index <= 10 then
                local itemId = single.itemId
                local itemCfg = ConfigRefer.Item:Find(itemId)
                if itemCfg:FunctionClass() == FunctionClass.AddHero then
                    local heroId = tonumber(itemCfg:UseParam(1))
                    local heroDb = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
                    local heroCfg = heroDb.configCell
                    if single.new or heroCfg:Quality() >= HeroQuality.Purple then
                        self.showResultList[#self.showResultList + 1] = {isNew = single.new, heroId = heroId, transItemId = single.transItemId, transItemCount = single.transItemCount, closeCallback = Delegate.GetOrCreate(self, self.PopupResultList)}
                    end
                elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
                    local petId = tonumber(itemCfg:UseParam(1))
                    local petCfg = ConfigRefer.Pet:Find(petId)
                    local petQuality = petCfg:Quality()
                    if single.new or petQuality >= 3 then
                        self.showResultList[#self.showResultList + 1] = {petCompId = single.CompId, closeCallback = Delegate.GetOrCreate(self, self.PopupResultList)}
                    end
                end
            else
                self.companionItems[#self.companionItems + 1] = {id = single.itemId, count = 1}
            end
        end
        self:PopupResultList()
    else
        for index = 1, #self.result.items do
            local single = self.result.items[index]
            local itemId = single.itemId
            local itemCfg = ConfigRefer.Item:Find(itemId)
            if itemCfg:FunctionClass() == FunctionClass.AddHero then
                local heroId = tonumber(itemCfg:UseParam(1))
                self.curHeroPopRuntimeId = g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator,
                {selectType = self.result.tid,
                heroId = heroId,
                transItemId = single.transItemId,
                transItemCount = single.transItemCount,
                closeCallback = Delegate.GetOrCreate(self, self.OnResultClose),
                dontCloseUI3DView = true}, Delegate.GetOrCreate(self, self.CloseSkipCg))
            elseif itemCfg:FunctionClass() == FunctionClass.AddPet then
                g_Game.UIManager:Open(UIMediatorNames.SEPetSettlementMediator, {petCompId = single.CompId, closeCallback = Delegate.GetOrCreate(self, self.OnResultClose)}, Delegate.GetOrCreate(self, self.CloseSkipCg))
            else
                self.companionItems[#self.companionItems + 1] = {id = single.itemId, count = 1}
                self:OnResultClose()
                g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
                self:CloseSkipCg()
            end
        end
    end
end

function HeroCardModule:OnResultClose(closeCallback)
    if self.companionItems and #self.companionItems > 0 then
        g_Game.UIManager:Open(UIMediatorNames.HeroCardShowTenMediator, {selectType = self.result.tid,
        result = self.result.items,
        closeCallback = closeCallback,
        isSingle = true})
    elseif closeCallback ~= nil then
        closeCallback()
    else
        g_Game.UIManager:Open(UIMediatorNames.HeroCardShowTenMediator, {selectType = self.result.tid, result = self.result.items, isSingle = true})
        g_Game.EventManager:TriggerEvent(EventConst.HERO_CARD_SHOW_UI, true)
        g_Game.UIManager:CloseUI3DView(self.curHeroPopRuntimeId)
    end
end

function HeroCardModule:PopupResultList()
    TimerUtility.DelayExecuteInFrame(function()
        if self.showResultList and next(self.showResultList) then
            local param = self.showResultList[1]
            param.dontCloseUI3DView = true
            table.remove(self.showResultList, 1)
            if param.heroId then
                self.curHeroPopRuntimeId = g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, param, Delegate.GetOrCreate(self, self.CloseSkipCg))
            elseif param.petCompId then
                g_Game.UIManager:Open(UIMediatorNames.SEPetSettlementMediator, param, Delegate.GetOrCreate(self, self.CloseSkipCg))
            end
        else
            local callBack = function()
                g_Game.SoundManager:Play("sfx_lottery_open_get_continuous")
                g_Game.UIManager:Open(UIMediatorNames.HeroCardShowTenMediator, {selectType = self.result.tid, result = self.result.items})
                g_Game.UIManager:CloseUI3DView(self.curHeroPopRuntimeId)
            end
            self:OnResultClose(callBack)
            self:CloseSkipCg()
        end
    end, 1, true)
end

return HeroCardModule
