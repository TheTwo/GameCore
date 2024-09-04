local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local DBEntityType = require('DBEntityType')
local TimeFormatter = require('TimeFormatter')
local ManualResourceConst = require('ManualResourceConst')

---@class GveHudDamageList : BaseUIComponent
---@field btnConfirm BistateButton
local GveHudDamageList = class('GveHudDamageList', BaseUIComponent)

function GveHudDamageList:ctor()
    self.timerDuration = -1
    self.module = ModuleRefer.GveModule
end

function GveHudDamageList:OnCreate()
    self.goGroupTitle = self:GameObject('title')
    -- self:Text('p_text_title','gverating_outputrankTitle')
    self.btnRankingDetail = self:Button('p_btn_ranking_detail', Delegate.GetOrCreate(self, self.OnBtnRankingDetailClicked))
    self.goTankingDetail = self:GameObject('p_btn_ranking_detail')
    self.tableRank = self:TableViewPro('p_table_rank')
    self:Text('p_text_hero_detail', 'gverating_detail')

    self.module = ModuleRefer.GveModule
    self.slgModule = ModuleRefer.SlgModule
    self.playerModule = ModuleRefer.PlayerModule
    self.textNum = self:Text('p_text_num')
    self.luaTypeDropdown = self:LuaObject('child_dropdown_scroll')

    self.goProgressWatch = self:GameObject('p_watch')
    self.transProgressWatch = self:RectTransform('p_watch')
    self.sliderProgressFillF = self:Slider('p_progress_fill_f')
    self.textNum1 = self:Text('p_text_num_1')
    self.btnWatchDetail = self:Button('p_btn_watch_detail', Delegate.GetOrCreate(self, self.OnBtnWatchDetailClicked))
    self.transWatchBuff = self:RectTransform('p_btn_watch_buff')
    self.p_table_rank = self:GameObject('p_table_rank')
    self.p_confirm = self:GameObject('p_confirm')
    self.p_text_status_1 = self:Text('p_text_status_1')
    self.p_text_status = self:Text('p_text_status')
end

function GveHudDamageList:OnShow(param)
    self.CheckBeforeBattle = nil
    self.ShowCountdown = nil
    self.bossId = self.module.curBoss and self.module.curBoss.ID
    self.goGroupTitle:SetVisible(true)
    self.luaTypeDropdown:SetVisible(false)
    -- g_Game.DatabaseManager:AddChanged(DBEntityPath.MapMob.DamageStatistic.TakeDamage.MsgPath,Delegate.GetOrCreate(self,self.OnDamageChanged))
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_CREATED, Delegate.GetOrCreate(self, self.UpdateTroopCount))
    g_Game.EventManager:AddListener(EventConst.GVE_MONSTER_MODIFIED, Delegate.GetOrCreate(self, self.OnMonsterModified))
    -- g_Game.DatabaseManager:AddChanged(DBEntityPath.Scene.Level.SyncData.Global.MsgPath, Delegate.GetOrCreate(self, self.OnMapLevelSyncDataChanged))
    self:UpdateDamageInfo()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.UpdateDamageInfo))
    if g_Game.SceneManager.current:GetName() == 'SlgScene' then
        self.curSceneId = g_Game.SceneManager.current.id
        -- self.obsCfgData = g_Game.SceneManager.current:GetObserverEnhanceData()
    end
    if not self.obsCfgData then
        self.goProgressWatch:SetVisible(false)
    else
        self.goProgressWatch:SetVisible(true)
        ---@type wds.Scene
        local sceneData = g_Game.DatabaseManager:GetEntity(self.curSceneId, DBEntityType.Scene)
        if sceneData then
            self:UpdateObserverInfo(sceneData.Level.SyncData.Global['observer_count'])
        end
    end
end

function GveHudDamageList:OnHide(param)
    -- g_Game.DatabaseManager:RemoveChanged(DBEntityPath.MapMob.DamageStatistic.TakeDamage.MsgPath,Delegate.GetOrCreate(self,self.OnDamageChanged))
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_CREATED, Delegate.GetOrCreate(self, self.UpdateTroopCount))
    g_Game.EventManager:RemoveListener(EventConst.GVE_MONSTER_MODIFIED, Delegate.GetOrCreate(self, self.OnMonsterModified))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Scene.Level.SyncData.Global.MsgPath, Delegate.GetOrCreate(self, self.OnMapLevelSyncDataChanged))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.UpdateDamageInfo))
    if self.prepareAreaVfx and self.prepareAreaVfx.Effect then
        self.prepareAreaVfx:Delete()
        self.prepareAreaVfx = nil
        self.playCountdown = nil
    end
end

function GveHudDamageList:OnOpened(param)
end

function GveHudDamageList:OnClose(param)
end

function GveHudDamageList:OnBtnRankingDetailClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothBattleConfirmAndRankingMediator, {mapMob = self.module.curBoss})
end

---@param index number
---@param damInfo PlayerDamageInfo
---@return GveBattleDamageInfoCellData
function GveHudDamageList.MakeCellData(index, damInfo, allDamage, maxPlayerDamage)
    ---@type GveBattleDamageInfoCellData
    local info = {}
    info.index = index
    info.isSelf = ModuleRefer.PlayerModule:IsMineById(damInfo.playerId)
    info.damageInfo = damInfo
    info.allDamage = allDamage
    info.maxPlayerDamage = maxPlayerDamage
    info.isThumbnail = true
    return info
end

function GveHudDamageList:UpdateTroopCount()
    local troops = self.module:GetAllTroops()
    if not troops then
        self.goGroupTitle:SetVisible(false)
        return
    end
    local count = #self.module:GetAllTroops()
    self.textNum.text = I18N.Get("alliance_behemoth_title_number") .. count
end

function GveHudDamageList:UpdateDamageInfo()
    self.tableRank:Clear()
    if self.bossId == nil then
        self.bossId = self.module.curBoss and self.module.curBoss.ID or nil
    end
    local damageList, allDamage, maxPlayerDamage = self.slgModule:GetMobDamageData(self.module.curBoss)

    if not damageList or damageList == {} then
        self.goTankingDetail:SetVisible(false)
        return
    end

    self.goTankingDetail:SetVisible(true)
    for index, value in ipairs(damageList) do
        ---@type GveBattleDamageInfoCellData
        local info = self.MakeCellData(index, value, allDamage, maxPlayerDamage)
        self.tableRank:AddData(info)
    end

    self:BeforeBattle()
end

function GveHudDamageList:BeforeBattle()
    if self.CheckBeforeBattle then
        return
    end

    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local passT = curTime - self.module:GetStartTime()

    -- 准备战斗阶段
    if passT < ConfigRefer.ConstMain:GvEStartWaitTime() then
        self.p_table_rank:SetVisible(false)
        self.p_confirm:SetVisible(true)
        local countdownT = math.ceil(ConfigRefer.ConstMain:GvEStartWaitTime() - passT)
        self.p_text_status.text = I18N.Get("alliance_behemoth_state_automatictime")
        self.p_text_status_1.text = TimeFormatter.TimerStringFormat(countdownT)
        self:ShowPrepareAreaVfx()

        if countdownT <= 6.2 and not self.playCountdown then
            self.playCountdown = true
            -- 战斗开始Toast
            ---@type CountdownToastMediatorParamter
            local param = {}
            param.startCountdownTime = curTime
            param.countdown = countdownT
            param.content = I18N.Get("alliance_challengeactivity_button_open")
            param.startText = I18N.Get("slg_warshow")
            ModuleRefer.ToastModule:ShowCountdownToast(param)
        end
    else
        self.p_table_rank:SetVisible(true)
        self.p_confirm:SetVisible(false)
        self.CheckBeforeBattle = true

        if self.prepareAreaVfx and self.prepareAreaVfx.Effect then
            self.prepareAreaVfx:Delete()
            self.prepareAreaVfx = nil
            self.playCountdown = nil
        end
    end
end

function GveHudDamageList:ShowPrepareAreaVfx()
    if self.prepareAreaVfx == nil then
        self.prepareAreaVfx = CS.DragonReborn.VisualEffect.VisualEffectHandle()
        self.prepareAreaVfx:Create(ManualResourceConst.vfx_bigmap_jushoulichang_01, ManualResourceConst.vfx_bigmap_jushoulichang_01, nil, function(success, obj, handle)
            if success then
                local go = handle.Effect.gameObject
                go.transform.localPosition = CS.UnityEngine.Vector3(1600, 0, 750)
                go.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 100, 0)
                go.transform.localScale = CS.UnityEngine.Vector3.one * 10
                self.prepareAreaVfx.Effect.gameObject:SetVisible(true)
            end
        end, nil, 0, false, false)
    end
end

function GveHudDamageList:OnMonsterModified()
    self.bossId = self.module.curBoss and self.module.curBoss.ID
    self:UpdateDamageInfo()
end

function GveHudDamageList:OnDamageChanged(data, changed)
    if data.ID ~= self.bossId then
        return
    end
    -- self:UpdateDamageInfo()
end

---@param data wds.Scene
function GveHudDamageList:OnMapLevelSyncDataChanged(data, changed)
    if data.ID ~= self.curSceneId then
        return
    end
    -- if changed then        
    self:UpdateObserverInfo(data.Level.SyncData.Global['observer_count'])
    -- end
end

---@param obsInfo wds.LevelDataUint
function GveHudDamageList:UpdateObserverInfo(obsInfo)
    if not self.obsCfgData then
        return
    end
    self.obsCount = obsInfo and obsInfo.IntValue or 0
    self.textNum1.text = I18N.GetWithParams('[*]观战人数:{1}人', self.obsCount)
    local p = math.clamp(self.obsCount / self.obsCfgData.maxCount, 0, 1)
    self.sliderProgressFillF.value = p
    if self.obsCount < self.obsCfgData.minCount then
        self.transWatchBuff:SetVisible(false)
    else
        self.transWatchBuff:SetVisible(true)
        local width = self.transProgressWatch.sizeDelta.x
        local buffPos = self.transWatchBuff.anchoredPosition
        buffPos.x = width * p
        self.transWatchBuff.anchoredPosition = buffPos
    end
end

function GveHudDamageList:OnBtnWatchDetailClicked(args)
    ---@type CommonTipsInfoMediatorParameter
    local param = {}
    param.title = I18N.Get('gve_observer_title')
    param.clickTransform = self.btnWatchDetail.transform
    param.contentList = {}

    local triggerIndex = -1
    for index, value in ipairs(self.obsCfgData.attrList) do
        if self.obsCount < value.obsCount then
            triggerIndex = index - 1
            break
        end
    end

    for index, value in ipairs(self.obsCfgData.attrList) do
        local infoState = 0
        if index == triggerIndex then
            infoState = 1
        elseif index < triggerIndex then
            infoState = 2
        end
        param.contentList[index] = {content = I18N.GetWithParams("[*]{1}人:    {2} +{3}", value.obsCount, I18N.Get(value.nameKey), value.value), state = infoState}
    end
    -- body
    g_Game.UIManager:Open(UIMediatorNames.CommonTipsInfoMediator, param)
end

return GveHudDamageList
