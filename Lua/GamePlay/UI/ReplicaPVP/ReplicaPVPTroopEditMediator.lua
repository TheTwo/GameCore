local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local NumberFormatter = require("NumberFormatter")
local KingdomMapUtils = require("KingdomMapUtils")
local UITroopHeroSelectComponnet = require("UITroopHeroSelectComponnet")
local UI3DViewConst = require("UI3DViewConst")
local UI3DTroopModelViewHelper = require('UI3DTroopModelViewHelper')
local UITroopHelper = require("UITroopHelper")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local UIHelper = require('UIHelper')
local rapidjson = require("rapidjson")

local OneKeyArrangeReplicaPvpPresetParameter = require("OneKeyArrangeReplicaPvpPresetParameter")

---@class ReplicaPVPTroopEditMediatorParameter
---@field isAtk boolean
---@field targetBasicInfo wds.ReplicaPvpPlayerBasicInfo

---@class ReplicaPVPTroopEditMediator:BaseUIMediator
---@field new fun():ReplicaPVPTroopEditMediator
---@field super BaseUIMediator
local ReplicaPVPTroopEditMediator = class('ReplicaPVPTroopEditMediator', BaseUIMediator)

local CellTransDuration = 0.2

---@param param ReplicaPVPTroopEditMediatorParameter
function ReplicaPVPTroopEditMediator:OnCreate(param)
    ---@type CommonBackButtonComponent
	self.backButton = self:LuaObject("child_common_btn_back")

    self.goAttacker = self:GameObject('p_group_left')
    self.goVS = self:GameObject('p_icon_vs')
    self.goDefender = self:GameObject('p_group_right')

    self.txtPowerMine = self:Text('p_text_power_attacker')
    self.txtPowerOpponent = self:Text('p_text_power_defender')
    ---@type PlayerInfoComponent
    self.playerHeadMine = self:LuaObject('p_head_attacker')
    ---@type PlayerInfoComponent
    self.playerHeadOpponent = self:LuaObject('p_head_defender')

    ---@type UITroopRelationInfoComponent
    self.relationInfoA = self:LuaObject('p_buff_left')
    ---@type UITroopRelationInfoComponent
    self.relationInfoB = self:LuaObject('p_buff_right')

    ---@type UITroopHeroCardGroup
    self.uiTroopHeroCardGroupA = self:LuaObject('p_troop_group_a')
    ---@type UITroopHeroCardGroup
    self.uiTroopHeroCardGroupB = self:LuaObject('p_troop_group_b')

    ---@type UITroopHeroSelectComponnet
	self.heroSelectionPanel = self:LuaObject('child_hero_list')

    self.btnRelation = self:Button('p_btn_relation', Delegate.GetOrCreate(self, self.OnBtnRelationClick))

    ModuleRefer.ReplicaPVPModule:EditPvpTroopStart(param.isAtk)

    self.dragCell = self:LuaObject("p_item_hero")
	self.transUpZone = self:RectTransform("p_img_light")
	self.transUpZone:SetVisible(false)
	self.upZoneCanvasGroup = self.transUpZone.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
	self.upZoneAnim = self:AnimTrigger("p_img_light")

    self.btnDefenceWord = self:Button('p_btn_defence_word', Delegate.GetOrCreate(self, self.OnDefenceWordClick))
    self.textDefenceWord = self:Text("p_text_defence", "se_pvp_fightmessage_name")

    self.goDefenceWordA = self:GameObject('p_popup_a')
    self.textWordA = self:Text('p_text_content_a')

    self.goDefenceWordB = self:GameObject('p_popup_b')
    self.textWordB = self:Text('p_text_content_b')
end

---@param param ReplicaPVPTroopEditMediatorParameter
function ReplicaPVPTroopEditMediator:OnOpened(param)
    self.isAtk = param.isAtk
    self.basicInfo = param.targetBasicInfo

    ---@type CommonBackButtonData
    local backButtonData = {}
    backButtonData.onClose = Delegate.GetOrCreate(self, self.OnBackButtonClick)
    self.backButton:FeedData(backButtonData)

    self.btnDefenceWord.gameObject:SetActive(not self.isAtk)

    ---@type UI3DViewerParam
	local ui3dViewerParam = {}
    ui3dViewerParam.type = UI3DViewConst.TroopViewType.DoubleTroop
    ui3dViewerParam.envPath = ConfigRefer.ReplicaPvpConst:TroopBG()
    ui3dViewerParam.preCallback =
	---@param viewer UI3DTroopModelView
	function(viewer)
        if viewer == nil then
            return
        end
        local cam = g_Game.UIManager.ui3DViewManager:UICam3D()
		if cam then
			local heroPosL ,petPosL = viewer:GetHeroAndPetPos_L()
			self.uiTroopHeroCardGroupA:SetupHeroAndPetPos(cam,heroPosL,petPosL)

            local heroPosR,petPosR = viewer:GetHeroAndPetPos_R()
            self.uiTroopHeroCardGroupB:SetupHeroAndPetPos(cam,heroPosR,petPosR)
		end
	end
	ui3dViewerParam.callback = function(viewer)
		self:SetupUI3DView(viewer,self.isDraging and CellTransDuration or 0)
	end
    g_Game.UIManager:SetupUI3DView(self:GetRuntimeId(), UI3DViewConst.ViewType.TroopViewer, ui3dViewerParam)

    -- 固定不变的UI
    self.playerHeadMine:FeedData(ModuleRefer.PlayerModule:GetSelfPortaitInfo())
    self:SetupOpponentUITroopHeroCardGroup()

    if self.isAtk then
        self:SetupOpponentDefenceWord()
    else
        self:SetupMyDefenceWord()
    end

    ModuleRefer.ReplicaPVPModule:EditRebuildSelectedHeroList()
    -- 需要刷新的UI
    self:RefreshMyUITroopHeroCardGroup()
    self:RefreshHeroSelectPanel()

    self.btnRelation.gameObject:SetActive(false)
end

function ReplicaPVPTroopEditMediator:OnClose(param)
    ModuleRefer.ReplicaPVPModule:EditPvpTroopFinish()

    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
end

function ReplicaPVPTroopEditMediator:OnBackButtonClick()
    if (not self.isAtk) and ModuleRefer.ReplicaPVPModule:EditNeedSavePreset() then
        self:ShowSaveConfirm()
    else
        self:BackToPrevious()
    end
end

function ReplicaPVPTroopEditMediator:ShowSaveConfirm()
    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("NewFormation_SaveAlertTitle")
    dialogParam.content = I18N.Get("NewFormation_SaveAlertContent02")
    dialogParam.onConfirm = Delegate.GetOrCreate(self, self.OnBackAndSaveClick)
    dialogParam.onCancel = Delegate.GetOrCreate(self, self.OnBackAndGiveUpClick)
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

---@return boolean
function ReplicaPVPTroopEditMediator:OnBackAndSaveClick()
    ModuleRefer.ReplicaPVPModule:EditSendSaveTroopPreset(function(cmd, isSuccess, rsp)
        if not isSuccess then
            return
        end

        self:BackToPrevious()
    end)
    return true
end

---@return boolean
function ReplicaPVPTroopEditMediator:OnBackAndGiveUpClick()
    self:BackToPrevious()
    return true
end

function ReplicaPVPTroopEditMediator:OnShow(param)
    g_Game.ServiceManager:AddResponseCallback(OneKeyArrangeReplicaPvpPresetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnQuickSelectCallback))
    g_Game.ServiceManager:AddResponseCallback(require("ReplicaPvpSetDefendAnnounceParameter").GetMsgId(), Delegate.GetOrCreate(self, self.OnSetDefenceWordCallback))

    -- 需要刷新的UI
    self:RefreshMyUITroopHeroCardGroup()
    self:RefreshHeroSelectPanel()
end

function ReplicaPVPTroopEditMediator:OnHide(param)
    g_Game.ServiceManager:RemoveResponseCallback(OneKeyArrangeReplicaPvpPresetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnQuickSelectCallback))
    g_Game.ServiceManager:RemoveResponseCallback(require("ReplicaPvpSetDefendAnnounceParameter").GetMsgId(), Delegate.GetOrCreate(self, self.OnSetDefenceWordCallback))
end

---@param viewer UI3DTroopModelView
function ReplicaPVPTroopEditMediator:SetupUI3DView(viewer,animDuration)
	---@type UI3DTroopModelView
	self.ui3dView = viewer
	self.ui3dView:OnStartLoadUnit()

    -- 自己的，会刷新
    self:RefreshSelf3DModels()

    -- 对手的，不会刷新
    self:SetupOpponent3DModels()
end

function ReplicaPVPTroopEditMediator:SetupMyDefenceWord()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local word = player.PlayerWrapper3.PlayerReplicaPvp.DefendAnnounce
    if not word or word == '' then
        self.goDefenceWordA:SetVisible(false)
        return
    end
    self.goDefenceWordA:SetVisible(true)
    self.textWordA.text = word
end

function ReplicaPVPTroopEditMediator:SetupOpponentDefenceWord()
    local word = self.basicInfo.DefendAnnounce
    if not word or word == '' then
        self.goDefenceWordB:SetVisible(false)
        return
    end
    self.goDefenceWordB:SetVisible(true)
    self.textWordB.text = word
end

function ReplicaPVPTroopEditMediator:RefreshHeroSelectPanel()
    ---@type UITroopHeroSelectComponnetParam
	local heroSelectParam = {}
	heroSelectParam.simpleMode = true
	heroSelectParam.onHeroSelected = Delegate.GetOrCreate(self, self.OnHeroSelectCallback)
    heroSelectParam.onHeroDragBegin = Delegate.GetOrCreate(self, self.OnHeroCellDragBegin)
	heroSelectParam.onHeroDragEnd = Delegate.GetOrCreate(self, self.OnHeroCellDragEnd)
	heroSelectParam.onHeroDrag = Delegate.GetOrCreate(self, self.OnHeroCellDrag)
	heroSelectParam.selectedHeroIds = ModuleRefer.ReplicaPVPModule:EditGetSelectHeroList()
	self.heroSelectionPanel:FeedData(heroSelectParam)
	self:RefreshHeroSelectPanelButtons()
end

function ReplicaPVPTroopEditMediator:RefreshHeroSelectPanelButtons()
    local btnParam = {}
    btnParam.btnParam_go = {
		buttonText = I18N.Get('formation_quickformation'),
		onClick = Delegate.GetOrCreate(self, self.OnQuickSelectClick),
		buttonEnabled = true
	}

    if self.isAtk then
        btnParam.btnParam_attack = {
            buttonText = I18N.Get('npc_monster_l_6_but'),
            onClick = Delegate.GetOrCreate(self, self.OnAttackClick),
            buttonEnabled = ModuleRefer.ReplicaPVPModule:EditGetSelectedHeroCount() > 0
        }
    else
        btnParam.btnParam_save = {
            buttonText = I18N.Get('NewFormation_FormationSave'),
            onClick = Delegate.GetOrCreate(self, self.OnSaveClick),
            buttonEnabled = ModuleRefer.ReplicaPVPModule:EditNeedSavePreset()
        }
    end
    self.heroSelectionPanel:RefreshButtonState(btnParam)
end

function ReplicaPVPTroopEditMediator:RefreshMyUITroopHeroCardGroup()
    local power = UITroopHelper.CalcTroopPower(ModuleRefer.ReplicaPVPModule:EditGetSelectHeroList(),nil, true)
    self.txtPowerMine.text = NumberFormatter.Normal(power)
    
    local cardDataList = {}
    for i = 1, 3 do
        local heroCardData = ModuleRefer.ReplicaPVPModule:EditGetMyHeroCardData(i)
        cardDataList[i] = heroCardData
    end

    ---@type UITroopHeroCardGroupData
	local heroCardGroupData = {}
	heroCardGroupData.editable = true
    heroCardGroupData.simpleMode = true
    heroCardGroupData.onHeroCardDataChanged = Delegate.GetOrCreate(self, self.OnHeroCardDataChanged)
    heroCardGroupData.heroCardData = cardDataList
    heroCardGroupData.isPvP = true

    self.uiTroopHeroCardGroupA:FeedData(heroCardGroupData)

    local heroIds = ModuleRefer.ReplicaPVPModule:EditGetSelectHeroList()
    -- g_Logger.Error('hero ids: %s', rapidjson.encode(heroIds))
    -- self.relationInfoA:FeedData(heroIds)
    self.relationInfoA:SetVisible(false)
end

function ReplicaPVPTroopEditMediator:SetupOpponentUITroopHeroCardGroup()
    if self.isAtk then
        self.goVS:SetVisible(true)
        self.goDefender:SetVisible(true)
        self.txtPowerOpponent.text = NumberFormatter.Normal(self.basicInfo.DefPreset.Power)
        self.playerHeadOpponent:FeedData(self.basicInfo.Portrait)
        self:SetupOpponentHeroCards(self.basicInfo.DefPreset.HeroInfos)

        self.relationInfoB:SetVisible(false)
    else
        -- 对方的防守阵容（无）
        self.goVS:SetVisible(false)
        self.goDefender:SetVisible(false)
        self.relationInfoB:SetVisible(false)
        self:SetupOpponentHeroCards(nil)
    end
end

---@param heroGrouthInfos wds.HeroGrowthInfo[] | RepeatedField
function ReplicaPVPTroopEditMediator:SetupOpponentHeroCards(heroGrouthInfos)
    local cardDataList = {}
    heroGrouthInfos = heroGrouthInfos or {}
    for i = 1, 3 do
        local heroCardData = self:GetOpponentCardData(heroGrouthInfos[i])
        cardDataList[i] = heroCardData
    end

    ---@type UITroopHeroCardGroupData
	local heroCardGroupData = {}
	heroCardGroupData.editable = false
    heroCardGroupData.simpleMode = true
    heroCardGroupData.heroCardData = cardDataList

    self.uiTroopHeroCardGroupB:FeedData(heroCardGroupData)
end

---@param heroGrowthInfo wds.HeroGrowthInfo
function ReplicaPVPTroopEditMediator:GetOpponentCardData(heroGrowthInfo)
    if heroGrowthInfo == nil then
        return nil
    end

    ---@type UITroopHeroCardData
    local data = {}
    -- 英雄信息
    data.heroCfgId = heroGrowthInfo.CfgId
    data.heroLevel = heroGrowthInfo.Level
    data.heroStrengthenLevel = heroGrowthInfo.StrengthenLevel

    -- 宠物信息
    local petData = heroGrowthInfo.Pet
    if petData then
        data.petSkillLevels = ModuleRefer.PetModule:GetSkillLevelQualityList(petData.CfgId, petData.ClientSkillLevel, petData.ClientLearnableSkillLevel)
        data.petCfgId = petData.CfgId
        data.petLevel = petData.Level
        data.petRankLevel = petData.RankLevel
        data.petUnlockNum = petData.TemplateIds and petData.TemplateIds:Count() or 0
    end

    return data
end

---刷新己方的3D模型
function ReplicaPVPTroopEditMediator:RefreshSelf3DModels(animDuration,playVfx)
    if self.ui3dView == nil then
        return
    end

	local viewData = ModuleRefer.ReplicaPVPModule:EditGetMyTroopViewData()
	-- self.ui3dView:SetupHeros_L(viewData)
	-- self.ui3dView:SetupPets_L(viewData)
    playVfx = playVfx or false
    self.ui3dView:PlayChangePosSequence(viewData,2,animDuration,playVfx,nil)
end

---刷新对手的3D模型
function ReplicaPVPTroopEditMediator:SetupOpponent3DModels()
    if self.ui3dView == nil then
        return 
    end

    local heroInfos = nil
    if self.isAtk then
        heroInfos = self.basicInfo.DefPreset.HeroInfos
    end

    local viewData = self:GetOpponentTroopViewData(heroInfos)
	self.ui3dView:SetupHeros_R(viewData)
	self.ui3dView:SetupPets_R(viewData)
    self.ui3dView:SetVisible_R(self.isAtk)
end

---取对手的阵容的3D模型数据
---@param heroInfos wds.HeroGrowthInfo[] | RepeatedField
---@return ModelViewData
function ReplicaPVPTroopEditMediator:GetOpponentTroopViewData(heroInfos)
    if heroInfos == nil then
        return nil
    end

    local heroCfgIds = {}
    local petCfgIds = {}
    local count = heroInfos:Count()
    for i = 1, count do
        local heroInfo = heroInfos[i]
        if heroInfo then
            heroCfgIds[i] = heroInfo.CfgId
            if heroInfo.Pet then
                petCfgIds[i] = heroInfo.Pet.CfgId
            else
                petCfgIds[i] = 0
            end
        end
    end

    return UI3DTroopModelViewHelper.CreateTroopViewData(heroCfgIds, petCfgIds)
end

--- 英雄选择单元格点击
---@param heroConfigId number
---@param selectionType number @UITroopHeroSelectComponnet.SelectionType
function ReplicaPVPTroopEditMediator:OnHeroSelectCallback(heroConfigId, selectionType)
    local opSuccess = false
    if selectionType == UITroopHeroSelectComponnet.SelectionType.Selected then
        -- 之前是选中状态，现在取消选中
        opSuccess = ModuleRefer.ReplicaPVPModule:EditHeroDelete(heroConfigId)
        if opSuccess then
            self.heroSelectionPanel:UpdateHeroSelectionState(heroConfigId, UITroopHeroSelectComponnet.SelectionType.Normal)
            self:RefreshHeroSelectPanelButtons()
        end
    elseif selectionType == UITroopHeroSelectComponnet.SelectionType.Normal then
        -- 之前是未选中状态，现在选中
        opSuccess = ModuleRefer.ReplicaPVPModule:EditHeroAdd(heroConfigId)
        if opSuccess then
            self.heroSelectionPanel:UpdateHeroSelectionState(heroConfigId, UITroopHeroSelectComponnet.SelectionType.Selected)
            self:RefreshHeroSelectPanelButtons()
        end
    end

    if opSuccess then
        self:RefreshMyUITroopHeroCardGroup()
        self:RefreshSelf3DModels( self.isDraging and CellTransDuration or 0,true)
        return true
    end
    return false
end

---@param list UITroopHeroCardData[]
---@param changed UITroopHeroCard
function ReplicaPVPTroopEditMediator:OnHeroCardDataChanged(list, changed)
    local opSuccess = ModuleRefer.ReplicaPVPModule:EditUpdateSelectedHeroList(list)

    if opSuccess then
        self:RefreshHeroSelectPanel()
        self:RefreshMyUITroopHeroCardGroup()
        self:RefreshSelf3DModels()
    end
end

function ReplicaPVPTroopEditMediator:OnAttackClick()
    ModuleRefer.ReplicaPVPModule:EditSendSaveTroopPreset(function(cmd, isSuccess, rsp)
        if not isSuccess then
            return 
        end
    
        self:DoAttack()
    end)
end

function ReplicaPVPTroopEditMediator:DoAttack()
    g_Game.UIManager:CloseAll()

    -- -- 大世界
    -- if (KingdomMapUtils.IsMapState()) then
    --     g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", SEHudTroopMediatorDefine.FromType.World, true)
    -- -- 内城
    -- else
    --     g_Game.StateMachine:WriteBlackboard("SE_FROM_TYPE", SEHudTroopMediatorDefine.FromType.City, true)
    -- end
    -- g_Game.StateMachine:WriteBlackboard("SE_USE_DEFAULT_POS", true, true)
    g_Game.StateMachine:WriteBlackboard("SE_PVP_ATTACKER_ID", ModuleRefer.PlayerModule:GetPlayerId(), true)
    g_Game.StateMachine:WriteBlackboard("SE_PVP_DEFENDER_ID", self.basicInfo.PlayerId, true)
    ModuleRefer.EnterSceneModule:EnterSePVP(ModuleRefer.ReplicaPVPModule:GetMapInstanceId(), nil, self.basicInfo.PlayerId)
end

function ReplicaPVPTroopEditMediator:OnQuickSelectClick()
    local req = OneKeyArrangeReplicaPvpPresetParameter.new()
    req.args.IsAtk = self.isAtk
    req:Send()
end

---@param isSuccess boolean
---@param reply wrpc.OneKeyArrangeReplicaPvpPresetReply
---@param req AbstractRpc
function ReplicaPVPTroopEditMediator:OnQuickSelectCallback(isSuccess, reply, req)
    if not isSuccess then return end

    ModuleRefer.ReplicaPVPModule:EditRebuildSelectedHeroList()

    self:RefreshHeroSelectPanel()
    self:RefreshMyUITroopHeroCardGroup()
    self:RefreshSelf3DModels(0,true)
end

function ReplicaPVPTroopEditMediator:OnSaveClick()
    ModuleRefer.ReplicaPVPModule:EditSendSaveTroopPreset(function(cmd, isSuccess, rsp)
        if not isSuccess then
            return 
        end

        self:RefreshHeroSelectPanel()
        self:RefreshMyUITroopHeroCardGroup()
        self:RefreshSelf3DModels()
    end)
end

function ReplicaPVPTroopEditMediator:OnBtnRelationClick()
	g_Game.UIManager:Open(UIMediatorNames.UITroopRelationTipsMediator, {
        heroIds = ModuleRefer.ReplicaPVPModule:EditGetSelectHeroList(),
        associateData = ModuleRefer.TroopModule:GetRelationConfigData(),
    })
end

function ReplicaPVPTroopEditMediator:OnDefenceWordClick()
    ---@type UIPlayerChangeNameMediatorParameter
    local data ={}
    data.changeName = false
    data.pvpDefenceWord = true
    g_Game.UIManager:Open(UIMediatorNames.UIPlayerChangeNameMediator, data)
end

function ReplicaPVPTroopEditMediator:OnSetDefenceWordCallback(isSuccess, reply, req)
    if not isSuccess then return end
    self:SetupMyDefenceWord()
end


---------------------------------------------
---Draging logic

---@param cellData UITroopHeroSelectionCellData
function ReplicaPVPTroopEditMediator:OnHeroCellDragBegin(go,pointData,cellData)
	if self.isDraging then
		return
	end
	self.isDraging = true
	self.dragCell:SetVisible(true)
	self.dragCell:FeedData(cellData)
	self.transUpZone:SetVisible(true)
	self.upZoneCanvasGroup.alpha = 0	
	self.upZoneRect = self.transUpZone:GetScreenRect(g_Game.UIManager:GetUICamera())
end
---@param cellData UITroopHeroSelectionCellData
function ReplicaPVPTroopEditMediator:OnHeroCellDrag(go,pointData,cellData)
	if not self.isDraging then
		return
	end
	local uiPos = UIHelper.ScreenPos2UIPos(pointData.position)	
	self.dragCell.CSComponent.transform.localPosition = uiPos	
	if self.upZoneRect:Contains(CS.UnityEngine.Vector2(pointData.position.x, CS.UnityEngine.Screen.height  - pointData.position.y)) then
		if not self.zoneShowing then
			self.zoneShowing = true
			self.upZoneAnim:PlayAll(FpAnimTriggerEvent.Custom1)
		end
	else
		if self.zoneShowing then
			self.zoneShowing = false
			self.upZoneAnim:PlayAll(FpAnimTriggerEvent.Custom2)		
		end
	end
end
---@param cellData UITroopHeroSelectionCellData
function ReplicaPVPTroopEditMediator:OnHeroCellDragEnd(go,pointData,cellData)
	if not self.isDraging then
		return
	end
	self.transUpZone:SetVisible(false)
	local setSucceed = false
	if self.upZoneRect:Contains(CS.UnityEngine.Vector2(pointData.position.x, CS.UnityEngine.Screen.height - pointData.position.y)) then
		setSucceed = self:OnHeroSelectCallback(cellData.heroId,UITroopHeroSelectComponnet.SelectionType.Normal)
	end
	self.isDraging = false
	if setSucceed then				
        local card = nil
        for __, heroCard in pairs(self.uiTroopHeroCardGroupA.heroCards) do
            if heroCard._data and heroCard._data.heroCfgId == cellData.heroId then
                card = heroCard
                break;
            end
        end
        
        if card and card.CSComponent then
            local cardTrans = card.CSComponent.transform
            self.dragCell.CSComponent.transform:DOKill()
            self.dragCell.CSComponent.transform:DOMove(cardTrans.position,CellTransDuration*2):OnComplete(function()
                self.dragCell:SetVisible(false)
            end)
        else
            self.dragCell:SetVisible(false)
        end
		
	else
		self.dragCell:SetVisible(false)
	end
end

return ReplicaPVPTroopEditMediator