local BaseTableViewProCell = require('BaseTableViewProCell')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local EarthRevivalDefine = require('EarthRevivalDefine')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
---@class EarthRevivalTaskCell : BaseTableViewProCell
local EarthRevivalTaskCell = class('EarthRevivalTaskCell', BaseTableViewProCell)

EarthRevivalTaskCell.updatingCount = 0

function EarthRevivalTaskCell:OnCreate()
    self.textTask = self:Text('p_text_task')
    self.tableReward = self:TableViewPro('p_table_reward')
    self.luaBtnClaim = self:LuaObject('p_btn_claim')
    self.goClaimed = self:GameObject('p_icon_finish')
    self.goLocked = self:GameObject('p_lock')
    self.textLock = self:Text('p_text_lock')
    self.goRoot = self:GameObject('')
    self.goGroup = self:GameObject('p_info_group')
    self.textTaskLock = self:Text('p_text_task_lock')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.textGoto = self:Text('p_text', I18N.Get('world_qianwang'))
    self.goBtnClaim = self:GameObject('p_btn_claim')
    ---@type CS.UnityEngine.Animation
    self.animCell = self:BindComponent("vfx_formula_lightsweep", typeof(CS.UnityEngine.Animation))
end

---@param param TaskLinkDataProvider
function EarthRevivalTaskCell:OnFeedData(param)
    self.param = param
    self:UpdateUI()
end

function EarthRevivalTaskCell:UpdateUI()
    if self.param:LinkFinished() then
        self.provider = self.param:GetLastTaskItemDataProvider()
    else
        self.provider = self.param:GetCurTaskItemDataProvider()
    end
    self.textTask.text = self.provider:GetTaskStr()
    self.textTaskLock.text = self.provider:GetTaskStr(true)
    self.tableReward:Clear()
    local score = string.split(self.provider:GetTaskCfg():FinishBranch(1):BranchReward(1):Param(), ';')[2]
    if score then
        local scoreItem = EarthRevivalDefine.ProgressItemId
        local scoreItemCfg = ConfigRefer.Item:Find(scoreItem)
        local count = tonumber(score)
        local data = {}
        data.configCell = scoreItemCfg
        data.count = count
        data.showTips = true
        self.tableReward:AppendData(data)
    end
    for _, reward in ipairs(self.provider:GetTaskRewards()) do
        self.tableReward:AppendData(reward)
    end
    ---@type BistateButtonSmallParam
    local btnParam = {}
    btnParam.buttonText = I18N.Get('worldstage_lingqu')
    btnParam.disableButtonText = I18N.Get('worldstage_lingqu')
    btnParam.onClick = self.provider.onClaim

    self.provider:SetClaimCallback(function()
        self.animCell:Play()
        if self.param:LinkFinished() then
            g_Game.EventManager:TriggerEvent(EventConst.ON_FIRE_PLAN_TASK_LINK_FINISH)
        else
            self:UpdateUI()
        end
    end)

    self.luaBtnClaim:FeedData(btnParam)
    self.textTask.gameObject:SetActive(true)
    self.luaBtnClaim:SetVisible(false)
    self.btnGoto.gameObject:SetActive(false)
    self.goClaimed:SetActive(false)
    self.goBtnClaim:SetActive(false)

    self.goLocked:SetActive(false)
    self.textTask.gameObject:SetActive(true)
    self.textTaskLock.gameObject:SetActive(false)
    self.goClaimed:SetActive(self.param:LinkFinished())
    self.luaBtnClaim:SetEnabled(self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish)
    self.luaBtnClaim:SetVisible(self.provider:GetTaskState() == wds.TaskState.TaskStateCanFinish or
        (self.provider:GetTaskState() == wds.TaskState.TaskStateReceived and not self.provider:HasGoto()))
    self.btnGoto.gameObject:SetActive(self.provider:GetTaskState() == wds.TaskState.TaskStateReceived and self.provider:HasGoto())
end

function EarthRevivalTaskCell:OnClickGoto()
    self.provider:OnGoto()
end

return EarthRevivalTaskCell