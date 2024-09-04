local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local TouchMenuMainBtnDatum = require('TouchMenuMainBtnDatum')
local Utils = require('Utils')
local RelocateCantPlaceReason = require('RelocateCantPlaceReason')
local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')
local TimeFormatter = require('TimeFormatter')
local ConfigTimeUtility = require('ConfigTimeUtility')
local Vector3 = CS.UnityEngine.Vector3

---@class RelocateMediator : BaseUIMediator
local RelocateMediator = class('RelocateMediator', BaseUIMediator)

---@class RelocateMediatorParameter
---@field camera BasicCamera
---@field worldPos CS.UnityEngine.Vector3
---@field relocatePos CS.UnityEngine.Vector3
---@field btns TouchMenuMainBtnDatum[]

function RelocateMediator:OnCreate()
    self.rootTrans = self:Transform("content")
    self.textTitle = self:Text('p_text_title')
    self.btnNewbieRelocate = self:Button('p_item1', Delegate.GetOrCreate(self, self.OnBtnNewbieRelocateItemClick))
    self.btnAllianceRelocate = self:Button('p_item2', Delegate.GetOrCreate(self, self.OnBtnAllianceRelocateItemClick))
    self.luaGoNewbieRelocate = self:LuaObject('p_item1')
    self.luaGoAllianceRelocate = self:LuaObject('p_item2')

    self.textDetailsList = {
        [1] = self:Text('p_text_detail'),
        [2] = self:Text('p_text_detail_1'),
        [3] = self:Text('p_text_detail_2'),
    }
    self.textQuantity = self:Text('p_text_quantity')

    self.textStatus = self:Text('p_text_status')

    self.btnGroup1 = self:GameObject('p_btn_group_1')
    self.btnGroup2 = self:GameObject('p_btn_group_2')
    self.btnGroup3 = self:GameObject('p_btn_group_3')

    self.btn1 = self:Button('p_btn_a', Delegate.GetOrCreate(self, self.OnClickCancel))
    self.btn2 = self:Button('p_btn_b', Delegate.GetOrCreate(self, self.OnClickRelocate))
    self.btn3 = self:Button('p_btn_c', Delegate.GetOrCreate(self, self.OnClickGetMore))

    self.btnText1 = self:Text('p_text_a', I18N.Get("relocate_btn_Cancel"))
    self.btnText2 = self:Text('p_text_b', I18N.Get("relocate_brn_Confirm_relocation"))
    self.btnText3 = self:Text('p_text_c', I18N.Get("relocate_getmore_btn"))

    -- self.luaGoConfirmBtn = self:LuaObject('p_group_btn_02')
end

---@param param RelocateMediatorParameter
function RelocateMediator:OnOpened(param)
    self.param = param
    self.camera = self.param.camera.mainCamera
    self.relocatePos = self.param.relocatePos
    self.needCheckRelocateStatus = false
    
    self.newbieRelocateItemID = ConfigRefer.ConstMain:NewbieRelocateItemID()
    self.allianceRelocateItemID = ConfigRefer.ConstMain:AllianceRelocateItemID()
    self.NewbieRelocateItemCfg = ConfigRefer.Item:Find(self.newbieRelocateItemID)
    self.AllianceRelocateItemCfg = ConfigRefer.Item:Find(self.allianceRelocateItemID)
    self.luaGoNewbieRelocate:OnFeedData({id = self.newbieRelocateItemID})
    self.luaGoAllianceRelocate:OnFeedData({id = self.allianceRelocateItemID})
    
    local newbieRelocateItemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.newbieRelocateItemID)
    if newbieRelocateItemCount > 0 then
        self:SelectedNewbieRelocateItem()
        self:RefreshItemNum(newbieRelocateItemCount)
    else
        self.btnNewbieRelocate.gameObject:SetActive(false)

        self:SelectedAllianceRelocateItem()
        local allianceRelocateItemCount = ModuleRefer.InventoryModule:GetAmountByConfigId(self.allianceRelocateItemID)
        self:RefreshItemNum(allianceRelocateItemCount)
    end

    self.kingdomPlaceModule = ModuleRefer.KingdomPlacingModule

    self:UpdatePosition()
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if hudMediator then
        hudMediator:SetVisible(false)
    end
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
end


function RelocateMediator:OnClickCancel()
    self.kingdomPlaceModule:EndPlacing()
end

function RelocateMediator:OnClickRelocate()
    self.kingdomPlaceModule:OnClickRelocate(self.relocateType)
end

function RelocateMediator:OnClickGetMore()
    local list = {}
    table.insert(list, {id = self.allianceRelocateItemID, num = 1})
    ModuleRefer.InventoryModule:OpenExchangePanel(list)
    self.kingdomPlaceModule:EndPlacing()
end

function RelocateMediator:OnClose(param)
    local hudMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.HUDMediator)
    if hudMediator then
        hudMediator:SetVisible(true)
    end
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnRelocateCDTick))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnLandformOpenTimeTick))
end

function RelocateMediator:RefreshItemNum(num)
    self.itemNum = num
    local numStr = tostring(num)
    if num == 0 then
        numStr = UIHelper.GetColoredText(numStr, "#FF0000")
    end
    self.textQuantity.text = I18N.Get("relocate_info_Already_have_item")..numStr
    
    self:CheckRelocateStatus()
end

function RelocateMediator:SelectedNewbieRelocateItem()
    self.luaGoNewbieRelocate:Selected()
    self.luaGoAllianceRelocate:Unselected()
    self.relocateType = wrpc.MoveCityType.MoveCityType_MoveToCurProvince
    if self.NewbieRelocateItemCfg then
        self.textTitle.text = I18N.Get(self.NewbieRelocateItemCfg:NameKey())
    end
    self.textDetailsList[1].text = I18N.Get("relocate_info_cond_1")
    self.textDetailsList[2].text = I18N.Get("relocate_info_cond_2")
    self.textDetailsList[3].text = I18N.Get("relocate_info_cond_3")
end

function RelocateMediator:SelectedAllianceRelocateItem()
    self.luaGoNewbieRelocate:Unselected()
    self.luaGoAllianceRelocate:Selected()
    self.relocateType = wrpc.MoveCityType.MoveCityType_MoveToAllianceTerrain
    if self.AllianceRelocateItemCfg then
        self.textTitle.text = I18N.Get(self.AllianceRelocateItemCfg:NameKey())
    end
    self.textDetailsList[1].text = I18N.Get("relocate_info_cond_1")
    self.textDetailsList[2].text = I18N.Get("relocate_info_cond_4")
    self.textDetailsList[3].text = I18N.Get("relocate_info_cond_5")
end

function RelocateMediator:OnBtnNewbieRelocateItemClick()
    self:SelectedNewbieRelocateItem()
    self:RefreshItemNum(ModuleRefer.InventoryModule:GetAmountByConfigId(self.newbieRelocateItemID))
end

function RelocateMediator:OnBtnAllianceRelocateItemClick()
    self:SelectedAllianceRelocateItem()
    self:RefreshItemNum(ModuleRefer.InventoryModule:GetAmountByConfigId(self.allianceRelocateItemID))
end

function RelocateMediator:OnLateTick()
    self:UpdatePosition()
end

function RelocateMediator:UpdatePosition()
    if Utils.IsNull(self.camera) then
        return
    end

    local screenPoint = self.camera:WorldToScreenPoint(self.param.worldPos)
    screenPoint.z = 0
    local uiCamera = g_Game.UIManager:GetUICamera()
    local pos = uiCamera:ScreenToWorldPoint(screenPoint)
    self.rootTrans.position = Vector3(pos.x + 1, pos.y, 0)
    if self.needCheckRelocateStatus then
        self:CheckRelocateStatus()
        self.needCheckRelocateStatus = false
    end
end

function RelocateMediator:CheckRelocateStatus()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnRelocateCDTick))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnLandformOpenTimeTick))
    
    local reason = ModuleRefer.RelocateModule.CanRelocate(self.relocatePos.x, self.relocatePos.y, self.relocateType)
    if reason == RelocateCantPlaceReason.CastleLevel then
        local toast = ModuleRefer.RelocateModule.CantRelocateToast(reason,self.relocatePos.x, self.relocatePos.y)
        self.textStatus.text = toast
        self.textStatus.color = CS.UnityEngine.Color.red
        self.textStatus:SetVisible(true)
        self.btnGroup2:SetVisible(false)
        self.btnGroup3:SetVisible(true)
    elseif reason == RelocateCantPlaceReason.ItemLimit then
        local toast = ModuleRefer.RelocateModule.CantRelocateToast(reason,self.relocatePos.x, self.relocatePos.y)
        self.textStatus.text = toast
        self.textStatus.color = CS.UnityEngine.Color.red
        self.textStatus:SetVisible(true)
        self.btnGroup2:SetVisible(false)
        self.btnGroup3:SetVisible(true)
    elseif reason == RelocateCantPlaceReason.InCD then
        self:OnRelocateCDTick()
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnRelocateCDTick))
        self.textStatus.color = CS.UnityEngine.Color.red
        self.textStatus:SetVisible(true)
        self.btnGroup2:SetVisible(false)
        self.btnGroup3:SetVisible(false)
    elseif reason == RelocateCantPlaceReason.LandformLocked then
        local toast = ModuleRefer.RelocateModule.CantRelocateToast(reason, self.relocatePos.x, self.relocatePos.y)
        if string.IsNullOrEmpty(toast) then
            self:OnLandformOpenTimeTick()
            g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnLandformOpenTimeTick))
            self.textStatus.color = CS.UnityEngine.Color.red
            self.textStatus:SetVisible(true)
            self.btnGroup2:SetVisible(false)
            self.btnGroup3:SetVisible(false)
        else
            self.textStatus.text = toast
            self.textStatus.color = CS.UnityEngine.Color.red
            self.textStatus:SetVisible(true)
            self.btnGroup2:SetVisible(false)
            self.btnGroup3:SetVisible(false)
        end
    elseif reason ~= RelocateCantPlaceReason.OK then
        local toast = ModuleRefer.RelocateModule.CantRelocateToast(reason, self.relocatePos.x, self.relocatePos.y)
        self.textStatus.text = toast
        self.textStatus.color = CS.UnityEngine.Color.red
        self.textStatus:SetVisible(true)
        self.btnGroup2:SetVisible(false)
        self.btnGroup3:SetVisible(false)
    else
        self.textStatus:SetVisible(false)
        self.btnGroup2:SetVisible(true)
        self.btnGroup3:SetVisible(false)
    end

    if self.itemNum == 0 then
        self.btnGroup3:SetVisible(true)
    else
        self.btnGroup3:SetVisible(false)
    end
end

function RelocateMediator:OnRelocateCDTick()
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local cdTime = ModuleRefer.PlayerModule:GetCastle().BasicInfo.MoveCityTime.Seconds
    self.remainTime = cdTime - serverTime
    
    if self.remainTime <= 0 then
        self.textStatus:SetVisible(false)
        self.btnGroup2:SetVisible(true)
        self.btnGroup3:SetVisible(false)
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnRelocateCDTick))
    else
        local timeStr = TimeFormatter.SimpleFormatTimeWithoutZero(self.remainTime)
        self.textStatus.text = I18N.GetWithParams("relocate_tips_Cooling", timeStr)
    end
end

function RelocateMediator:OnLandformOpenTimeTick()
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(self.relocatePos.x, self.relocatePos.y)
    local landCfgCell = ConfigRefer.Land:Find(landCfgId)
    if not landCfgCell then
        return
    end
    local systemEntryCfgCell = ConfigRefer.SystemEntry:Find(landCfgCell:SystemEntryId())
    if not systemEntryCfgCell then
        return
    end
    local unlockServerOpenTime = systemEntryCfgCell:UnlockServerOpenTime()
    if unlockServerOpenTime <= 0 then
        return
    end
    local kingdomEntity = ModuleRefer.KingdomModule:GetKingdomEntity()
    if not kingdomEntity then
        return
    end
    --没有开服时间
    local osTime = kingdomEntity.KingdomBasic.OsTime
    if osTime.Seconds <= 0 then
        return
    end
    
    local openTime = osTime.Seconds + ConfigTimeUtility.NsToSeconds(unlockServerOpenTime)
    self.remainOpenTime = openTime - serverTime
    if self.remainOpenTime <= 0 then
        self.textStatus:SetVisible(false)
        self.btnGroup2:SetVisible(true)
        self.btnGroup3:SetVisible(false)
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnRelocateCDTick))
    else
        local timeStr = TimeFormatter.SimpleFormatTimeWithDayHour(self.remainOpenTime)
        self.textStatus.text = I18N.GetWithParams("bw_tips_remove_land_unlock", timeStr)
    end
end

function RelocateMediator:UpdateRelocatePosParam(relocatePos, worldPos)
    if relocatePos then
        self.relocatePos = relocatePos
        self.param.relocatePos = relocatePos
    end
    if worldPos then
        self.param.worldPos = worldPos
    end
    self.needCheckRelocateStatus = true
end

return RelocateMediator