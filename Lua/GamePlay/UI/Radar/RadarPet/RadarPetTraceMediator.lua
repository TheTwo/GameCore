local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetSkillType = require("PetSkillType")
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local TimerUtility = require('TimerUtility')
local PetQuality = require('PetQuality')
local UIHelper = require('UIHelper')

---@class RadarPetTraceMediator : BaseUIMediator
local RadarPetTraceMediator = class('RadarPetTraceMediator', BaseUIMediator)
function RadarPetTraceMediator:ctor()
    self._rewardList = {}
end

function RadarPetTraceMediator:OnCreate()
    ---@type RadarFourPetComp
    self.p_table_pet = self:TableViewPro('p_table_pet')
    self.p_btn_change = self:Button('p_btn_change', Delegate.GetOrCreate(self, self.OnBtnChangeClick))
    self.p_btn_close_tip = self:Button('p_btn_close_tip', Delegate.GetOrCreate(self, self.OnBtnChangeClick))
    self.child_comp_btn_b_l = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.OnBtnTraceClick))
    self.p_text = self:Text('p_text', "radartrack_info_to_track")
    self.p_text_content = self:Text('p_text_content')
    self.p_text_tracking = self:Text('p_text_tracking')
    self.p_btn_detail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetail))
    self.p_text_title = self:Text('p_text_title')
    self.p_tip_pet = self:GameObject('p_tip_pet')
    self.p_group_arrow = self:GameObject('p_group_arrow')
    self.p_text_hint = self:Text('p_text_hint', 'build_newitem')
    self.p_text_pet = self:Text('p_text_pet')
    self.p_hint = self:GameObject('p_hint')
    self.child_btn_close = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClick))
    self.child_comp_btn_detail = self:Button('child_comp_btn_detail')
    ---@type RadarPetModelComp
    self.p_pet_1 = self:LuaObject('p_pet_1')
    self.p_pet_2 = self:LuaObject('p_pet_2')
    self.p_pet_3 = self:LuaObject('p_pet_3')
    self.p_pets = {self.p_pet_1, self.p_pet_2, self.p_pet_3}

    self.petListVfx = self:BindComponent("p_tip_pet", typeof(CS.FpAnimation.FpAnimationCommonTrigger))
end

function RadarPetTraceMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.RADAR_TRACE_PET_SWAP, Delegate.GetOrCreate(self, self.TempSwapPet))

end

function RadarPetTraceMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.RADAR_TRACE_PET_SWAP, Delegate.GetOrCreate(self, self.TempSwapPet))
end

function RadarPetTraceMediator:OnOpened(param)
    local status = ModuleRefer.RadarModule:GetRadarPetTraceState()
    self.isTracing = status ~= 2
    self:InitContent()
    self:RefreshContent()
    self:InitButton()

    if param and param.tracePetId then
        self:OnBtnChangeClick()
        local index = self:GetIndexByID(param.tracePetId)
        if index == nil then
            g_Logger.Error("雷达中不存在 petTypeId = " .. param.tracePetId .. " 的宠物")
            return
        end
        self:OnPetSelected({cfgId = param.tracePetId, index = index})
    end
end

function RadarPetTraceMediator:OnClose()
    self.selected = nil
    ModuleRefer.RadarModule:SetRadarTraceSelectPet(self.selected)
    ModuleRefer.RadarModule:SetTempRadarTracingPets({})
end

function RadarPetTraceMediator:InitContent()
    self.p_btn_close_tip:SetVisible(false)
    local curT, maxT = ModuleRefer.RadarModule:GetRadarTrackingPetTimes()
    self.curT = curT
    self.isChangePet = false
    self.tracingPets = ModuleRefer.RadarModule:GetRadarTracingPets()
    ModuleRefer.RadarModule:SetTempRadarTracingPets(self.tracingPets)
    self.petsData = ModuleRefer.RadarModule:GetRadarTracePets()

    if self.isTracing then
        self.p_text_title.text = I18N.Get("radartrack_info_being_tracked")
        self.p_text_content.text = I18N.Get("radartrack_info_track_condition")
        self.p_text_pet.text = I18N.Get('radartrack_info_cannot_be_replaced')
        local cur, max = ModuleRefer.RadarModule:GetRadarPetTrackingProgress()
        self.p_text_tracking:SetVisible(false)
        -- 已追踪到
        -- if max == 0 then
        --     self.p_text_tracking.text = I18N.GetWithParams("")
        -- else
        --     self.p_text_tracking.text = I18N.GetWithParams("radartrack_info_progress", cur .. "/" .. max)
        -- end
    else
        self.p_text_title.text = I18N.Get("radartrack_info_will_be_tracked")
        self.p_text_pet.text = I18N.Get('radartrack_info_select_and_deselect')
        local protectT = ConfigRefer.RadarConst:PetTrackNotPerfectMaxTimes()
        local totalT, notPerfectT = ModuleRefer.RadarModule:GetRadarTrackingPetTotalTimes()
        local remainT = protectT - notPerfectT
        self.p_text_content.text = I18N.GetWithParams("radartrack_info_random", protectT, remainT)
        self.p_text_tracking.text = I18N.GetWithParams("radartrack_info_tracking_times", curT .. "/" .. maxT)
        self.p_text_tracking:SetVisible(true)
    end
    self:CheckNewPet()
end

function RadarPetTraceMediator:RefreshContent()
    table.sort(self.petsData, RadarPetTraceMediator.SortPetDataByRarity)

    self.selectedNum = 0
    self.p_table_pet:Clear()
    self.swapData = {}
    local counter = 0
    local tableIndex = 1
    local threePetsData = {}
    for k, v in pairs(self.petsData) do
        if counter == 4 then
            ---@type RadarFourPetComp
            self.p_table_pet:AppendData(threePetsData)
            table.insert(self.swapData, threePetsData)
            counter = 0
            threePetsData = {}
            tableIndex = tableIndex + 1
        end

        ---@type RadarPetModelComp
        local data = {}
        data.cfgId = v.cfgId
        data.isLock = v.isLock
        data.lockLand = v.lockLand
        data.lockCastleLevel = v.lockCastleLevel
        data.isUnknown = v.isUnknown
        data.unOwn = v.unOwn
        data.onClick = Delegate.GetOrCreate(self, self.OnPetSelected)
        data.index = tableIndex
        data.selected = false
        data.manualLock = true
        local isTracing = false
        for k2, v2 in pairs(self.tracingPets) do
            if v2 == v.cfgId then
                isTracing = true
                break
            end
        end
        data.isTracing = isTracing
        data.isCheck = isTracing
        data.showMask = isTracing
        table.insert(threePetsData, data)
        counter = counter + 1
    end

    if #threePetsData > 0 then
        self.p_table_pet:AppendData(threePetsData)
        table.insert(self.swapData, threePetsData)
    end
    self:RefreshTracingPet()
end

function RadarPetTraceMediator:OnPetSelected(data, trans)
    if self.selected ~= data.cfgId then
        self.selected = data.cfgId
        ModuleRefer.RadarModule:SetRadarTraceSelectPet(self.selected)
        for i = 1, self.p_table_pet.DataCount do
            local cell = self.p_table_pet:GetCell(i - 1)
            if cell then
                local lua = cell.Lua
                if lua and lua.__cname == "RadarFourPetComp" then
                    lua:RefreshSelect(data.cfgId)
                end
            end
        end
    end

    -- 宠物详情
    local detailIndex = data.index + 1
    local areaIndex = data.index + 2
    local castleIndex = data.index + 3

    if self.showCastle then
        self.p_table_pet:RemAt(self.lastCastleIndex - 1)
        self.showCastle = false
    end

    if self.showArea then
        self.p_table_pet:RemAt(self.lastAreaIndex - 1)
        self.showArea = false
    end

    if self.showDetail then
        self.p_table_pet:RemAt(self.lastDetailIndex - 1)
        self.showDetail = false
    end

    -- 被锁宠物无详情信息
    if not data.isLock then
        local detailData = {cfgId = data.cfgId}
        if detailIndex > self.p_table_pet.DataCount then
            self.p_table_pet:AppendData(detailData, 1)
            self.showDetail = true
        else
            if not self.showDetail then
                self.showDetail = true
                self.p_table_pet:InsertData(detailIndex - 1, detailData, 1)
            end
        end
    else
        areaIndex = areaIndex - 1
        castleIndex = castleIndex - 1
    end

    -- 宠物前往圈层
    if data.lockLand then
        local areaData = {cfgId = data.cfgId}
        if areaIndex > self.p_table_pet.DataCount then
            self.p_table_pet:AppendData(areaData, 2)
            self.showArea = true
        else
            if not self.showArea then
                self.showArea = true
                self.p_table_pet:InsertData(areaIndex - 1, areaData, 2)
            else
                self.p_table_pet:InsertData(areaIndex, areaData, 2)
            end
        end
    else
        castleIndex = castleIndex - 1
    end

    -- 主堡等级不足
    if data.lockCastleLevel then
        local areaData = {cfgId = data.cfgId, lockCastleLevel = true}
        if castleIndex > self.p_table_pet.DataCount then
            self.p_table_pet:AppendData(areaData, 2)
            self.showCastle = true
        else
            if not self.showCastle then
                self.showCastle = true
                self.p_table_pet:InsertData(castleIndex - 1, areaData, 2)
            end
        end
    end

    self.lastDetailIndex = detailIndex
    self.lastAreaIndex = areaIndex
    self.lastCastleIndex = castleIndex

    -- 宠物上下阵
    if not self.isTracing then
        if data.isCheck then
            if self:CheckCanUnselect() then
                self:ShowHideSwapMode(false)
                self:TempUnselectPet(data.cfgId, data.index)
                self:RefreshTracingPet()
                self:ShowHideSwapMode(false)
            end
        elseif not data.isLock then
            if self:CheckCanSelect() then
                self:TempSelectPet(data.cfgId, data.index)
                self:RefreshTracingPet()
            else
                -- Swap
                self:ShowHideSwapMode(true, data.cfgId, data.index)
            end
        else
            self:ShowHideSwapMode(false)
        end
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("radartrack_info_cannot_be_replaced"))
    end
end

function RadarPetTraceMediator.SortPetDataByRarity(a, b)
    if (a.isUnknown ~= b.isUnknown) then
        return b.isUnknown
    elseif (a.lockLand ~= b.lockLand) then
        return b.lockLand
    elseif (a.rarity ~= b.rarity) then
        return a.rarity < b.rarity
        -- elseif (a.lockCastleLevel ~= b.lockCastleLevel) then
        --     return b.lockCastleLevel
    else
        return a.cfgId < b.cfgId
    end
end

function RadarPetTraceMediator:InitButton()
    self.p_tip_pet:SetVisible(false)

    if self.isTracing then
        self.child_comp_btn_b_l:SetVisible(false)
    else
        if self.curT == 0 then
            self.child_comp_btn_b_l:SetVisible(false)
        else
            self.child_comp_btn_b_l:SetVisible(true)

        end
    end
end

function RadarPetTraceMediator:OnBtnChangeClick()
    self.isChangePet = not self.isChangePet
    self.p_tip_pet:SetVisible(self.isChangePet)
    self.p_btn_close_tip:SetVisible(self.isChangePet)

    if self.isChangePet == false then
        self.petListVfx:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        self:ShowHideSwapMode(false)
    else
        self:SetNewPet()
    end
end
function RadarPetTraceMediator:OnBtnTraceClick()
    -- 上锁\标记将要出现的任务
    ModuleRefer.RadarModule:SetManualRadarTaskLock(true)
    local req = require('RadarPetTrackRefreshParameter').new()
    req:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then
            self:CloseSelf()
            g_Game.EventManager:TriggerEvent(EventConst.RADAR_TRACE_PET_START_TRACE)
        else
            ModuleRefer.RadarModule:SetManualRadarTaskLock(false)
        end
    end)
end
function RadarPetTraceMediator:OnBtnDetail()
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform = self.p_btn_detail.transform
    toastParameter.content = I18N.Get("radartrack_tips_tutorial")
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end
function RadarPetTraceMediator:OnBtnCloseClick()
    self:CloseSelf()
end

function RadarPetTraceMediator:CheckCanSelect()
    return #self.tracingPets < 3
end

function RadarPetTraceMediator:CheckCanUnselect()
    return #self.tracingPets > 0
end

function RadarPetTraceMediator:ShowHideSwapMode(isShow, swapId, swapIndex)
    self.isSwapMode = isShow
    self.p_group_arrow:SetVisible(isShow)
    self.swapId = swapId
    self.swapIndex = swapIndex
end

function RadarPetTraceMediator:TempSwapPet(unselectId)
    if not self.isSwapMode then
        return
    end

    local unselectIndex = self:GetIndexByID(unselectId)
    local pos = self:TempUnselectPet(unselectId, unselectIndex)
    self:TempSelectPet(self.swapId, self.swapIndex, pos)
    self:RefreshTracingPet()
    self:ShowHideSwapMode(false)
end

function RadarPetTraceMediator:GetIndexByID(petCfgId)
    for k, v in pairs(self.swapData) do
        for k2, v2 in pairs(v) do
            if v2.cfgId == petCfgId then
                return v2.index
            end
        end
    end
end

function RadarPetTraceMediator:TempSelectPet(petCfgId, index, pos)
    if pos then
        table.insert(self.tracingPets, pos, petCfgId)
    else
        table.insert(self.tracingPets, petCfgId)
    end
    ModuleRefer.RadarModule:SetTempRadarTracingPets(self.tracingPets)
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TRACE_PET_CHANGE, index)

    if #self.tracingPets == 3 then
        self:SaveTracingPet()
    end
end

function RadarPetTraceMediator:TempUnselectPet(petCfgId, index)
    local pos
    for k, v in pairs(self.tracingPets) do
        if v == petCfgId then
            pos = k
            break
        end
    end
    if pos then
        table.remove(self.tracingPets, pos)
    end
    ModuleRefer.RadarModule:SetTempRadarTracingPets(self.tracingPets)
    g_Game.EventManager:TriggerEvent(EventConst.RADAR_TRACE_PET_CHANGE, index)
    return pos
end

function RadarPetTraceMediator:SaveTracingPet()
    local req = require('RadarPetTrackSetParameter').new()
    req.args.Info.PetIds:AddRange(self.tracingPets)
    req:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then
            -- self:RefreshContent()
        end
    end)
end

function RadarPetTraceMediator:RefreshTracingPet()
    for i = 1, 3 do
        if i <= #self.tracingPets then
            self.p_pets[i]:FeedData({cfgId = self.tracingPets[i]})
        else
            self.p_pets[i]:FeedData({cfgId = nil})
        end
    end

    if #self.tracingPets < 3 then
        UIHelper.SetGray(self.child_comp_btn_b_l.gameObject, true)
        self.child_comp_btn_b_l.interactable = false
    else
        UIHelper.SetGray(self.child_comp_btn_b_l.gameObject, false)
        self.child_comp_btn_b_l.interactable = true
    end
end

function RadarPetTraceMediator:CheckNewPet()
    local node = ModuleRefer.RadarModule:GetPetTraceReddot()
    self.p_hint:SetVisible(node.NotificationCount > 0)
end

function RadarPetTraceMediator:SetNewPet()
    local node = ModuleRefer.RadarModule:GetPetTraceReddot()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(node, 0)
    self:CheckNewPet()
end

return RadarPetTraceMediator
