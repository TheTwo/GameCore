local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local TimeFormatter = require('TimeFormatter')
local I18N = require("I18N")
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local CatchPetHelper = require('CatchPetHelper')
local EventConst = require('EventConst')

local AutoCatchPetParameter = require('AutoCatchPetParameter')
local CancelAutoCatchPetParameter = require('CancelAutoCatchPetParameter')
local OpenPetBallParameter = require('OpenPetBallParameter')

local BALL_MAX = 10
local CATCH_TIME_BY_LEVEL = 60      -- 秒
local BALL_MIN = 2

---UI状态，对应StatusRecordParent中存储的0~3
---@class UIState
local UIState = {
    IDLE_NOT_READY = 0,
    IDLE_CAN_SEND = 1,
    WORKING = 2,
    FINISHED = 3,
}

---@class CityLegoBuildingUIPage_CatchPet:BaseUIComponent
local CityLegoBuildingUIPage_CatchPet = class('CityLegoBuildingUIPage_CatchPet', BaseUIComponent)

function CityLegoBuildingUIPage_CatchPet:ctor()
    self.selectLandCfgId = 0
    ---@type table<number, number> @key: itemId, value: itemCount
    self.selectItems = {}
end

function CityLegoBuildingUIPage_CatchPet:OnCreate()
    ---@type CS.StatusRecordParent
	self.statusControl = self:BindComponent("", typeof(CS.StatusRecordParent))

    self.tableLandform = self:TableViewPro('p_table_landform')
    self.txtLandformName = self:Text('p_text_select_landform')
    self.btnLandformDetail = self:Button('p_btn_detail_landform', Delegate.GetOrCreate(self, self.OnLandformDetailClick))

    self.txtAllPets = self:Text('p_text_pet', 'pet_drone_available_pets_name')
    self.tablePet = self:TableViewPro('p_table_pet')

    self.txtPetBallSelect = self:Text('p_text_ball_select')
    self.txtPetBallDailyLeft = self:Text('p_text_ball_daily_left')
    self.tableBallItems = self:TableViewPro('p_table_item')
    self.btnQuickSelect = self:Button('p_btn_select_qiuck', Delegate.GetOrCreate(self, self.OnQuickSelectClick))
    self.txtQuickSelect = self:Text('p_text_select_qiuck', 'pet_drone_quick_select_name')

    self.txtWorkTime = self:Text('p_text_time')
    self.slideWork = self:Slider('p_progress')

    self.btnRecall = self:Button('p_btn_recall', Delegate.GetOrCreate(self, self.OnRecallClick))
    self.txtRecall = self:Text('p_text_recall', 'pet_drone_recall_name')

    self.txtSendFinish = self:Text('p_text_ok', 'pet_drone_complete_name')

    self.btnOpen = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnOpenClick))
    self.txtOpen = self:Text('p_text_open', 'treasure_option')

    self.btnSend = self:Button('p_btn_send', Delegate.GetOrCreate(self, self.OnSendClick))
    self.txtSend = self:Text('p_text_send', 'pet_drone_assign_name')
    self.txtSendTimePreview = self:Text('p_text_num_wilth_bl')
    self.imgTimeIcon = self:Image('p_icon_time')

    self.btnSendDisable = self:Button('p_btn_d', Delegate.GetOrCreate(self, self.OnSendDisableClick))
    self.txtSendDisable = self:Text('p_text_d_s', 'pet_drone_assign_name')
end

function CityLegoBuildingUIPage_CatchPet:OnShow(param)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTicker))
end

function CityLegoBuildingUIPage_CatchPet:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameTicker))
end

---@param param CityFurnitureCatchPetUIParameter
function CityLegoBuildingUIPage_CatchPet:OnFeedData(param)
    self.param = param

    local furnitureLevel = param.furnitureLevel
    BALL_MAX = ConfigRefer.PetConsts:CatchPetItemMax(furnitureLevel) or 10
    BALL_MIN = ConfigRefer.PetConsts:CatchPetItemMin()
    CATCH_TIME_BY_LEVEL = ConfigRefer.PetConsts:CatchPetTime(furnitureLevel) or 60

    self:RefreshUI()
end

function CityLegoBuildingUIPage_CatchPet:OnClose()
    self:OnHide()
end

function CityLegoBuildingUIPage_CatchPet:OnFrameTicker(delta)
    if not self.param then return end
    -- 状态切换刷新UI
    local uiState = self:GetCurrentState()
    if uiState ~= self.uiState then
        self:RefreshUI()
    end

    if self.uiState == UIState.WORKING then
        self:RefreshSlider()
    end
end

---@return wds.CastleFurniture
function CityLegoBuildingUIPage_CatchPet:GetFurnitureData()
    return self.param.cellTile:GetCastleFurniture()
end

---@return UIState
function CityLegoBuildingUIPage_CatchPet:GetCurrentState()
    if self:GetFurnitureData() == nil then
        g_Logger.Error('状态调用时机错误')
        return UIState.IDLE_NOT_READY
    end

    local furnitureData = self:GetFurnitureData()
    -- 空闲状态
    if furnitureData.CastleCatchPetInfo == nil or furnitureData.CastleCatchPetInfo.Status == wds.AutoCatchPetStatus.AutoCatchPetStatusIdle then
        if self:GetCurrentSelectTotal() >= BALL_MIN then
            return UIState.IDLE_CAN_SEND
        end

        return UIState.IDLE_NOT_READY
    end

    -- 工作状态
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    if now >= furnitureData.CastleCatchPetInfo.StartTime.Seconds and now < furnitureData.CastleCatchPetInfo.FinishTime.Seconds then
        return UIState.WORKING
    end

    return UIState.FINISHED
end

---@param uiState UIState
function CityLegoBuildingUIPage_CatchPet:UpdatePetCatchItems(uiState)
    if uiState == UIState.IDLE_NOT_READY or uiState == UIState.IDLE_CAN_SEND then
        if table.isNilOrZeroNums(self.selectItems) then
            local petCatchItemList = ModuleRefer.PetModule:GetPetCatchItemCfgList()
            for _, petCatchItemCfgCell in pairs(petCatchItemList) do
                local itemCfgId = petCatchItemCfgCell:ItemCfg()
                self.selectItems[itemCfgId] = 0
            end
        end
    else
        table.clear(self.selectItems)
        local furnitureData = self:GetFurnitureData()
        for i = 1, furnitureData.CastleCatchPetInfo.CatchItems:Count() do
            local costItem = furnitureData.CastleCatchPetInfo.CatchItems[i]
            self.selectItems[costItem.ConfigId] = costItem.Count
        end
    end
end

function CityLegoBuildingUIPage_CatchPet:GetCurrentSelectTotal()
    local total = 0
    for _, count in pairs(self.selectItems) do
        if count > 0 then
            total = total + count
        end
    end

    return total
end

---@return number @秒
function CityLegoBuildingUIPage_CatchPet:GetSendTimeCost()
    return self:GetCurrentSelectTotal() * CATCH_TIME_BY_LEVEL
end

function CityLegoBuildingUIPage_CatchPet:GetDailyLeftPetCount()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local dailyGet = player.PlayerWrapper2.PlayerPet.DailyGetPetCount
    local dailyTotal = ConfigRefer.PetConsts:CatchPetCountLimit()
    local left = dailyTotal - dailyGet
    left = math.max(0, left)
    return left
end

---@param forceRefreshLandform boolean
function CityLegoBuildingUIPage_CatchPet:RefreshUI(forceRefreshLandform)
    -- 时间变化或操作变化都会刷新状态，所以此时再判断一次
    self.uiState = self:GetCurrentState()
    self.statusControl:ApplyStatusRecord(self.uiState)
    self:UpdatePetCatchItems(self.uiState)

    self.txtPetBallDailyLeft.text = string.format('%s: %s', I18N.Get('pet_drone_daily_rest_num_name'), self:GetDailyLeftPetCount())

    if self.uiState == UIState.IDLE_NOT_READY or self.uiState == UIState.IDLE_CAN_SEND then
        -- idle状态

        -- 圈层选择
        if forceRefreshLandform or self.selectLandCfgId == nil or self.selectLandCfgId == 0 then
            self.tableLandform:Clear()
            for _, cell in ConfigRefer.Land:ipairs() do
                local landCfgId = cell:Id()
                if not ModuleRefer.LandformModule:IsLandformUnlockByCfgId(landCfgId) then
                    goto continue
                end
        
                -- 默认选中第一个解锁的圈层
                if self.selectLandCfgId == nil or self.selectLandCfgId == 0 then
                    self.selectLandCfgId = cell:Id()
                end
        
                ---@type CatchPetLandformMiniIconCellData
                local cellData = {}
                cellData.landCfgCell = cell
                cellData.selectLandCfgId = self.selectLandCfgId
                cellData.onClick = Delegate.GetOrCreate(self, self.OnLandformMiniIconClick)
                self.tableLandform:AppendData(cellData)
        
                ::continue::
            end
        end
    
        -- 圈层信息
        local landCfgCell = ConfigRefer.Land:Find(self.selectLandCfgId)
        self.txtLandformName.text = I18N.Get(landCfgCell:Name())
    
        self.tablePet:Clear()
        local petCount = landCfgCell:UnlockPetLength()
        local petVillageCount = landCfgCell:UnlockPetVillageLength()
        for i = 1, petVillageCount do
            local unlockPet = landCfgCell:UnlockPetVillage(i)
            ---@type LandformImageCellData
            local petCellData = {}
            petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
            petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
            petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
            petCellData.isVillagePet = true
            self.tablePet:AppendData(petCellData)
        end
        for i = 1, petCount do
            local unlockPet = landCfgCell:UnlockPet(i)
            ---@type LandformImageCellData
            local petCellData = {}
            petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
            petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
            petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
            self.tablePet:AppendData(petCellData)
        end
    
        -- 抓宠道具选择
        self.tableBallItems:Clear()
        local petCatchItemList = ModuleRefer.PetModule:GetPetCatchItemCfgList()
        for _, petCatchItemCfgCell in pairs(petCatchItemList) do
            local itemCfgId = petCatchItemCfgCell:ItemCfg()
            local count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfgId)
            local selectCount = self.selectItems[itemCfgId]
    
            ---@type ItemIconData
            local itemIconData = {}
            itemIconData.configCell = ConfigRefer.Item:Find(itemCfgId)
            itemIconData.count = count
            itemIconData.addCount = selectCount
            itemIconData.useNoneMask = count <= 0
            itemIconData.onClick = Delegate.GetOrCreate(self, self.OnItemClick)
            itemIconData.onDelBtnClick = Delegate.GetOrCreate(self, self.OnItemDelBtnClick)
            self.tableBallItems:AppendData(itemIconData)
        end

        self.txtPetBallSelect.text = string.format('%s: %s/%s', I18N.Get('gacha_select_already'), self:GetCurrentSelectTotal(), BALL_MAX)

        self.txtSendTimePreview:SetVisible(self.uiState == UIState.IDLE_CAN_SEND)
        self.imgTimeIcon:SetVisible(self.uiState == UIState.IDLE_CAN_SEND)
        if self.uiState == UIState.IDLE_CAN_SEND then
            self.txtSendTimePreview.text = TimeFormatter.SimpleFormatTime(self:GetSendTimeCost())
            g_Game.SpriteManager:LoadSprite('sp_common_icon_time_01', self.imgTimeIcon)
        end
    elseif self.uiState == UIState.WORKING or self.uiState == UIState.FINISHED then
        -- 派遣中或派遣完成

        -- 圈层信息（不可选择）
        local furnitureData = self:GetFurnitureData()
        local petAreaCfgCell = ConfigRefer.PetArea:Find(furnitureData.CastleCatchPetInfo.PetAreaId)
        self.selectLandCfgId = petAreaCfgCell:LandId()
        local landCfgCell = ConfigRefer.Land:Find(self.selectLandCfgId)
        self.txtLandformName.text = I18N.Get(landCfgCell:Name())
    
        self.tablePet:Clear()
        local petCount = landCfgCell:UnlockPetLength()
        local petVillageCount = landCfgCell:UnlockPetVillageLength()
        for i = 1, petVillageCount do
            local unlockPet = landCfgCell:UnlockPetVillage(i)
            ---@type LandformImageCellData
            local petCellData = {}
            petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
            petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
            petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
            petCellData.isVillagePet = true
            self.tablePet:AppendData(petCellData)
        end
        for i = 1, petCount do
            local unlockPet = landCfgCell:UnlockPet(i)
            ---@type LandformImageCellData
            local petCellData = {}
            petCellData.iconId = ModuleRefer.LandformModule:GetMiniIconFromPetCfgId(unlockPet)
            petCellData.nameKey = ModuleRefer.LandformModule:GetNameFromPetCfgId(unlockPet)
            petCellData.descKey = ModuleRefer.LandformModule:GetDescFromPetCfgId(unlockPet)
            self.tablePet:AppendData(petCellData)
        end

        -- 抓宠道具（不可选择）
        self.tableBallItems:Clear()
        for itemCfgId, itemCount in pairs(self.selectItems) do
            ---@type ItemIconData
            local itemIconData = {}
            itemIconData.configCell = ConfigRefer.Item:Find(itemCfgId)
            itemIconData.count = itemCount
            self.tableBallItems:AppendData(itemIconData)
        end

        if self.uiState == UIState.WORKING then
            self.txtPetBallSelect.text = string.format('%s :%s', I18N.Get('pet_drone_carried_bubbles_name'), self:GetCurrentSelectTotal())
        elseif self.uiState == UIState.FINISHED then
            self.txtPetBallSelect.text = string.format('%s :%s', I18N.Get('pet_drone_completed_bubbles_name'), self:GetCurrentSelectTotal())
        end
    end
end

function CityLegoBuildingUIPage_CatchPet:RefreshSlider()
    local furnitureData = self:GetFurnitureData()
    if furnitureData == nil or furnitureData.CastleCatchPetInfo == nil then
        return
    end

    local progress, leftSeconds = CatchPetHelper.GetAutoPetCatchWorkInfo(furnitureData)
    self.txtWorkTime.text = string.format('%s: %s', I18N.Get('pet_drone_assigning_name'), TimeFormatter.SimpleFormatTime(leftSeconds))
    self.slideWork.value = progress
end

---@param itemCfgCell ItemConfigCell
function CityLegoBuildingUIPage_CatchPet:OnItemClick(itemCfgCell)
    local selectItemId = itemCfgCell:Id()
    local itemHave = ModuleRefer.InventoryModule:GetAmountByConfigId(selectItemId) or 0

    if itemHave == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_catch_item_lack_tips'))
        return
    end

    local itemSelect = self.selectItems[selectItemId] or 0
    -- 超过当前拥有上限
    if itemSelect >= itemHave then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_drone_all_selected_name'))
        return
    end

    -- 超过当日上限
    local dailyLeft = self:GetDailyLeftPetCount()
    if self:GetCurrentSelectTotal() >= dailyLeft then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_drone_daily_total_upperbound_des'))
        return
    end

    -- 超过携带上限
    if self:GetCurrentSelectTotal() >= BALL_MAX then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_drone_bubbles_upperbound_des'))
        return
    end

    itemSelect = itemSelect + 1
    self.selectItems[selectItemId] = itemSelect
    self:RefreshUI()
end

---@param itemCfgCell ItemConfigCell
function CityLegoBuildingUIPage_CatchPet:OnItemDelBtnClick(itemCfgCell)
    local selectItemId = itemCfgCell:Id()
    local itemSelect = self.selectItems[selectItemId]
    if itemSelect == 0 then
        return
    end

    itemSelect = itemSelect - 1
    self.selectItems[selectItemId] = itemSelect
    self:RefreshUI()
end

---@param landCfgCell LandConfigCell
function CityLegoBuildingUIPage_CatchPet:OnLandformMiniIconClick(landCfgCell)
    if self.selectLandCfgId ~= landCfgCell:Id() then
        self.selectLandCfgId = landCfgCell:Id()
        self:RefreshUI(true)
    end
end

function CityLegoBuildingUIPage_CatchPet:OnLandformDetailClick()
    ---@type CatchPetLandformTipParameter
    local param = {}
    param.landCfgId = self.selectLandCfgId
    g_Game.UIManager:Open(UIMediatorNames.CatchPetLandformTip, param)
end

function CityLegoBuildingUIPage_CatchPet:OnQuickSelectClick()
    local dailyLeft = self:GetDailyLeftPetCount()
    if dailyLeft <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_drone_daily_total_upperbound_des'))
        return
    end

    local petCatchItemList = ModuleRefer.PetModule:GetPetCatchItemCfgList()
    local tmp = {}
    table.clear(self.selectItems)
    for _, petCatchItemCfgCell in pairs(petCatchItemList) do
        local itemCfgId = petCatchItemCfgCell:ItemCfg()
        tmp[itemCfgId] = petCatchItemCfgCell:LuckPoint()
        self.selectItems[itemCfgId] = 0
    end
    tmp = table.mapToList(tmp)

    -- 降序排列，幸运分高的优先
    table.sort(tmp, function(a, b) return a.value > b.value end)

    -- 高品质优先，直至选择到道具用完
    local totalCount = 0
    local left = BALL_MAX
    for _, pair in pairs(tmp) do
        local itemCfgId = pair.key
        local itemHave = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfgId)
        totalCount = totalCount + itemHave
        if itemHave == 0 then
            goto continue
        end

        if itemHave >= left then
            self.selectItems[itemCfgId] = left
            break
        end

        self.selectItems[itemCfgId] = itemHave
        left = left - itemHave

        ::continue::
    end

    if totalCount == 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_catch_item_lack_tips'))
        return
    end

    self:RefreshUI()
end

function CityLegoBuildingUIPage_CatchPet:OnRecallClick()
    ---@type CommonConfirmPopupMediatorParameter
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("equip_warning")
    dialogParam.content = I18N.Get("pet_drone_is_recall_des")
    dialogParam.onConfirm = Delegate.GetOrCreate(self, self.OnRecallConfirmClick)
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end

---@return boolean
function CityLegoBuildingUIPage_CatchPet:OnRecallConfirmClick()
    local req = CancelAutoCatchPetParameter.new()
    req.args.FurnitureId = self.param.furnitureId
    req:SendOnceCallback(nil, nil, nil, Delegate.GetOrCreate(self, self.OnRecallCallback))
    return true
end

---@param cmd CancelAutoCatchPetParameter
---@param isSuccess boolean
---@param rsp wrpc.CancelAutoCatchPetReply
function CityLegoBuildingUIPage_CatchPet:OnRecallCallback(cmd, isSuccess, rsp)
    if not isSuccess then
        return
    end 

    self:RefreshUI()

    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_drone_recall_tip_des'))
    g_Game.EventManager:TriggerEvent(EventConst.AUTO_PET_CATCH_STATE_CHANGED, self.param.furnitureId)
end

function CityLegoBuildingUIPage_CatchPet:OnOpenClick()
    local req = OpenPetBallParameter.new()
    req.args.FurnitureId = self.param.furnitureId
    req:SendOnceCallback(nil, nil, nil, Delegate.GetOrCreate(self, self.OnOpenCallback))
end

---@param cmd OpenPetBallParameter
---@param isSuccess boolean
---@param rsp wrpc.OpenPetBallReply
function CityLegoBuildingUIPage_CatchPet:OnOpenCallback(cmd, isSuccess, rsp)
    if not isSuccess then
        return
    end 

    -- 清空上次选择
    self.selectItems = {}
    self:RefreshUI()
    
    ---@type CatchPetResultMediatorParameter
    local param = {}
    param.result = rsp.Return
    g_Game.UIManager:Open(UIMediatorNames.CatchPetResultMediator, param)

    g_Game.EventManager:TriggerEvent(EventConst.AUTO_PET_CATCH_STATE_CHANGED, self.param.furnitureId)
end

function CityLegoBuildingUIPage_CatchPet:GetPetAreaId(landCfgId)
    for _, cell in ConfigRefer.PetArea:pairs() do
        if cell:LandId() == landCfgId then
            return cell:Id()
        end
    end

    return 0
end

function CityLegoBuildingUIPage_CatchPet:OnSendClick()
    local req = AutoCatchPetParameter.new()
    req.args.FurnitureId = self.param.furnitureId
    req.args.PetAreaId = self:GetPetAreaId(self.selectLandCfgId)
    for itemCfgId, itemCount in pairs(self.selectItems) do
        if itemCount > 0 then
            local costItem = wds.CostItem.New()
            costItem.ConfigId = itemCfgId
            costItem.Count = itemCount
            req.args.CostItems:Add(costItem)
        end
    end
    req:SendOnceCallback(nil, nil, nil, Delegate.GetOrCreate(self, self.OnSendCallback))
end

---@param cmd AutoCatchPetParameter
---@param isSuccess boolean
---@param rsp wrpc.AutoCatchPetReply
function CityLegoBuildingUIPage_CatchPet:OnSendCallback(cmd, isSuccess, rsp)
    if not isSuccess then
        return
    end 

    self:RefreshUI()

    g_Game.EventManager:TriggerEvent(EventConst.AUTO_PET_CATCH_STATE_CHANGED, self.param.furnitureId)
end

function CityLegoBuildingUIPage_CatchPet:OnSendDisableClick()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('pet_drone_warning_des'))
end

return CityLegoBuildingUIPage_CatchPet