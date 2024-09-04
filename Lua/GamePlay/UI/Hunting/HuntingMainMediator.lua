local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local EventConst = require("EventConst")
local I18N = require("I18N")
local Utils = require("Utils")
local HuntingSectionType = require("HuntingSectionType")
local UIMediatorNames = require("UIMediatorNames")
local DailyRewardHuntingParameter = require("DailyRewardHuntingParameter")
local SEUnitCategory = require("SEUnitCategory")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local SlgBattlePowerHelper = require("SlgBattlePowerHelper")
local UIHelper = require("UIHelper")
local TimerUtility = require("TimerUtility")
local NotificationType = require("NotificationType")
local SeJumpScene = require("SeJumpScene")
local GotoUtils = require("GotoUtils")
---@class HuntingMainMediator:BaseUIMediator
---@field super BaseUIMediator
local HuntingMainMediator = class('HuntingMainMediator', BaseUIMediator)

---@class HuntingMainMediatorUpdateUIParameter
---@field updateMask number
---@field sectionInfo HuntingSectionInfo

local TABLE_REWARD_CELL_TYPE = {
    MONSTER_INFO = 0,
    LINE = 1
}

---@class HuntingMainMediatorUpdateUIMask
local UPDATE_MASK = {
    MONSTER_LIST = 1,
    RIGHT_GROUP = 2,
    ALL = 0xFF
}

local GROUP_RIGHT_STATUS = {
    NOT_AVAILABLE = 0,
    AVAILABLE = 1,
    FINISHED = 2
}

local POWER_COLOR_STR = {
    '#6D9D3A',
    '#B8120E',
    '#CA9850'
}

function HuntingMainMediator:ctor()
    HuntingMainMediator.super.ctor(self)
    ---@type {scenePath:string, nextCall:number, preWarmCollection:string}
    self._tickKeepPreloadInfo = nil
end

function HuntingMainMediator:OnCreate()
    self.tableMonster = self:TableViewPro('p_table_monster')

    self.textTitle = self:Text('p_text_title', 'setower_systemname_endlesschallenge')
    self.textSubTitle = self:Text('p_text_title_level', 'searchentity_tips_selectlv')

    --- group right
    self.statusGroupRight = self:StatusRecordParent('p_group_right')
    self.imgMonsterLeft = self:Image('p_img_monster_l')
    self.imgVxMonster = self:Image('vx_img_monster_l_1')
    self.imgVxMonster2 = self:Image('vx_img_monster_l_2')
    self.goDefeatTag = self:GameObject('p_defeat')
    self.textDefeat = self:Text('p_text_defeat', 'setower_tips_completed')

    self.goGoto = self:GameObject('btn_goto')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnGotoBtnClicked))
    self.textGoto = self:Text('p_text_goto', 'Radar_btn_goto')
    self.textGotoHint = self:Text('p_text_hint', 'setower_tips_presection')

    self.goBattle = self:GameObject('btn_battle')
    self.btnBattle = self:Button('p_btn_battle', Delegate.GetOrCreate(self, self.OnBattleBtnClicked))
    self.textBattle = self:Text('p_text_battle', 'Radar_btn_goto')
    self.vxTriggerBattle = self:AnimTrigger('vx_trigger')

    self.imgIconStatus = self:Image('p_icon_status')
    self.textPowerText = self:Text('p_text_power')
    self.textPowerValue = self:Text('p_text_power_number')

    self.textReward = self:Text('p_text_reward', 'setower_dayreward_off')
    self.tableReward = self:TableViewPro('p_table_reward')

    self.goBaseNormal = self:GameObject('p_base_monster')
    self.goVxBaseNormal = self:GameObject('vx_base_monster_1')
    self.goBaseBoss = self:GameObject('p_base_boss')
    self.goVxBaseBoss = self:GameObject('vx_base_boss_1')

    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    --- end of group right

    self.btnStar = self:Button('p_btn_star', Delegate.GetOrCreate(self, self.OnBtnStarClicked))
    self.textStar = self:Text('p_text_star')

    self.btnShop = self:Button('p_btn_return_chapter', Delegate.GetOrCreate(self, self.OnBtnShopClicked))
    self.textShop = self:Text('p_txt_return_chapter', 'setower_systemname_shop')

    self.btnGiftCanClaim = self:Button('p_btn_close_gift', Delegate.GetOrCreate(self, self.OnBtnGiftClicked))
    self.textGift = self:Text('p_text_gift', 'setower_dayreward_on')

    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnClickBtnClose))
    self.goGiftClaimed = self:GameObject('p_btn_open')
    self.btnGiftClaimed = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnBtnGiftClicked))
    self.textGiftClaimed = self:Text('p_text_claimed', 'bundle_daily_freegift_claimed')

    self.notifyNodeStar = self:LuaObject('child_reddot_default_star')
    self.notifyNodeDaily = self:LuaObject('child_reddot_default_daily')

    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function HuntingMainMediator:OnOpened()
    g_Game.EventManager:AddListener(EventConst.HUNTING_MONSTER_CELL_SELECT, Delegate.GetOrCreate(self, self.OnMonsterCellSelected))
    g_Game.EventManager:AddListener(EventConst.HUNTING_GOTO_CURRENT_LEVEL, Delegate.GetOrCreate(self, self.GotoCurLvel))
    self.btnDetail.gameObject:SetActive(false)
    self:UpdateUI({updateMask = UPDATE_MASK.MONSTER_LIST})
    self:SelectTabBySectionId(self:GetNextSecIdSafe())
    local info = ModuleRefer.HuntingModule:GetSectionInfo(self:GetNextSecIdSafe())
    self._tickKeepPreloadInfo = nil
    if info and not info.isFinished then
        local scenePath = ModuleRefer.EnterSceneModule.DoGetScenePathByTid(info.mapInstanceId)
        self._tickKeepPreloadInfo = {}
        self._tickKeepPreloadInfo.nextCall = 0
        self._tickKeepPreloadInfo.scenePath = scenePath
        self._tickKeepPreloadInfo.preWarmCollection = "Common_SECharacter"--ModuleRefer.EnterSceneModule.DoGetShaderWarmupByTid(info.mapInstanceId)
    end

    local logicNotifyNodeStar = ModuleRefer.NotificationModule:GetDynamicNode('HUNTING_STAR_REWARD', NotificationType.HUNTING_STAR_REWARD)
    ModuleRefer.NotificationModule:AttachToGameObject(logicNotifyNodeStar, self.notifyNodeStar.go, self.notifyNodeStar.redDot)

    local logicNotifyNodeDaily = ModuleRefer.NotificationModule:GetDynamicNode('HUNTING_DAILY_REWARD', NotificationType.HUNTING_DAILY_REWARD)
    ModuleRefer.NotificationModule:AttachToGameObject(logicNotifyNodeDaily, self.notifyNodeDaily.go, self.notifyNodeDaily.redDot)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

function HuntingMainMediator:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.HUNTING_MONSTER_CELL_SELECT, Delegate.GetOrCreate(self, self.OnMonsterCellSelected))
    g_Game.EventManager:RemoveListener(EventConst.HUNTING_GOTO_CURRENT_LEVEL, Delegate.GetOrCreate(self, self.GotoCurLvel))
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.everyThing ~ HUDMediatorPartDefine.bossInfo, true)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateTick))
end

---@param param HuntingMainMediatorUpdateUIParameter
function HuntingMainMediator:UpdateUI(param)
    local paramOrEmpty = param or {}
    local updateMask = paramOrEmpty.updateMask or UPDATE_MASK.ALL
    local sectionInfo = paramOrEmpty.sectionInfo
    self.sectionInfo = sectionInfo
    if updateMask & UPDATE_MASK.MONSTER_LIST ~= 0 then
        self:UpdateMonsterList()
    end
    if updateMask & UPDATE_MASK.RIGHT_GROUP ~= 0 then
        self:UpdateRightGroup(sectionInfo)
    end
end

function HuntingMainMediator:SelectTabBySectionId(sectionId)
    self.sectionInfo = ModuleRefer.HuntingModule:GetSectionInfo(sectionId)
    self.tableMonster:SetDataFocus(self.sectionId2TableIndex[sectionId], 0, CS.TableViewPro.MoveSpeed.Fast)
    self.tableMonster:SetToggleSelectIndex(self.sectionId2TableIndex[sectionId])
end

---@param sectionInfo HuntingSectionInfo
function HuntingMainMediator:UpdateRightGroup(sectionInfo)
    if not self.CSComponent then return end
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    if not sectionInfo then
        self.goGoto:SetActive(false)
        self.goBattle:SetActive(false)
        self.textReward.gameObject:SetActive(false)
        self.tableReward.gameObject:SetActive(false)
        self.btnDetail.gameObject:SetActive(false)
        return
    end
    local monsterPic = sectionInfo.monsterPic or ''
    local sprite = ArtResourceUtils.GetUIItem(monsterPic)
    g_Game.SpriteManager:LoadSprite(sprite, self.imgMonsterLeft)
    g_Game.SpriteManager:LoadSprite(sprite, self.imgVxMonster)
    g_Game.SpriteManager:LoadSprite(sprite, self.imgVxMonster2)
    local status = GROUP_RIGHT_STATUS.NOT_AVAILABLE
    if sectionInfo.isFinished then
        status = GROUP_RIGHT_STATUS.FINISHED
    elseif ModuleRefer.HuntingModule:GetNextSectionId() == sectionInfo.sectionId then
        status = GROUP_RIGHT_STATUS.AVAILABLE
    end
    local sysId = ConfigRefer.HuntingConst:DailyRewardSystemID()
    local isDailyRewardUnlocked = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysId)
    self.textStar.text = ModuleRefer.HuntingModule:GetCurStarNum()
    self.btnGiftCanClaim.gameObject:SetActive(not ModuleRefer.HuntingModule:IsDailyRewardClaimed() and isDailyRewardUnlocked)
    self.goGiftClaimed:SetActive(ModuleRefer.HuntingModule:IsDailyRewardClaimed() and isDailyRewardUnlocked)

    self.statusGroupRight:ApplyStatusRecord(status)

    local curPower = ModuleRefer.SlgInterfaceModule:GetStrongestTroopPower()
    local compareResult = SlgBattlePowerHelper.ComparePower(curPower, sectionInfo.power, sectionInfo.power)
    local statusSprite = SlgBattlePowerHelper.GetPowerCompareIcon(compareResult)
    self.textPowerValue.text = UIHelper.GetColoredText(I18N.GetWithParams('world_tjbl', sectionInfo.power), POWER_COLOR_STR[compareResult])
    g_Game.SpriteManager:LoadSprite(statusSprite, self.imgIconStatus)

    self.tableReward:Clear()
    self.textReward.gameObject:SetActive(#sectionInfo.rewards > 0)
    self.tableReward.gameObject:SetActive(#sectionInfo.rewards > 0)
    local rewardsCopy = {}
    Utils.CopyArray(sectionInfo.rewards, rewardsCopy)
    ---@type ItemIconData, ItemIconData
    table.sort(rewardsCopy, function (a, b)
        return a.configCell:Quality() > b.configCell:Quality()
    end)
    if #sectionInfo.rewards > 0 then
        for _, reward in ipairs(rewardsCopy) do
            self.tableReward:AppendData(reward)
        end
    end

    self.goBaseBoss:SetActive(sectionInfo.monsterType == SEUnitCategory.Boss)
    self.goVxBaseBoss:SetActive(sectionInfo.monsterType == SEUnitCategory.Boss)
    self.goBaseNormal:SetActive(sectionInfo.monsterType ~= SEUnitCategory.Boss)
    self.goVxBaseNormal:SetActive(sectionInfo.monsterType ~= SEUnitCategory.Boss)
end

function HuntingMainMediator:UpdateMonsterList()
    local chapterInfos = ModuleRefer.HuntingModule:GetChapterInfos()
    self.tableMonster:Clear()
    self.sectionId2TableIndex = {}
    local tableIndex = 0
    for _, chapterInfo in pairs(chapterInfos) do
        for _, sectionId in ipairs(chapterInfo.sectionIds) do
            local param = {
                sectionId = sectionId,
                isUnLocked = chapterInfo.isUnlocked
            }
            self.tableMonster:AppendData(param, TABLE_REWARD_CELL_TYPE.MONSTER_INFO)
            self.sectionId2TableIndex[sectionId] = tableIndex
            tableIndex = tableIndex + 1
        end
        self.tableMonster:AppendData({}, TABLE_REWARD_CELL_TYPE.LINE)
        tableIndex = tableIndex + 1
    end
end

function HuntingMainMediator:GotoCurLvel()
    self:SelectTabBySectionId(self:GetNextSecIdSafe())
end

---@param sectionInfo HuntingSectionInfo
function HuntingMainMediator:OnMonsterCellSelected(sectionInfo)
    ---@type HuntingSectionInfo
    self.sectionInfo = sectionInfo
    self:UpdateRightGroup(sectionInfo)
end

function HuntingMainMediator:OnBattleBtnClicked()
    if not self.sectionInfo then
        return
    end
    ---@type HUDSelectTroopListData
    local troopSelectData = {}
    troopSelectData.isSE = true
    troopSelectData.filter = function(troopInfo)
        return troopInfo ~= nil and troopInfo.preset ~= nil and (troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetInHome or troopInfo.preset.Status == wds.TroopPresetStatus.TroopPresetIdle)
    end
    troopSelectData.overrideItemClickGoFunc = function (data)
        local troopId = (data.troopInfo.entityData or {}).ID or data.troopInfo.preset.ID
        ModuleRefer.EnterSceneModule:EnterHuntingScene(self.sectionInfo.mapInstanceId, 0, troopId, self.sectionInfo.sectionId, data.index)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.HUDSelectTroopList)
        self:CloseSelf()
    end
    local HUDTroopUtils = require("HUDTroopUtils")
    local HUDSelectTroopList = require("HUDSelectTroopList")
    local troops = ModuleRefer.SlgInterfaceModule:GetMyTroops(true) or {}
    local matchCount = 0
    ---@type HUDSelectTroopListItemData
    local firstMatch = nil
    for i, troop in pairs(troops) do
        if HUDTroopUtils.DoesPresetHaveAnyHero(troop.preset) then
            if not troopSelectData.filter(troop) then
                goto continue
            end
            if not firstMatch then
                firstMatch = HUDSelectTroopList.MakeHUDSelectTroopListItemData(i, troop, troopSelectData, nil)
            end
            matchCount = matchCount + 1
        end
        ::continue::
    end
    if matchCount == 1 then
        troopSelectData.overrideItemClickGoFunc(firstMatch)
        return
    end
    if matchCount <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("radartask_toast_troop_busy"))
        return
    end
    HUDTroopUtils.StartMarch(troopSelectData)
end

function HuntingMainMediator:OnGotoBtnClicked()
    self:SelectTabBySectionId(self:GetNextSecIdSafe())
end

function HuntingMainMediator:OnBtnStarClicked()
    g_Game.UIManager:Open(UIMediatorNames.HuntingStarRewardMediator)
end

function HuntingMainMediator:OnBtnGiftClicked()
    if ModuleRefer.HuntingModule:IsDailyRewardClaimed() then
        local groupId = ModuleRefer.HuntingModule:GetCurDailyRewardGroupId()
        ModuleRefer.SEClimbTowerModule:ShowRewardTips('bundle_daily_freegift_claimed', groupId, self.btnGiftClaimed.gameObject.transform)
    else
        local msg = DailyRewardHuntingParameter.new()
        msg:SendOnceCallback(self.btnGiftCanClaim.gameObject.transform, nil, nil, function (_, isSuccess, _)
            if isSuccess then
                self.btnGiftCanClaim.gameObject:SetActive(false)
                self.goGiftClaimed:SetActive(true)
            end
        end)
    end
end

function HuntingMainMediator:OnBtnShopClicked()
    local climbTowerShopId = ConfigRefer.ClimbTowerConst.ClimbTowerShopID and ConfigRefer.ClimbTowerConst:ClimbTowerShopID() or 100
	g_Game.UIManager:Open(UIMediatorNames.UIShopMeidator, {tabIndex = climbTowerShopId})
end

function HuntingMainMediator:OnBtnDetailClicked()
    local desc = I18N.Get(self.sectionInfo.monsterDesc)
    local tipParam = {}
    tipParam.clickTransform = self.btnDetail.gameObject.transform
    tipParam.content = desc
    ModuleRefer.ToastModule:ShowTextToast(tipParam)
end

function HuntingMainMediator:OnClickBtnClose()
    self:CloseSelf()
end

function HuntingMainMediator:GetNextSecIdSafe()
    local nextSecId = ModuleRefer.HuntingModule:GetNextSectionId()
    local lastSecId = ModuleRefer.HuntingModule:GetLastSectionId()
    return math.min(nextSecId, lastSecId)
end

function HuntingMainMediator:LateTick(dt)
    if self._tickKeepPreloadInfo and not string.IsNullOrEmpty(self._tickKeepPreloadInfo.scenePath) then
        self._tickKeepPreloadInfo.nextCall = self._tickKeepPreloadInfo.nextCall - dt
        if self._tickKeepPreloadInfo.nextCall <= 0 then
            self._tickKeepPreloadInfo.nextCall = 1
            g_Game.SceneManager:AddToPreLoadScene(self._tickKeepPreloadInfo.scenePath)
        end
        if not string.IsNullOrEmpty(self._tickKeepPreloadInfo.preWarmCollection) then
            CS.DragonReborn.AssetTool.ShaderWarmupUtils.WarmUpShaderVariantsAsync(self._tickKeepPreloadInfo.preWarmCollection, 10)
            self._tickKeepPreloadInfo.preWarmCollection = string.Empty
        end
    end
end

return HuntingMainMediator