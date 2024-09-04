local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local GuideUtils = require("GuideUtils")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder

---@class WorldTrendStageCell : BaseTableViewProCell
local WorldTrendStageCell = class('WorldTrendStageCell', BaseTableViewProCell)

---@class WorldTrendStageCellParam
---@field lastStage number      上一阶段
---@field stage number          当前阶段
---@field isOpen boolean
---@field index number

function WorldTrendStageCell:OnCreate()
    self.animTrigger = self:GameObject("p_cell_group"):GetComponent(typeof(CS.FpAnimation.FpAnimationCommonTrigger))
    -- stageOpen
    self.goStageOpen = self:GameObject('p_stage_open')
    self.goPersonalTask = self:GameObject('p_btn_personal_task')
    self.goAllianceTask = self:GameObject('p_btn_alliance_task')
    self.goGlobalTask = self:GameObject('p_btn_global_task')
    self.goUnlockInfo = self:GameObject('p_unlock_info')
    self.goGlobalBranch = self:GameObject('p_btn_global_branch')
    self.goStageClose = self:GameObject('p_stage_close')
    self.luagoPersonalTask = self:LuaObject('p_btn_personal_task')
    self.luagoAllianceTask = self:LuaObject('p_btn_alliance_task')
    self.luagoGlobalTask = self:LuaObject('p_btn_global_task')
    self.luagoUnlockInfo = self:LuaObject('p_unlock_info')
    self.luagoGlobalBranch = self:LuaObject('p_btn_global_branch')

    -- stageInfo
    self.textStageName = self:Text('p_text_stage_name')
    self.textStageDesc = self:Text('p_text_stage_desc')
    self.statusStageInfo = self:StatusRecordParent('p_stage_info')
    self.textStageDescLong = self:Text('p_text_stage_desc_long')
    self.btnOpenDetailDesc = self:Button('p_btn_view_open', Delegate.GetOrCreate(self, self.OnClickOpenDetailDesc))
    self.btnCLoseDetailDesc = self:Button('p_btn_view_close', Delegate.GetOrCreate(self, self.OnClickCloseDetailDesc))
    -- self.imgStageDot = self:Image('dot')

    -- stageClose
    self.goLockInfo = self:GameObject('p_lock_info')
    self.textCondition = self:Text('p_text_condition', I18N.Get("WorldStage_info_open_Stage_not_open"))
    self.textOpenTime = self:Text('p_text_open_time')

    self.goLockCondition1 = self:GameObject('p_lock_01')
    -- self.textLockCondition1 = self:Text('p_text_lock_01')
    self.imgLockConditionIcon1 = self:Image('p_icon_01')
    self.btnLockDetail1 = self:Button('p_btn_lock_detail_01', Delegate.GetOrCreate(self, self.OnClickLockDetail1))
    self.goLockCondition2 = self:GameObject('p_lock_02')
    -- self.textLockCondition2 = self:Text('p_text_lock_02')
    self.imgLockConditionIcon2 = self:Image('p_icon_02')
    self.btnLockDetail2 = self:Button('p_btn_lock_detail_02', Delegate.GetOrCreate(self, self.OnClickLockDetail2))

    self.p_base_stage = self:Image("p_base_stage")
    self.rectScroll = self:RectTransform('scroll_long')

    self.textLockSubtitle = self:Text('p_text_lock_subtitle',I18N.Get('WorldStage_unlockSystem_title'))
end

function WorldTrendStageCell:OnShow()
    self:RegisterEvent()
    self:OnClickCloseDetailDesc()
end

function WorldTrendStageCell:OnHide()
    self:UnregisterEvent()
end

---@param param WorldTrendStageCellParam
function WorldTrendStageCell:OnFeedData(param)
    if not param then
        return
    end
    self.isOpen = param.isOpen
    self.lastStage = param.lastStage
    self.curStage = param.stage
    self.curMaxStage = param.curMaxStage
    if self.isOpen then
        self:InitStageOpenCell()
    else
        if (self.curMaxStage < 1) then
            self.textCondition.text = I18N.Get("WorldStage_info_Preview")
        else
            self.textCondition.text = I18N.Get("WorldStage_info_open_Stage_not_open")
        end
        self:InitStageCloseCell()
    end
end

function WorldTrendStageCell:RegisterEvent()
end

function WorldTrendStageCell:UnregisterEvent()
    if(self.SetStageDescSeq) then
        self.SetStageDescSeq:Kill()
        self.SetStageDescSeq = nil
    end
end

function WorldTrendStageCell:SetStageDesc()
    if(self.SetStageDescSeq) then
        self.SetStageDescSeq:Kill()
        self.SetStageDescSeq = nil
    end

    self.SetStageDescSeq = CS.DG.Tweening.DOTween.Sequence()
    self.SetStageDescSeq:InsertCallback(0.1, function()
        local fullText = I18N.Get(self.stageConfig:CondDesc())
        self.textStageDesc.text = fullText
        UIHelper.SetStringEllipsis(self.textStageDesc, fullText)
        self.textStageDescLong.text = fullText
    end
    )
end

function WorldTrendStageCell:InitStageOpenCell()
    if(ModuleRefer.WorldTrendModule.PlayOpenVX and self.curStage == self.curMaxStage) then
        self.animTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        ModuleRefer.WorldTrendModule.PlayOpenVX = nil
    end

    self.goStageOpen:SetActive(true)
    self.goStageClose:SetActive(false)

    local stageConfig = ConfigRefer.WorldStage:Find(self.curStage)
    self.stageConfig = stageConfig
    if not stageConfig then
        return
    end
    g_Game.SpriteManager:LoadSprite(stageConfig:StageBackground(), self.p_base_stage)
    self.textStageName.text = I18N.Get(stageConfig:StageDesc())
    self:SetStageDesc()

    if stageConfig:PlayerTasksLength() > 0 and stageConfig:PlayerTasks(1) then
        ---@type WorldTrendTaskParam
        self.luagoPersonalTask:OnFeedData({taskID = stageConfig:PlayerTasks(1), stage = self.curStage})
    end

    if stageConfig:AllianceTasksLength() > 0 and stageConfig:AllianceTasks(1) then
        ---@type WorldTrendTaskParam
        self.luagoAllianceTask:OnFeedData({taskID = stageConfig:AllianceTasks(1), stage = self.curStage})
    end

    -- 有分支
    if stageConfig:BranchesLength() > 1 then
        self.goGlobalTask:SetActive(false)
        self.goUnlockInfo:SetActive(false)
        self.goGlobalBranch:SetActive(true)
        ---@type WorldTrendBranchParam
        self.luagoGlobalBranch:OnFeedData({stageID = self.curStage})
    else
        self.goGlobalTask:SetActive(true)
        self.goGlobalBranch:SetActive(false)
        if stageConfig:KingdomTasksLength() > 0 and stageConfig:KingdomTasks(1) then
            ---@type WorldTrendTaskParam
            self.luagoGlobalTask:OnFeedData({taskID = stageConfig:KingdomTasks(1), stage = self.curStage, desc = stageConfig:KingdomTaskDesc()})
        end
    end

    if stageConfig:UnlockSystemsLength() > 0 then
        ---@type WorldTrendUnlockParam
        self.goUnlockInfo:SetActive(true)
        self.luagoUnlockInfo:OnFeedData({stageID = self.curStage})
    else
        self.goUnlockInfo:SetActive(false)
    end
end

function WorldTrendStageCell:InitStageCloseCell()
    if(ModuleRefer.WorldTrendModule.PlayOpenVX and self.curStage == self.curMaxStage) then
        self.animTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        ModuleRefer.WorldTrendModule.PlayOpenVX = nil
    end

    self.goStageOpen:SetActive(false)
    self.goStageClose:SetActive(true)
    self:ShowOpenTime()
    local stageConfig = ConfigRefer.WorldStage:Find(self.curStage)
    if not stageConfig then
        return
    end
    if stageConfig:UnlockSystemsLength() > 0 and self.curMaxStage > 0 then
        self.goLockInfo:SetVisible(true)
        local sys2 = stageConfig:UnlockSystemsLength() == 2 and stageConfig:UnlockSystems(2) or -1
        self:InitUnlockInfo(stageConfig:UnlockSystems(1), sys2)
    else
        self.goLockInfo:SetVisible(false)
    end
end

function WorldTrendStageCell:GetRefreshTime(seconds)
    local int = math.floor(seconds);
    if int ~= int then
        return "--:--:--"
    end
    local h = int // 3600;
    int = int - h * 3600;
    local m = int // 60;
    local s = int % 60;
    return ("%02d:%02d:%02d"):format(h, m, s);
end

function WorldTrendStageCell:ShowOpenTime()
    local openTime = ModuleRefer.WorldTrendModule:GetStageOpenTime(self.curStage)
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()

    --活动开始前 UI表现
    if (openTime == 0) then
        self.textOpenTime:SetVisible(false)
        return
    end

    local leftTime = openTime - curTime
    if leftTime > TimeFormatter.OneDaySeconds then
        self.textOpenTime.text = I18N.GetWithParams("WorldStage_info_open_", TimeFormatter.TimeToDateTimeStringUseFormat(openTime, "yyyy/MM/dd HH:mm:ss"))
    else
        local h = leftTime // 3600
        leftTime = leftTime - h * 3600
        local m = leftTime // 60
        local s = leftTime % 60
        local d = h // 24

        if m == 0 and s > 0 then
            m = 1
        end

        if d > 0 then
            self.textOpenTime.text = I18N.GetWithParams("WorldStage_countdown_1", d)
        elseif h > 0 then
            self.textOpenTime.text = I18N.GetWithParams("WorldStage_countdown_2", h)
        elseif m > 0 then
            self.textOpenTime.text = I18N.GetWithParams("WorldStage_countdown_3", m)
        end
    end
end

function WorldTrendStageCell:InitUnlockInfo(sys1, sys2)
    local sysConfig1 = ConfigRefer.SystemEntry:Find(sys1)
    local sysConfig2 = ConfigRefer.SystemEntry:Find(sys2)
    if not sysConfig1 then
        self.goLockCondition1:SetActive(false)
    else
        self.goLockCondition1:SetActive(true)
        -- self.textLockCondition1.text = sysConfig1:Name()
        local spriteName = sysConfig1:Icon()
        if not string.IsNullOrEmpty(spriteName) then
            g_Game.SpriteManager:LoadSprite(spriteName, self.imgLockConditionIcon1)
        end
    end
    if not sysConfig2 then
        self.goLockCondition2:SetActive(false)
    else
        self.goLockCondition2:SetActive(true)
        -- self.textLockCondition2.text = sysConfig2:Name()
        local spriteName = sysConfig2:Icon()
        if not string.IsNullOrEmpty(spriteName) then
            g_Game.SpriteManager:LoadSprite(spriteName, self.imgLockConditionIcon2)
        end
    end
end

function WorldTrendStageCell:OnClickLockDetail1()
    local config = ConfigRefer.WorldStage:Find(self.curStage)
    if not config then
        return
    end
    if config:UnlockSystemTipsLength() > 0 and not string.IsNullOrEmpty(config:UnlockSystemTips(1)) then
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = self.btnLockDetail1:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.content = I18N.Get(config:UnlockSystemTips(1))
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
end

function WorldTrendStageCell:OnClickLockDetail2()
    local config = ConfigRefer.WorldStage:Find(self.curStage)
    if not config then
        return
    end
    if config:UnlockSystemTipsLength() > 1 and not string.IsNullOrEmpty(config:UnlockSystemTips(2)) then
        ---@type TextToastMediatorParameter
        local param = {}
        param.clickTransform = self.btnLockDetail2:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.content = I18N.Get(config:UnlockSystemTips(2))
        ModuleRefer.ToastModule:ShowTextToast(param)
    end
end

function WorldTrendStageCell:OnClickOpenDetailDesc()
    self.statusStageInfo:SetState(1)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.rectScroll)
end

function WorldTrendStageCell:OnClickCloseDetailDesc()
    self.statusStageInfo:SetState(0)
end

return WorldTrendStageCell
