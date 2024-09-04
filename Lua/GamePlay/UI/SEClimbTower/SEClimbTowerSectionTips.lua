local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local UIMediatorNames = require("UIMediatorNames")
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local NumberFormatter = require('NumberFormatter')
local DBEntityPath = require('DBEntityPath')

---@class SEClimbTowerSectionTipsData
---@field chapterId number 章节Id
---@field index number 关卡序号（1开始）

---@class SEClimbTowerSectionTips:BaseUIComponent
---@field new fun():SEClimbTowerSectionTips
---@field super BaseUIComponent
local SEClimbTowerSectionTips = class('SEClimbTowerSectionTips', BaseUIComponent)

function SEClimbTowerSectionTips:OnCreate()
    self.btnClose = self:Button('p_btn_base', Delegate.GetOrCreate(self, self.OnCloseClick))
    
    self.txtTitle = self:Text('p_text_title')
    self.txtRewardView = self:Text('p_text_view_rewards', 'setips_title_reward')
    self.btnRewardView = self:Button('p_btn_view', Delegate.GetOrCreate(self, self.OnRewardViewClicked))

    ---@type SEClimbTowerSectionRewardTips
    self.rewardDetailView = self:LuaObject('p_tips_rewards')

    self.txtStarInfo1 = self:Text('p_text_objective_1')
    self.txtStarInfo2 = self:Text('p_text_objective_2')
    self.txtStarInfo3 = self:Text('p_text_objective_3')
    self.txtStarInfos = {}
    table.insert(self.txtStarInfos, self.txtStarInfo1)
    table.insert(self.txtStarInfos, self.txtStarInfo2)
    table.insert(self.txtStarInfos, self.txtStarInfo3)

    self.imgStar1 = self:Image('p_icon_star_01')
    self.imgStar2 = self:Image('p_icon_star_02')
    self.imgStar3 = self:Image('p_icon_star_03')
    self.imgStars = {}
    table.insert(self.imgStars, self.imgStar1)
    table.insert(self.imgStars, self.imgStar2)
    table.insert(self.imgStars, self.imgStar3)

    self.txtMonsterPreview = self:Text('p_text_monster_preview', 'setips_title_monster')
    self.tableMonster = self:TableViewPro('p_table_monster')

    ---@type BistateButton
    self.btnChallenge = self:LuaObject('child_comp_btn_b')
    self.txtChallengeComplete = self:Text('p_text_finish', 'setower_tips_completed')

    self.goStatus = self:GameObject('p_status')
    self.imgPower = self:Image('p_icon_status_1')
    self.txtPower = self:Text('p_text_status')

    self.vxTrigger = self:AnimTrigger('p_group_tip')
end

function SEClimbTowerSectionTips:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.ClimbTower.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopChanged))
end

function SEClimbTowerSectionTips:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.ClimbTower.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopChanged))
end

function SEClimbTowerSectionTips:OnTroopChanged()
    self:UpdateTroopPower()
end

---@param data SEClimbTowerSectionTipsData
function SEClimbTowerSectionTips:OnFeedData(data)
    -- 当有切换的时候
    self:TriggerVfxIfChanged(self.index, data.index)

    self.chapterId = data.chapterId
    self.index = data.index
    ---@type ClimbTowerSectionConfigCell
    self.sectionConfigCell = ModuleRefer.SEClimbTowerModule:GetSectionConfigCell(self.chapterId, self.index)
    self.mapInstanceConfigCell = ConfigRefer.MapInstance:Find(self.sectionConfigCell:MapInstanceId())

    self:UpdateUI()
end

---@param lastIndex number
---@param newIndex number
function SEClimbTowerSectionTips:TriggerVfxIfChanged(lastIndex, newIndex)
    if lastIndex and lastIndex > 0 and lastIndex == newIndex then
        return
    end

    self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
end

function SEClimbTowerSectionTips:UpdateUI()
    -- 场景名
    self.txtTitle.text = I18N.Get(self.mapInstanceConfigCell:Name())

    -- 星级获取条件
    for i = 1, 3 do
        ---@type StarUnlockEvent
        local starEvent = ModuleRefer.SEClimbTowerModule:GetSectionStarEventStruct(self.chapterId, self.index, i)
        self.txtStarInfos[i].text = ModuleRefer.SEClimbTowerModule:GetStartEventDesc(starEvent)

        local isStarAchieved = ModuleRefer.SEClimbTowerModule:IsSectionStarAchieved(self.sectionConfigCell:Id(), i)
        self.imgStars[i]:SetVisible(isStarAchieved)
    end
    

    local isUnlock = ModuleRefer.SEClimbTowerModule:IsSectionUnlock(self.chapterId, self.index)
    ---@type BistateButtonParameter
    local btnData = {}
    btnData.onClick = Delegate.GetOrCreate(self, self.OnChallengeClick)
    btnData.disableClick = Delegate.GetOrCreate(self, self.OnChallengeLockedClick)
    btnData.buttonText = I18N.Get('setower_btn_start')
    self.btnChallenge:FeedData(btnData)
    self.btnChallenge:SetEnabled(isUnlock)

    -- 怪物预览
    self.tableMonster:Clear()
    local seNpcLength = self.mapInstanceConfigCell:SeNpcConfLength()
    for i = 1, seNpcLength do 
        local seNpcConfigId = self.mapInstanceConfigCell:SeNpcConf(i)
        local seNpcConfigCell = ConfigRefer.SeNpc:Find(seNpcConfigId)
        ---@type SEClimbTowerSectionMonsterCellData
        local monsterCellData = {}
        monsterCellData.iconId = seNpcConfigCell:MonsterInfoIcon()
        self.tableMonster:AppendData(monsterCellData)
    end

    -- 战力
    self:UpdateTroopPower()
end

function SEClimbTowerSectionTips:UpdateTroopPower()
    local isSectionComplete = ModuleRefer.SEClimbTowerModule:IsSectionComplete(self.sectionConfigCell:Id())
    self.btnChallenge:SetVisible(not isSectionComplete)
    self.txtChallengeComplete:SetVisible(isSectionComplete)
    self.goStatus:SetVisible(not isSectionComplete)
    local minPower = self.mapInstanceConfigCell:Power()
    local troopPower = ModuleRefer.SEClimbTowerModule:GetTroopPower()
    local noColorTips = I18N.GetWithParams('setips_title_ce', NumberFormatter.Normal(minPower))
    local tipsImage, colorTips = ModuleRefer.SEPreModule:GetPowerTips(troopPower, minPower, noColorTips)
    self.txtPower.text = colorTips
    g_Game.SpriteManager:LoadSprite(tipsImage, self.imgPower)
end

function SEClimbTowerSectionTips:ShowRewardTips()
    self.rewardDetailView:SetVisible(true)

    ---@type SEClimbTowerSectionRewardTipsData
    local data = {}
    data.chapterId = self.chapterId
    data.index = self.index
    self.rewardDetailView:FeedData(data)
end

function SEClimbTowerSectionTips:HideRewardTips()
    self.rewardDetailView:SetVisible(false)
end

function SEClimbTowerSectionTips:OnCloseClick()
    self:SetVisible(false)
end

function SEClimbTowerSectionTips:OnRewardViewClicked()
    self:ShowRewardTips()
end

function SEClimbTowerSectionTips:OnChallengeLockedClick()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('setower_tips_presection'))
end

function SEClimbTowerSectionTips:OnChallengeClick()
	---@type SEClimbTowerTroopMediatorParam
	local param = {
		challengeMode = true,
		sectionId = self.sectionConfigCell:Id(),
	}
    g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerTroopMediator, param)
end

return SEClimbTowerSectionTips
