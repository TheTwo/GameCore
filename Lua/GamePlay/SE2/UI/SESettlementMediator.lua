local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local SEEnvironment = require("SEEnvironment")
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')

---@class SESettlementMediator : BaseUIMediator
local SESettlementMediator = class("SESettlementMediator", BaseUIMediator)

local winAnimName = 'anim_se_battle_win'
local loseAnimName = 'anim_se_battle_lose'

function SESettlementMediator:ctor()
    self.closeCD = math.floor(ConfigRefer.ConstSe:SEEndCountDown02() or 2)
	self.animCD = math.floor(ConfigRefer.ConstSe:SEEndCountDown01() or 1)
	self._petIconSlider = {}
	self._petIconSliderValue = {}
	self._petData = {}
end

function SESettlementMediator:OnCreate()
    self.animationContent = self:BindComponent('p_content', typeof(CS.UnityEngine.Animation))
    self.goWin = self:GameObject("p_win")
    self.goLose = self:GameObject("p_lose")
	self.loseAnim = self:BindComponent("p_lose", typeof(CS.UnityEngine.Animation))
    self.title = self:Text('p_text_title', "hero_hero")
	self.petText = self:Text("p_text_pet", "pet_title0")
    self.tips = self:Text('p_text_tips')
    self.titleLose = self:Text('p_text_title_lose', 'se_fail')
    self.btnContinue = self:Button('p_btn_continue', Delegate.GetOrCreate(self, self.OnBtnContinueClicked))
    self.txtContinue1 = self:Text('p_text_continue_1', 'task_open_next_click')
    self.txtContinue2 = self:Text("p_text_continue_2")
    self.animationWin = self:BindComponent('p_win', typeof(CS.UnityEngine.Animation))
    self.animationLose = self:BindComponent('p_lose', typeof(CS.UnityEngine.Animation))
	self.baseGroup = self:GameObject("p_group_1")
	self.petGroup = self:GameObject("p_group_2")
	self.extraGroup = self:GameObject("p_group_3")

	self.tableStrengthen = self:TableViewPro("p_table_way")
	self.textStrengthen = self:Text("p_text_strengthen", "explore_des_rpp")

    self.goGroupCollect = self:GameObject('p_group_collect')
    self.btnFinish = self:Button('p_finish', Delegate.GetOrCreate(self, self.OnBtnCollectClicked))
    self.goHeros = {}
    self.compHeros = {}
    self.heroSliderProgressItems = {}
    self.heroTextExps = {}
    self.heroTextExpNums = {}
    self.TextMaxItems = {}
    self.heroGoGroupFulls = {}
    self.heroTextFulls = {}
	self.seNodes = {}
	self.climbTowerSliders = {}

    for i = 1, 3 do
        self.goHeros[i] = self:GameObject('p_hero_' .. i)
        self.compHeros[i] = self:LuaBaseComponent("child_card_hero_" .. i)
		self.seNodes[i] = self:GameObject("p_se_" .. i)
		self.climbTowerSliders[i] = self:Slider("p_progress_climbtower_" .. i)

        self.heroSliderProgressItems[i] = self:Slider('p_progress_' .. i)
        self.heroTextExps[i] = self:Text('p_text_exp_' .. i, I18N.Get("hero_exp"))
        self.heroTextExpNums[i] = self:Text('p_text_exp_num_' .. i)
        self.TextMaxItems[i] = self:Text('p_text_hint_max_' .. i)
        self.heroGoGroupFulls[i] = self:GameObject('p_group_full_' .. i)
        self.heroTextFulls[i] = self:Text('p_text_full_' .. i)
    end

    self.textReward = self:Text('p_text_reward', I18N.Get("se_item_reward"))
    self.tableviewproTableReward = self:TableViewPro('p_table_reward')
    self.btnFinish.gameObject:SetActive(false)
	self.state = 0
	self.noItem = false

	self.textConds = {}
	self.textConds[1] = self:Text("p_text_condition_1")
	self.textConds[2] = self:Text("p_text_condition_2")
	self.textConds[3] = self:Text("p_text_condition_3")

	self.iconCondMarks = {}
	self.iconCondMarks[1] = self:GameObject("p_status_a_1")
	self.iconCondMarks[2] = self:GameObject("p_status_a_2")
	self.iconCondMarks[3] = self:GameObject("p_status_a_3")

	self.iconCondMarkGots = {}
	self.iconCondMarkGots[1] = self:GameObject("p_status_b_1")
	self.iconCondMarkGots[2] = self:GameObject("p_status_b_2")
	self.iconCondMarkGots[3] = self:GameObject("p_status_b_3")

	self.iconCondStars = {}
	self.iconCondStars[1] = self:GameObject("p_status_star_a_1")
	self.iconCondStars[2] = self:GameObject("p_status_star_a_2")
	self.iconCondStars[3] = self:GameObject("p_status_star_a_3")

	self.iconCondStarGots = {}
	self.iconCondStarGots[1] = self:GameObject("p_status_star_b_1")
	self.iconCondStarGots[2] = self:GameObject("p_status_star_b_2")
	self.iconCondStarGots[3] = self:GameObject("p_status_star_b_3")

	self.tablePetReward = self:TableViewPro("p_table_pet")

	self.textLoseTip1 = self:Text("p_text_lose_tip1")
	self.textLoseTip2 = self:Text("p_text_lose_tip2")
end

function SESettlementMediator:OnShow(param)
end

function SESettlementMediator:OnHide(param)
end

function SESettlementMediator:OnOpened(param)
    self.heroModule = ModuleRefer.HeroModule
	---@type wrpc.LevelRewardInfo
    self.levelRewardInfo = param.LevelRewardInfo
    self.isSuc = param.Suc
	self.extraStr = param.extraStr
	self.totalTimeStr = param.totalTimeStr
	self.isClimbTower = param and param.LevelRewardInfo and param.LevelRewardInfo.ClimbTowerRewardInfo and param.LevelRewardInfo.ClimbTowerRewardInfo.SectionCfgId > 0
    self.goWin:SetVisible(self.isSuc)
    self.goLose:SetVisible(not self.isSuc)
    self.heroLastInfos = {}
	self.petLastInfos = {}
	self.animPlayed = false

	self.textConds[1].text = self.extraStr
	if (not self.isClimbTower) then
		self.textConds[2].text = self.totalTimeStr
		self.textConds[3].text = ""
		self.iconCondMarkGots[1]:SetActive(true)
		self.iconCondMarkGots[2]:SetActive(true)
		self.iconCondMarkGots[3]:SetActive(false)
		self.iconCondMarks[1]:SetActive(false)
		self.iconCondMarks[2]:SetActive(false)
		self.iconCondMarks[3]:SetActive(false)
		self.iconCondStars[1]:SetActive(false)
		self.iconCondStars[2]:SetActive(false)
		self.iconCondStars[3]:SetActive(false)
		self.iconCondStarGots[1]:SetActive(false)
		self.iconCondStarGots[2]:SetActive(false)
		self.iconCondStarGots[3]:SetActive(false)
	end

	if (ConfigRefer.ConstSe:SeDefeatTipsTextLength() > 1) then
		self.textLoseTip1.text = I18N.Get(ConfigRefer.ConstSe:SeDefeatTipsText(1))
		self.textLoseTip2.text = I18N.Get(ConfigRefer.ConstSe:SeDefeatTipsText(2))
	end

    if self.isSuc then
		self.animationContent:Play("anim_se_battle_win")
        self.tips.text = I18N.Get('se_success_subtittle')
		-- 英雄信息
        local heroInfos = self.levelRewardInfo.HeroInfos or {}
        for _, singleInfo in ipairs(heroInfos) do
            local temp = {}
            temp.id = singleInfo.CId
            local heroData = self.heroModule:GetHeroByCfgId(singleInfo.CId).dbData
            local lastLv, lastExp, lastExpPercent = self.heroModule:CalcTargetLevel(singleInfo.CId, heroData.Exp - singleInfo.AddExp)
            temp.lv = lastLv
            temp.levelUpperLimit = heroData.LevelUpperLimit
            temp.expPercent, temp.expValue = lastExpPercent, lastExp
            temp.isMax = self.heroModule:IsMaxLevel(temp.id, lastLv)
            temp.isLimitUpgrade = not self.heroModule:CanLevelUpgrade(temp.id, lastLv)
            temp.addExp = singleInfo.AddExp
            self.heroLastInfos[#self.heroLastInfos + 1] = temp
        end

		g_Game.SoundManager:Play('sfx_se_fight_victory_pve')
    else
		-- self.loseAnim:Play("anim_se_battle_lose")
        self.tips.text = I18N.Get('se_fail_subtittle')
		local providers = ModuleRefer.PowerRecommandModule:GetCurRecommandTypes(param.preset)
		self.tableStrengthen:Clear()
		for _, provider in ipairs(providers) do
			self.tableStrengthen:AppendData(provider)
		end
		if (#providers < 3) then
			self.tableStrengthen:AppendData({})
		end

		g_Game.SoundManager:Play('sfx_se_fight_defeat_pve')
    end

    self.txtContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.animCD)))
	self.txtContinue1.gameObject:SetActive(false)
	self.txtContinue2.gameObject:SetActive(false)
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
    self.heroFrameTimers = {}
	self.petFrameTimers = {}
    self.goGroupCollect:SetActive(false)

	local env = require("SEEnvironment").Instance()
	env:StopSETimer()
	env:GetUnitManager():DestroyAllHeroHuds()
end

function SESettlementMediator:OnClose(param)
    for i = 1, 3 do
        if self.heroFrameTimers[i] then
            TimerUtility.StopAndRecycle(self.heroFrameTimers[i])
            self.heroFrameTimers[i] = nil
        end
    end
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function SESettlementMediator:OnSecondTicker(delta)
	if (self.state == 0) then
		self.animCD = self.animCD - 1
		self.txtContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.animCD)))
		if (self.animCD < 0.1) then
			self:EnterNextState()
		end
	else
		self.closeCD = self.closeCD - 1
		self.txtContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.closeCD)))
	
		if self.closeCD < 0.1 then
			self:EnterNextState()
		end
	end
end

function SESettlementMediator:OnBtnContinueClicked(args)
    self:EnterNextState()
end

function SESettlementMediator:EnterNextState()
    self.tips.text = ""
	self.state = self.state + 1
    if self.isSuc and self.levelRewardInfo then
		if (not self.animPlayed) then
			self.animPlayed = true
			self.animationContent:Play("anim_se_battle_result_move")
		end

		if (self.state == 1) then
			g_Game.SoundManager:Play('sfx_se_fight_settlement_pve')

			self.txtContinue1.gameObject:SetActive(false)
			self.txtContinue2.gameObject:SetActive(false)
			self.closeCD = ConfigRefer.ConstSe:SEEndCountDown02() or 2
			self.txtContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.closeCD)))
			self.goGroupCollect:SetActive(true)
			self.animationContent:Play()
			if (#self.petLastInfos == 0) then
				self:EnterNextState()
			else
				self.petGroup:SetActive(true)
			end
			self:ShowDetails()
		elseif (self.state == 2) then
			if (not self.isClimbTower and self.noItem) then
				self:Quit()
			else
				self.closeCD = ConfigRefer.ConstSe:SEEndCountDown() or 12
				self.txtContinue1.gameObject:SetActive(true)
				self.txtContinue2.gameObject:SetActive(true)
					self.txtContinue2.text = I18N.GetWithParams('se_end_countdown', tostring(math.floor(self.closeCD)))
				self.petGroup:SetActive(false)
				self.extraGroup:SetActive(not self.noItem)
			end
		else
			self:Quit()
		end
    else
        self:Quit()
    end
end

function SESettlementMediator:ShowDetails()
	if (not self.isClimbTower) then
		-- 英雄
		local heroInfos = self.levelRewardInfo.HeroInfos or {}
		for i = 1, #self.goHeros do
			self.climbTowerSliders[i].gameObject:SetActive(false)
			local singleInfo = heroInfos[i]
			local hasHero = singleInfo ~= nil
			self.goHeros[i]:SetActive(hasHero)
			if hasHero then
				self:RefreshHero(i)
			end
		end

		-- 宠物
		self.tablePetReward:Clear()
		for i = 1, #self.petLastInfos do
			self.tablePetReward:AppendData(self:GenPetData(i))
		end
		self.tablePetReward:RefreshAllShownItem()
	else
		-- 爬塔
		local info = self.levelRewardInfo.ClimbTowerRewardInfo
		local sectionCfg = ConfigRefer.ClimbTowerSection:Find(info.SectionCfgId)

		for i = 1, 3 do
			self.seNodes[i]:SetActive(false)
			self.climbTowerSliders[i].gameObject:SetActive(false)
			self.iconCondStarGots[i]:SetActive(info.IsGetStar[i])
			self.iconCondStars[i]:SetActive(not info.IsGetStar[i])
			self.iconCondMarkGots[i]:SetActive(false)
			self.iconCondMarks[i]:SetActive(false)
		end

		for i = 2, 3 do
			self.textConds[i].text = I18N.GetWithParams(sectionCfg:StarEvent(i):Des(), sectionCfg:StarEvent(i):DesPrm())
		end

		---@type wrpc.ClimbTowerPresetInfo
		local showPreset
		for i = 1, 3 do
			if (info.Infos[i] and info.Infos[i].IsBattle) then
				showPreset = info.Infos[i]
			end
		end
		if (showPreset) then
			local preset = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.ClimbTower.Presets[showPreset.PresetIndex + 1]
			if (preset) then
				for i = 1, 3 do
					local heroInfo = preset.Heros[i]
					if (heroInfo and heroInfo.Info.ConfigId > 0) then
						self.climbTowerSliders[i].gameObject:SetActive(true)
						self.goHeros[i]:SetActive(true)
						self.compHeros[i]:FeedData({heroData = ModuleRefer.HeroModule:GetHeroByCfgId(heroInfo.Info.ConfigId)})
						self.climbTowerSliders[i].value = heroInfo.Info.CurHpPrecent
					else
						self.goHeros[i]:SetActive(false)
					end
				end
			end
			self.baseGroup:SetActive(true)
		end
	end

	-- 物品
    self.tableviewproTableReward:Clear()
    local items = self.levelRewardInfo.RewardInfos or {}
	self.noItem = next(items) == nil
    self.textReward.gameObject:SetActive(not self.noItem)
	if (not self.noItem) then
		for id, num in pairs(items) do
			local singleItem = {}
			singleItem.configCell = ConfigRefer.Item:Find(id)
			singleItem.count = num
			singleItem.showTips = true
			self.tableviewproTableReward:AppendData(singleItem)
		end
	end
end

---@param self SESettlementMediator
---@param index number
function SESettlementMediator:GenPetData(index)
	local info = self.petLastInfos[index]
	local data = {
		data = {
			id = info.id,
			cfgId = info.petData.ConfigId,
			level = info.petData.Level,
		},
		index = index,
		showExp = true, --info.isMax,
		expText = I18N.Get("EXP"),
	}
	if (info.isMax) then
		data.expFullText = I18N.Get("hero_level_full")
	end
    data.expNumText = "+" .. info.addExp
	self._petData[index] = data
	return self._petData[index]
end

---@param petConfig PetConfigCell
function SESettlementMediator:RefreshPetExpProgress(petConfig, maxLevel, index, level, startExp, deltaExp)
    if self.petFrameTimers[index] then
        TimerUtility.StopAndRecycle(self.petFrameTimers[index])
        self.petFrameTimers[index] = nil
    end
	local data = self._petData[index].data
    data.level = level
    local isLimitUpgrade = level == maxLevel
    if isLimitUpgrade then
        data.showExp = false
		data.expFullText = I18N.Get("hero_level_full")
    end
    local expTempId = petConfig:Exp()
    local expTemp = ConfigRefer.ExpTemplate:Find(expTempId)
    local curLvlUpExp = expTemp:ExpLv(level)
	self._petIconSliderValue[index] = startExp / curLvlUpExp
	if (self._petIconSlider[index]) then
		self._petIconSlider[index].value = self._petIconSliderValue[index]
	end
    local endValue = 1
    local lastExp = deltaExp - (curLvlUpExp - startExp)
    local isLoop = true
    if lastExp < 0 then
        endValue = (startExp + deltaExp) / curLvlUpExp
        isLoop = false
    end
    self.petFrameTimers[index] = TimerUtility.StartFrameTimer(function()
        self:RefreshPetProgressValue(petConfig, maxLevel, index, level, isLoop, endValue, lastExp)
    end, 0, -1)
end

---@param config PetConfigCell
function SESettlementMediator:RefreshPetProgressValue(config, levelUpperLimit, index, level, isLoop, endValue, deltaExp)
	local frameValue = self._petIconSliderValue[index] + 0.04
	if (self._petIconSlider[index]) then
		self._petIconSlider[index].value = frameValue
	end
    if frameValue >= endValue then
        if self.petFrameTimers[index] then
            TimerUtility.StopAndRecycle(self.petFrameTimers[index])
            self.petFrameTimers[index] = nil
        end
        if isLoop then
            self:RefreshPetExpProgress(config, levelUpperLimit, index, level + 1, 0, deltaExp)
        end
    end
end

function SESettlementMediator:RefreshHero(index)
    local lastInfo = self.heroLastInfos[index]
    local curLvl = lastInfo.lv
    local config = ConfigRefer.Heroes:Find(lastInfo.id)
    self.compHeros[index]:FeedData({heroData = self.heroModule:GetHeroByCfgId(lastInfo.id)})
    self.compHeros[index].Lua:RefreshLv(curLvl)
    if lastInfo.isMax or lastInfo.isLimitUpgrade then
        self.heroTextExps[index].gameObject:SetActive(false)
        self.heroSliderProgressItems[index].gameObject:SetActive(false)
        if lastInfo.isMax then
            self.TextMaxItems[index].gameObject:SetActive(false)
            self.heroGoGroupFulls[index]:SetActive(true)
            self.heroTextFulls[index].text = I18N.Get("hero_level_max")
        else
            self.TextMaxItems[index].gameObject:SetActive(true)
            self.heroGoGroupFulls[index]:SetActive(false)
            self.TextMaxItems[index].text = I18N.Get("hero_need_breaklimit")
        end
        return
    end
    self.heroTextExps[index].gameObject:SetActive(true)
    local addExp = lastInfo.addExp
	if (not addExp or addExp <= 0) then
		self.seNodes[index]:SetActive(false)
	else
		self.seNodes[index]:SetActive(true)
	end
    self.heroTextExpNums[index].text = "+" .. addExp
    self:RefreshHeroExpProgress(config, lastInfo.levelUpperLimit, index, curLvl, lastInfo.expValue, addExp)
end

function SESettlementMediator:RefreshHeroExpProgress(config, levelUpperLimit, index, level, startExp, deltaExp)
    if self.heroFrameTimers and self.heroFrameTimers[index] then
        TimerUtility.StopAndRecycle(self.heroFrameTimers[index])
        self.heroFrameTimers[index] = nil
    end
    self.compHeros[index].Lua:RefreshLv(level)
    local attTemId = config:AttrTemplateCfg()
    local attTemp = ConfigRefer.AttrTemplate:Find(attTemId)
    local isMax = attTemp:MaxLv() == level
    local isLimitUpgrade = level == levelUpperLimit
    if isMax or isLimitUpgrade then
        self.heroTextExps[index].gameObject:SetActive(false)
        self.heroSliderProgressItems[index].gameObject:SetActive(false)
        if isMax then
            self.TextMaxItems[index].gameObject:SetActive(false)
            self.heroGoGroupFulls[index]:SetActive(true)
            self.heroTextFulls[index].text = I18N.Get("hero_level_max")
        else
            self.TextMaxItems[index].gameObject:SetActive(true)
            self.heroGoGroupFulls[index]:SetActive(false)
            self.TextMaxItems[index].text = I18N.Get("hero_need_breaklimit")
        end
        return
    end
    local expTempId = config:ExpTemplateCfg()
    local expTemp = ConfigRefer.ExpTemplate:Find(expTempId)
    local curLvlUpExp = expTemp:ExpLv(level)
    self.heroSliderProgressItems[index].value = startExp / curLvlUpExp
    local endValue = 1
    local lastExp = deltaExp - (curLvlUpExp - startExp)
    local isLoop = true
    if lastExp < 0 then
        endValue = (startExp + deltaExp) / curLvlUpExp
        isLoop = false
    end
    self.heroFrameTimers[index] = TimerUtility.StartFrameTimer(function()
        self:RefreshHeroProgressValue(config, levelUpperLimit, index, level, isLoop, endValue, lastExp)
    end, 0, -1)
end

function SESettlementMediator:RefreshHeroProgressValue(config, levelUpperLimit, index, level, isLoop, endValue, deltaExp)
    local frameValue = self.heroSliderProgressItems[index].value + 0.04
    self.heroSliderProgressItems[index].value = frameValue
    if frameValue >= endValue then
        if self.heroFrameTimers and self.heroFrameTimers[index] then
            TimerUtility.StopAndRecycle(self.heroFrameTimers[index])
            self.heroFrameTimers[index] = nil
        end
        if isLoop then
            self:RefreshHeroExpProgress(config, levelUpperLimit, index, level + 1, 0, deltaExp)
        end
    end
end

function SESettlementMediator:Quit()
    self:CloseSelf()
	local env = SEEnvironment.Instance()
	if env then
    	env:RequestLeave(nil, not self.isSuc)
	end
end

function SESettlementMediator:OnGetPetIconSlider(index, slider)
	self._petIconSlider[index] = slider
end

return SESettlementMediator
