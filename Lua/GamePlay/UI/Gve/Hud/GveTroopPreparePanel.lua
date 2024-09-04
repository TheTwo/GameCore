local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')

---@class GveTroopPreparePanel : BaseUIComponent
---@field btnConfirm CS.StatusRecordParent
local GveTroopPreparePanel = class('GveTroopPreparePanel', BaseUIComponent)

function GveTroopPreparePanel:ctor()
    self.timerDuration = -1
    self.module = ModuleRefer.GveModule
end

function GveTroopPreparePanel:OnCreate()

    self.textHint = self:Text('p_text_hint')
    self.goPrepareTime = self:GameObject('p_prepare_time')
    self.textHintTime = self:Text('p_text_hint_time')
    self.troopTable = self:TableViewPro('p_table_troop')
    self:SteupConfirmButton()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self,self.Tick))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.TroopCandidateList.MsgPath,Delegate.GetOrCreate(self,self.OnTroopCandidateChanged))
end


function GveTroopPreparePanel:OnShow(param)
    -- self:SteupConfirmButton()
    self.btnConfirm:Play(1)
end

function GveTroopPreparePanel:OnHide(param)
end

function GveTroopPreparePanel:OnOpened(param)
end

function GveTroopPreparePanel:OnClose(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.TroopCandidateList.MsgPath,Delegate.GetOrCreate(self,self.OnTroopCandidateChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self,self.Tick))
end

function GveTroopPreparePanel:OnFeedData(param)
end

---@param data wds.ScenePlayer
function GveTroopPreparePanel:OnTroopCandidateChanged(data,changed)
   if changed.StageEndTime or changed.Stage then
    self:UpdateTimer()
   end
end

function GveTroopPreparePanel:SteupConfirmButton()
    -- local buttonParam = {}
    -- buttonParam.onClick = Delegate.GetOrCreate(self,self.OnTroopSelectBtnClick)--fun(clickData:any)
    -- buttonParam.buttonText = I18N.Get('alliance_battle_button8')--string

    -- self.btnConfirm:FeedData(buttonParam)

    self.btnConfirm = self:StatusRecordParent('child_comp_btn_battle')
    self.btnConfirmNormal = self:Button('child_comp_btn_b_s', Delegate.GetOrCreate(self, self.OnTroopSelectBtnClick))
    self.btnTextConfirmNormal = self:Text('p_text_b', I18N.Get('alliance_battle_button8'))
    self.btnConfirmDisable = self:Button('child_comp_btn_d_s', Delegate.GetOrCreate(self, self.OnTroopSelectDisableBtnClick))
    self.btnTextConfirmDisable = self:Text('p_text_d', I18N.Get('alliance_battle_button8'))
end

function GveTroopPreparePanel:OnTroopSelectBtnClick()
    ModuleRefer.GveModule:SendSelectTroopParam()
end

function GveTroopPreparePanel:OnTroopSelectDisableBtnClick()
    
end

function GveTroopPreparePanel:SteupTroopTable()
    local myTroops = ModuleRefer.GveModule:GetAllTroops()
    self.troopTable:Clear()
    local onClickDelegate = Delegate.GetOrCreate(self,self.OnTroopCellClick)
    self.troopTableData = {}
    local defaultIndex = -1
    if myTroops then
        for index, value in ipairs(myTroops) do
            self.troopTableData[index] = {
                index = index,
                troopData = value,
                onClick = onClickDelegate
            }
            self.troopTable:AppendData(self.troopTableData[index])
            if defaultIndex < 0 and value.Status ~= wds.TroopCandidateStatus.TroopCandidateDead then
                defaultIndex = index
            end
        end
    end
    self.troopTable:RefreshAllShownItem(false)
    self:OnTroopCellClick(defaultIndex)
end

function GveTroopPreparePanel:OnTroopCellClick(index)
    if self.onTroopSelection then
        self.onTroopSelection(index)
    end
    self:UpdateSelect()
end

function GveTroopPreparePanel:UpdateSelect()
    local selectIndex = ModuleRefer.GveModule.selectTroopIndex
    if self.troopTableData[selectIndex] then
        self.troopTable:SetToggleSelect(self.troopTableData[selectIndex])
        -- self.btnConfirm:SetEnabled(true)
        self.btnConfirm:Play(0)
    end
end

function GveTroopPreparePanel:UpdateTimer()
    local dbData = self.module:GetTroopCandidateDBData()
    if dbData then
        self.timerDuration = (dbData.StageEndTime - g_Game.ServerTime:GetServerTimestampInMilliseconds())/1000.0
    end
    if self.timerDuration > 0 then
        self.timerStr = string.format('%0.0f',self.timerDuration) .. 's'
        self.textHintTime.text = self.timerStr
    else
        self.timerDuration = nil
        self.timerStr = ''
        self.textHintTime.text = self.timerStr
    end
end



function GveTroopPreparePanel:SetState_Ready(param)
    self.goPrepareTime:SetVisible(true)
    self.textHint.text = I18N.Get('alliance_battle_hud15')
    self.troopTable:SetVisible(false)
    self.btnConfirm:SetVisible(false)
    self:UpdateTimer()
end

function GveTroopPreparePanel:SetState_TroopSelction(param)
    self.onTroopSelection = param.onSelect
    self.goPrepareTime:SetVisible(true)
    self.textHint.text = I18N.Get('alliance_battle_hud17')
    self.troopTable:SetVisible(true)
    self.btnConfirm:SetVisible(true)
    self:UpdateTimer()
    self:SteupTroopTable()
end

function GveTroopPreparePanel:SetState_DeadWait(param)
    self.goPrepareTime:SetVisible(true)
    self.textHint.text = I18N.Get('alliance_battle_hud19')
    self.troopTable:SetVisible(false)
    self.btnConfirm:SetVisible(false)
    self:UpdateTimer()
end

function GveTroopPreparePanel:SetState_OB(param)
    self.goPrepareTime:SetVisible(false)
    self.textHint.text = I18N.Get('alliance_battle_hud20')
    self.troopTable:SetVisible(false)
    self.btnConfirm:SetVisible(false)
end

function GveTroopPreparePanel:Tick(delta)
    if not self.timerDuration then
        self.textHintTime.text = '--'
        return
    end
    if  self.timerDuration < 0 then
        return
    end
    self.timerDuration = self.timerDuration - delta
    if self.timerDuration > 0 then
        local tmpTimerStr = string.format('%0.0f',self.timerDuration) .. 's'
        if self.timerStr ~= tmpTimerStr then
            self.timerStr = tmpTimerStr
            self.textHintTime.text = self.timerStr
        end
    else
        self.textHintTime.text = '0s'
    end
end

return GveTroopPreparePanel
