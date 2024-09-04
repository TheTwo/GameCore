--- scene:scene_league_popup_gift

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ProtocolId = require("ProtocolId")
local DBEntityPath = require("DBEntityPath")
local timestamp = require("timestamp")
local AllianceGiftType = require("AllianceGiftType")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceGiftMediator:BaseUIMediator
---@field new fun():AllianceGiftMediator
---@field super BaseUIMediator
local AllianceGiftMediator = class('AllianceGiftMediator', BaseUIMediator)

function AllianceGiftMediator:ctor()
    AllianceGiftMediator.super.ctor(self)
    self._eventAdd = false
    self._allianceId = nil
    ---@type table<number, wds.AllianceGiftInfo>
    self._serverData = {}
    ---@type AllianceGiftCellData[]
    self._tabData = {}
    self._tab = nil
    self._nextTime = nil
    ---@type number|nil
    self._delayShowReward = nil
    self._delayShowRewardQueue = {}
    self._triggerFetchData = false
end

function AllianceGiftMediator:OnCreate(param)
    ---@see CommonPopupBackComponent
    self._child_popup_base_l = self:LuaBaseComponent("child_popup_base_l")
    
    -- left
    self._p_base_gift = self:Image("p_base_gift")
    self._p_btn_box = self:Button("p_btn_box", Delegate.GetOrCreate(self, self.OnClickBox))
    self._p_btn_box_img = self:Image("p_btn_box")
    self._p_progress_box = self:Slider("p_progress_box")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_box = self:Text("p_text_box")
    self._p_text_quantity_coin = self:Text("p_text_quantity_coin")
    self._p_progress_lv = self:Slider("p_progress_lv")
    self._p_btn_info = self:Button("p_btn_info", Delegate.GetOrCreate(self, self.OnClickTipInfo))
    
    
    -- right
    self._p_tab = self:StatusRecordParent("p_tab")
    self._p_btn_a = self:Button("p_btn_a", Delegate.GetOrCreate(self, self.OnClickBtnTabA))
    self:Text("p_text_a_n", "alliance_gift_tab1")
    self:Text("p_text_a", "alliance_gift_tab1")
    ---@type NotificationNode
    self._child_reddot_default_a = self:LuaObject("child_reddot_default_a")
    self._p_btn_b = self:Button("p_btn_b", Delegate.GetOrCreate(self, self.OnClickBtnTabB))
    self:Text("p_text_b_n", "alliance_gift_tab2")
    self:Text("p_text_b", "alliance_gift_tab2")
    ---@type NotificationNode
    self._child_reddot_default_b = self:LuaObject("child_reddot_default_b")
    
    self._p_table = self:TableViewPro("p_table")
    self._p_empty = self:GameObject("p_empty")
    self:Text("p_text_empty", "alliance_gift_nonegift")
    
    self._p_comp_btn_b_l = self:Button("p_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickClaimAll))
    self:Text("p_text", "alliance_gift_getall_btn")
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickDelete))
    self:Text("p_text_delete", "alliance_gift_clear_btn")
    
    self._p_upgrade = self:GameObject("p_upgrade")
    self._p_text_upgrade = self:Text("p_text_upgrade")
    self._p_text_lv_upgrade = self:Text("p_text_lv_upgrade")
    self._p_upgrade:SetVisible(false)
    self._p_upgrade_trigger = self:AnimTrigger("p_upgrade")
    
    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

function AllianceGiftMediator:OnShow(param)
    self:SetupEvents(true)
end

function AllianceGiftMediator:OnHide(param)
    self._allianceId = nil
    self:SetupEvents(false)
end

function AllianceGiftMediator:OnOpened(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_gift_title")
    backBtnData.onClose = Delegate.GetOrCreate(self, self.CheckClickClose)
    self._child_popup_base_l:FeedData(backBtnData)
    self:OnClickBtnTabA(true)
    self:FetchData()
    self:SetupEnergyBox()
end

function AllianceGiftMediator:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.ServiceManager:AddResponseCallback(ProtocolId.GetAllianceGiftsList, Delegate.GetOrCreate(self, self.OnAllianceGiftDataRet))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceGifts.GiftLevel.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceGiftLevelChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceGifts.GiftExp.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceGiftExpChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceGifts.EnergyBoxLevel.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceEnergyBoxLevelChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceGifts.EnergyBoxExp.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceEnergyBoxExpChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.GetAllianceGiftsList, Delegate.GetOrCreate(self, self.OnAllianceGiftDataRet))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceGifts.GiftLevel.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceGiftLevelChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceGifts.GiftExp.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceGiftExpChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceGifts.EnergyBoxLevel.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceEnergyBoxLevelChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceGifts.EnergyBoxExp.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceEnergyBoxExpChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    end
end

function AllianceGiftMediator:FetchData()
    ModuleRefer.AllianceModule:GetAllianceGiftsList()
end

function AllianceGiftMediator:SetupEnergyBox()
    local boxInfo,waitGetIds, boxConfig, levelConfig = ModuleRefer.AllianceModule:GetAllianceEnergyBoxInfo()
    if not boxInfo then
        return
    end
    g_Game.SpriteManager:LoadSprite(boxConfig:QualityBg(), self._p_base_gift)
    g_Game.SpriteManager:LoadSprite(boxConfig:Icon(), self._p_btn_box_img)
    self._p_progress_box.value = math.inverseLerp(0, boxConfig:EnergyBoxExp(), boxInfo.EnergyBoxExp)
    self._p_text_quantity.text = ("%d/%d"):format(boxInfo.EnergyBoxExp, boxConfig:EnergyBoxExp())
    local lvStr =  tostring(boxInfo.EnergyBoxLevel)
    self._p_text_lv.text = lvStr
    self._p_text_box.text = I18N.GetWithParams("alliance_gift_chest_title", lvStr)
    self._p_text_quantity_coin.text = ("%d/%d"):format(boxInfo.GiftExp, levelConfig and levelConfig:GiftExp() or 0)
    self._p_progress_lv.value = math.inverseLerp(0, levelConfig and levelConfig:GiftExp() or 0, boxInfo.GiftExp)
    self._vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom3)
    if table.isNilOrZeroNums(waitGetIds) then
        self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    else
        self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
end

---@return boolean
function AllianceGiftMediator.AllianceGiftInfoFieldEqual(valueA, valueB)
    if valueA == valueB then
        return true
    end
    local typeA = type(valueA)
    local typeB = type(valueB)
    if typeA ~= typeB then
        return false
    end
    if typeA ~= 'table' then
        return false
    end
    if valueA == nil then
        return true
    end
    if valueA.TypeName and valueA.TypeName == timestamp.TypeName then
        return valueA.timeSeconds == valueB.timeSeconds and valueA.nanos == valueB.nanos
    end
    return false
end

---@param from table<number, wds.AllianceGiftInfo>
---@param to table<number, wds.AllianceGiftInfo>
---@return table<number, wds.AllianceGiftInfo>,  table<number, wds.AllianceGiftInfo>, table<number, wds.AllianceGiftInfo[]> @add,remove,change
function AllianceGiftMediator.GetAddRemoveChange(from, to)
    local add = {}
    local remove = {}
    local change = {}
    for id, v in pairs(to) do
        local oldV = from[id]
        if not oldV then
            add[id] = v
        else
            for fieldKey, fieldValue in pairs(oldV) do
                if not AllianceGiftMediator.AllianceGiftInfoFieldEqual(fieldValue, v[fieldKey]) then
                    change[id] = {v, oldV}
                    break
                end
            end
        end
    end
    for id, v in pairs(from) do
        if not to[id] then
            remove[id] = v
        end
    end
    return add,remove,change
end

---@param isSuccess boolean
---@param rsp wrpc.GetAllianceGiftsListReply
function AllianceGiftMediator:OnAllianceGiftDataRet(isSuccess, rsp)
    if not self._allianceId or not isSuccess then
        return
    end
    local toMap = {}
    for _, v in pairs(rsp.Gifts) do
        toMap[v.GiftID] = v
    end
    local add,remove,change = AllianceGiftMediator.GetAddRemoveChange(self._serverData, toMap)
    self._serverData = toMap
    local list = self._tabData
    local needRefresh = false

    for i = #list, 1, -1 do
        local cell = list[i]
        if remove[cell.serverData.GiftID] then
            table.remove(list, i)
            self._p_table:RemData(cell)
        end
    end
    
    for _, v in ipairs(list) do
        local changeData = change[v.serverData.GiftID]
        if changeData then
            v.serverData = changeData[1]
            needRefresh = true
        end
    end
    local addCell = {}
    for _, v in pairs(add) do
        if v.Typo == self._tab then
            ---@type AllianceGiftCellData
            local cellData = {}
            cellData.serverData = v
            cellData.host = self
            table.insert(addCell, cellData)
        end
    end
    for _, v in pairs(addCell) do
        needRefresh = true
        table.insert(list, v)
    end
    if needRefresh then
        AllianceGiftMediator.NowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        table.sort(list, AllianceGiftMediator.Sorter)
        self._p_table:Clear()
        for i, v in ipairs(list) do
            self._p_table:AppendData(v)
        end
    end
    self._p_empty:SetVisible(#list <= 0)
    self._p_comp_btn_b_l:SetVisible(self._tab == AllianceGiftType.Normal and #list > 0)
    self._p_btn_delete:SetVisible(#list > 0)
    self:UpdateTabNotify()
    self:SetupEnergyBox()
    self._nextTime = nil
end

AllianceGiftMediator.NowTime = 0

---@param cellA AllianceGiftCellData
---@param cellB AllianceGiftCellData
---@return boolean
function AllianceGiftMediator.Sorter(cellA, cellB)
    local a = cellA.serverData
    local b = cellB.serverData
    local aIsExpired = a.ExpirationTime.ServerSecond <= AllianceGiftMediator.NowTime
    local bIsExpired = b.ExpirationTime.ServerSecond <= AllianceGiftMediator.NowTime
    local aCanGet = not a.IsGet and not aIsExpired
    local bCanGet = not b.IsGet and not bIsExpired
    if aCanGet and not bCanGet then
        return true
    end
    if not aCanGet and bCanGet then
        return false
    end
    if aCanGet then
        return a.ExpirationTime.ServerSecond < b.ExpirationTime.ServerSecond
    else
        return a.CreateTime.ServerSecond < b.CreateTime.ServerSecond
    end
end

---@param entity wds.Alliance
function AllianceGiftMediator:OnAllianceGiftLevelChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:SetupEnergyBox()
end

---@param entity wds.Alliance
function AllianceGiftMediator:OnAllianceGiftExpChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:SetupEnergyBox()
end

---@param entity wds.Alliance
function AllianceGiftMediator:OnAllianceEnergyBoxLevelChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:SetupEnergyBox()
    self._p_text_upgrade.text = I18N.Get("alliance_gift_chestlvup")
    self._p_text_lv_upgrade.text = tostring(entity.AllianceGifts.EnergyBoxLevel)
    self._p_upgrade:SetVisible(true)
    self._p_upgrade_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1, function()
        self._p_upgrade:SetVisible(false)
    end)
end

---@param entity wds.Alliance
function AllianceGiftMediator:OnAllianceEnergyBoxExpChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self:SetupEnergyBox()
end

function AllianceGiftMediator:OnClickBox()
    if self:IsPlayingEffect() then return end
    local _,waitGetIds, energyBoxConfig, _ = ModuleRefer.AllianceModule:GetAllianceEnergyBoxInfo()
    if not waitGetIds then
        return
    end
    if waitGetIds and #waitGetIds > 0 then
        ModuleRefer.AllianceModule:OpenAllianceEnergyBox(self._p_btn_box.transform, waitGetIds, function(cmd, isSuccess, rsp)
            if isSuccess then
                if self._allianceId then
                    g_Game.SoundManager:Play("sfx_se_world_alliancegift_gold")
                    self._vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
                    self._vx_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom2)
                    local length = self._vx_trigger:GetTriggerTypeAnimLength(CS.FpAnimation.CommonTriggerType.Custom3)
                    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
                    if length and length > 0 then
                        self:DelayShowReward(rsp, math.min(length, 1.2))
                    else
                        self:DelayShowReward(rsp, 1.2)
                    end
                    return
                end
            end
            self._triggerFetchData = true
        end)
    else
        ---@type AllianceGiftTipsPopupMediatorParameter
        local param = {}
        param.clickTrans = self._p_btn_box:GetComponent(typeof(CS.UnityEngine.RectTransform))
        param.energyBoxConfig = energyBoxConfig
       g_Game.UIManager:Open(UIMediatorNames.AllianceGiftTipsPopupMediator, param) 
    end
end

function AllianceGiftMediator:DelayShowReward(rsp, delay)
    if not self._delayShowReward then
        self._delayShowReward = delay
    end
    local delayCall = function()
        if rsp and not table.isNilOrZeroNums(rsp.Reward) then
            ---@type UIRewardMediatorParameter
            local data = {}
            data.itemInfo = {}
            data.itemProfiteType = wds.enum.ItemProfitType.ItemAddByOpenBox
            for itemId, count in pairs(rsp.Reward) do
                ---@type UIRewardMediatorItemData
                local cell = {}
                cell.id = itemId
                cell.count = count
                table.insert(data.itemInfo, cell)
            end
            ModuleRefer.RewardModule:ShowDefaultReward(data)
        end
        self._triggerFetchData = true
    end
    table.insert(self._delayShowRewardQueue, delayCall)
end

function AllianceGiftMediator:OnClickTipInfo()
    if self:IsPlayingEffect() then return end
    ---@type TextToastMediatorParameter
    local parameter = {}
    parameter.content = I18N.Get("alliance_gift_tips_desc")
    parameter.clickTransform = self._p_btn_info.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    ModuleRefer.ToastModule:ShowTextToast(parameter)
end

function AllianceGiftMediator:OnClickBtnTabA(clearOnly)
    if self._tab == AllianceGiftType.Normal then
        return
    end
    if self:IsPlayingEffect() then return end
    self._tab = AllianceGiftType.Normal
    self:DoChangeTable(clearOnly)
    self._p_comp_btn_b_l:SetVisible(#self._tabData > 0)
    self._p_btn_delete:SetVisible(#self._tabData > 0)
end

function AllianceGiftMediator:OnClickBtnTabB(clearOnly)
    if self._tab == AllianceGiftType.Specail then
        return
    end
    if self:IsPlayingEffect() then return end
    self._tab = AllianceGiftType.Specail
    self:DoChangeTable(clearOnly)
    self._p_comp_btn_b_l:SetVisible(false)
    self._p_btn_delete:SetVisible(#self._tabData > 0)
end

function AllianceGiftMediator:DoChangeTable(clearOnly)
    self._p_tab:SetState(self._tab - 1)
    table.clear(self._tabData)
    self._p_table:Clear()
    if clearOnly then
        self._p_empty:SetVisible(true)
        return
    end
    local t = self._tab
    local serverData = self._serverData
    for i, v in pairs(serverData) do
        if v.Typo == t then
            ---@type AllianceGiftCellData
            local cellData = {}
            cellData.serverData = v
            cellData.host = self
            table.insert(self._tabData, cellData)
        end
    end
    AllianceGiftMediator.NowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    table.sort(self._tabData, AllianceGiftMediator.Sorter)
    for _, v in ipairs(self._tabData) do
        self._p_table:AppendData(v)
    end
    self._p_empty:SetVisible(#self._tabData <= 0)
end

function AllianceGiftMediator:OnClickClaimAll()
    if self:IsPlayingEffect() then return end
    if self._tab ~= AllianceGiftType.Normal then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for i, v in ipairs(self._tabData) do
        if not v.serverData.IsGet and v.serverData.ExpirationTime.ServerSecond > nowTime  then
            ModuleRefer.AllianceModule:GetBatchAllianceNormalGiftReward(self._p_comp_btn_b_l.transform, function(cmd, isSuccess, rsp)
                if isSuccess and rsp and not table.isNilOrZeroNums(rsp.Reward) then
					g_Game.SoundManager:Play("sfx_se_world_alliancegift_key")
                    ---@type UIRewardMediatorParameter
                    local data = {}
                    data.itemInfo = {}
                    data.itemProfiteType = wds.enum.ItemProfitType.ItemAddByOpenBox
                    for itemId, count in pairs(rsp.Reward) do
                        ---@type UIRewardMediatorItemData
                        local cell = {}
                        cell.id = itemId
                        cell.count = count
                        table.insert(data.itemInfo, cell)
                    end
                    ModuleRefer.RewardModule:ShowDefaultReward(data)
                end
                self._triggerFetchData = true
            end)
            return
        end
    end
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_gift_nonegift"))
end

function AllianceGiftMediator:OnClickDelete()
    if self:IsPlayingEffect() then return end
    local doDelete = function()
        ModuleRefer.AllianceModule:ClearHaveGetGifts(self._p_btn_delete.transform, function(cmd, isSuccess, rsp)
            if isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_gift_recordcleared"))
                self._triggerFetchData = true
            end
        end)
    end
    
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for i, v in ipairs(self._tabData) do
        if v.serverData.IsGet or v.serverData.ExpirationTime.ServerSecond < nowTime  then
            if self._tab == AllianceGiftType.Normal then
                ---@type CommonConfirmPopupMediatorParameter
                local confirmParameter = {}
                confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.WarningAndCancel
                confirmParameter.content = I18N.Get("alliance_gift_recordclear_makesure")
                confirmParameter.confirmLabel = I18N.Get("confirm")
                confirmParameter.cancelLabel = I18N.Get("cancle")
                confirmParameter.onConfirm = function()
                    doDelete()
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
                return
            elseif self._tab == AllianceGiftType.Specail then
                doDelete()
            end
        end
    end
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_gift_nonegift"))
end

function AllianceGiftMediator:OnClickUpgrade()
    self._p_upgrade:SetVisible(false)
end

function AllianceGiftMediator:OnLeaveAlliance()
    self._allianceId = nil
    self:CloseSelf()
end

function AllianceGiftMediator:LocalSetCellIsGet(giftId)
    local cellSrcData = self._serverData[giftId]
    if not cellSrcData then
        return
    end
    AllianceGiftMediator.NowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for i = 1, #self._tabData do
        local cellData = self._tabData[i]
        if cellData.serverData.GiftID == giftId then
            table.remove(self._tabData, i)
            self._p_table:RemData(cellData)
            cellData.serverData.IsGet = true
            local insertIndex = #self._tabData + 1
            for j = #self._tabData, 1, -1 do
                local current = self._tabData[j]
                if AllianceGiftMediator.Sorter(cellData, current) then
                    insertIndex = j
                else
                    insertIndex = j + 1
                    break
                end
            end
            table.insert(self._tabData, insertIndex ,cellData)
            self._p_table:AppendData(cellData)
            self:UpdateTabNotify()
            return
        end
    end
end

function AllianceGiftMediator:TickSec(dt)
    if self._delayShowReward then
        self._delayShowReward = self._delayShowReward - dt
        if self._delayShowReward <= 0 then
            self._delayShowReward = nil
            for _, value in ipairs(self._delayShowRewardQueue) do
                value()
            end
        end
    end
    if self._triggerFetchData then
        self._triggerFetchData = false
        self:FetchData()
    end
    if not self._nextTime then
        return
    end
    if self._nextTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        return
    end
    self:UpdateTabNotify()
end

function AllianceGiftMediator:UpdateTabNotify()
    local countNormal = 0
    local countSpecial = 0
    self._nextTime = nil
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for _, v in pairs(self._serverData) do
        if not v.IsGet and v.ExpirationTime.ServerSecond > nowTime then
            if v.Typo == AllianceGiftType.Normal then
                countNormal = countNormal + 1
                if not self._nextTime or self._nextTime > v.ExpirationTime.ServerSecond then
                    self._nextTime = v.ExpirationTime.ServerSecond
                end
            elseif v.Typo == AllianceGiftType.Specail then
                countSpecial = countSpecial + 1
                if not self._nextTime or self._nextTime > v.ExpirationTime.ServerSecond then
                    self._nextTime = v.ExpirationTime.ServerSecond
                end
            end
        end
    end
    if countNormal > 0 then
        self._child_reddot_default_a.go:SetVisible(true)
        self._child_reddot_default_a:ShowNumRedDot(countNormal)
    else
        self._child_reddot_default_a.go:SetVisible(false)
    end
    if countSpecial > 0 then
        self._child_reddot_default_b.go:SetVisible(true)
        self._child_reddot_default_b:ShowNumRedDot(countSpecial)
    else
        self._child_reddot_default_b.go:SetVisible(false)
    end
end

function AllianceGiftMediator:IsPlayingEffect()
    return nil ~= self._delayShowReward
end

function AllianceGiftMediator:CheckClickClose()
    if self:IsPlayingEffect() then return end
    self:BackToPrevious()
end

return AllianceGiftMediator
