local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local QueuedTask = require("QueuedTask")
local SeScene = require("SeScene")
local UIMediatorNames = require("UIMediatorNames")
---@class SESettlementStrengthenCell : BaseTableViewProCell
local SESettlementStrengthenCell = class("SESettlementStrengthenCell", BaseTableViewProCell)

function SESettlementStrengthenCell:ctor()
end

function SESettlementStrengthenCell:OnCreate()
    self.textDetail = self:Text("p_text_detail")
    self.btnGoto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnBtnGotoClick))
    self.goLock = self:GameObject("p_icon_lock")
end

---@param data CultivateDataProvider
function SESettlementStrengthenCell:OnFeedData(data)
    self.data = data
    if not data or not next(data) then
        self.textDetail.text = "power_dev_hq_levelup_name"
        return
    end
    self.textDetail.text = data:GetName()
    self.goLock:SetActive(data:GetGotoId() <= 0)
    self.btnGoto.gameObject:SetActive(data:GetGotoId() > 0)
end

function SESettlementStrengthenCell:OnBtnGotoClick()
    self:GetParentBaseUIMediator():Quit()
    g_Game.StateMachine:WriteBlackboard("NEED_REOPEN_MEDIATOR_NAME", nil, true)
    local queuedTask = QueuedTask.new()
    queuedTask:WaitTrue(function()
        local loadingMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.LoadingPageMediator)
        local curSceneName = g_Game.SceneManager:GetCurrentSceneName()
        return not loadingMediator and curSceneName ~= SeScene.Name
    end):DoAction(function()
        if self.data and next(self.data) then
            self.data:OnGoto()
        end
    end):Start()
end

return SESettlementStrengthenCell