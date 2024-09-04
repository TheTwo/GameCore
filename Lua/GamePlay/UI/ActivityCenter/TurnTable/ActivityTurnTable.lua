local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require ('Delegate')
local ConfigRefer = require ('ConfigRefer')
local UIHelper = require ('UIHelper')
local ModuleRefer = require ('ModuleRefer')
local TurnTableConst = require ('TurnTableConst')
local I18N = require ('I18N')
local ActivityRewardType = require ('ActivityRewardType')
local PlayerAutoRewardOpParameter = require ('PlayerAutoRewardOpParameter')
local Utils = require ('Utils')
local UIMediatorNames = require ('UIMediatorNames')
local TimerUtility = require ('TimerUtility')
local FunctionClass = require ('FunctionClass')
local UIAsyncDataProvider = require ('UIAsyncDataProvider')
local PayConfirmHelper = require ('PayConfirmHelper')
local ExchangeMultiItemParameter = require ('ExchangeMultiItemParameter')
local EventConst = require ('EventConst')
---@class ActivityTurnTable : BaseUIComponent
local ActivityTurnTable = class('ActivityTurnTable', BaseUIComponent)
---@sence sence_child_activity_2
local ITEM_TYPE = TurnTableConst.ITEM_TYPE
local REWARD_STATUS = TurnTableConst.REWARD_STATUS

local FILL_DELTA = 0.01

---@class UpdateTurnTableParam
---@field updateMask number
---@field isManully boolean
---@field newReceivedGId number
---@field shouldPlayAnim boolean

local DATA_UPDATE_MASK = {
    LEFT = 1,
    RIGHT = 2,
    BTN = 4,
    ALL = 7,
}

local ANIM_MASK = {
    NORMAL_TURNTABLE = 1,
    ADV_TURNTABLE = 1 << 1,
    LEFT_UPDATE = 1 << 2,
    RIGHT_UPDATE = 1 << 3,
    SWITCH_TO_ADV = 1 << 4,
    ADV_REWARD = 1 << 5,
}

local TurnTablePayGroupId = 1018

function ActivityTurnTable._ItemAddHeroChecker()
    return false
end

function ActivityTurnTable:ctor()
    self.isAnimPlaying = 0
    self.leftRewards = {}
    self.leftDisks = {}
    self.rightRewards = {}
    self.isInited = false
    self.isDataFeeded = false
    self.isAnimTickStart = false
    self.animTimerSec = 0
    self.animCheckPoints = {}
    self.curCheckPointIndex = 1
    self.curSelectAdvIndex = 0
    self.lastIndex = 0
    self.advItemsLengthCache = 0
    self.receivedNormalItems = {}
    self.receivedAdvancedItems = {}
    self.newlyAcquiredGroupIds = {}
    self.delayedTimers = {}
    self.finishBlocker = false
    self.isFirstOpen = true
    self.isAutoReset = false
    self.normalItems = {}
    self.advancedItems = {}
    self.tabId = 0
    self.actId = 0
    self.configId = 0
    self.leftItemNum = 0

    self.isSkipAnim = g_Game.PlayerPrefsEx:GetIntByUid('turntable_toggle', 0) == 1
end

function ActivityTurnTable:OnCreate()
    self.imgReward = self:Image('p_img_reward')
    self.textTitle = self:Text('p_text_title', I18N.Get('activity_turn_table_title'))
    self.textTime = self:Text('p_text_time')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.goArrow = self:GameObject('p_group_indicator')
    ---@type CS.TurntableAnimCurve
    self.animCtrlArrow = self:BindComponent('p_group_indicator', typeof(CS.TurntableAnimCurve))
    self.animCtrlPanel = self:BindComponent('p_group_rewards_2', typeof(CS.TurntableAnimCurve))
    self.goLeftDisk = self:GameObject('p_group_disk_1')

    ---@type CS.DragonReborn.UI.UGUIExtends.CircleLayoutGroup
    self.layoutLeftRewards = self:BindComponent('p_group_rewards_1', typeof(CS.DragonReborn.UI.UGUIExtends.CircleLayoutGroup))

    self.normalItemTemplate = self:LuaBaseComponent('p_item_2')
    self.emptyItem = self:LuaBaseComponent('p_item_1')
    self.leftDiskTemplate = self:LuaBaseComponent('p_disk_1')

    self.btnDrawSingle = self:Button('child_comp_btn_e_l', Delegate.GetOrCreate(self, self.DrawSingle))
    self.textDrawSingle = self:Text('p_text_e', I18N.Get('activity_turn_table_btn1_active'))
    self.imgIconCostItemSingle = self:Image('p_icon_e')
    self.textNumCostItemSingleGreen = self:Text('p_text_num_green_e')
    self.textNumCostItemSingleRed = self:Text('p_text_num_red_e')
    self.textNumCostItemSingle = self:Text('p_text_num_e')

    self.btnDrawMulti = self:Button('child_comp_btn_e_l_2', Delegate.GetOrCreate(self, self.DrawMulti))
    self.textDrawMulti = self:Text('p_text_e_2')
    self.imgIconCostItemMulti = self:Image('p_icon_e_2')
    self.textNumCostItemMultiGreen = self:Text('p_text_num_green_e_2')
    self.textNumCostItemMultiRed = self:Text('p_text_num_red_e_2')
    self.textNumCostItemMulti = self:Text('p_text_num_e_2')
    self.goHint = self:GameObject('p_hint')
    self.textHint = self:Text('p_text_hint')

    self.toggleSkip = self:Toggle('child_toggle', Delegate.GetOrCreate(self, self.OnToggleSkipClicked))
    self.textSkip = self:Text('p_text_skip', 'turn_table_skip_txt')

    self.btnActivityDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.statusRecordParent = self:StatusRecordParent('')

    self.vxTrigger = self:AnimTrigger('vx_trigger')
    self.animGroupLight = self:BindComponent('p_group_light', typeof(CS.UnityEngine.Animation))

    self.imgTurnBase = self:Image('p_base')
    self.isFirstOpen = true

    self.toggleSkip.isOn = self.isSkipAnim

    self.btnToken = self:Button('p_btn_token', Delegate.GetOrCreate(self, self.OnBtnTokenClicked))
end

function ActivityTurnTable:OnFeedData(param)
    if not param then
        return
    end
    self.tabId = param.tabId
    self.actId = ConfigRefer.ActivityCenterTabs:Find(self.tabId):RefActivityReward()
    self.configId = ConfigRefer.ActivityRewardTable:Find(self.actId):RefConfig()
    local cfg = ConfigRefer.Turntable:Find(self.configId)
    self.isAutoReset = cfg:AutoReset()
    self.normalItems = self:GetNormalItems()
    self.normalItems[0] = {}
    self.advancedItems = self:GetAdvancedItems()
    self.newlyAcquiredGroupIds = {}
    self.finishBlocker = false
    self.isDataFeeded = true
    self:BuildPage()
    self:UpdateTurnTable({shouldPlayAnim = false})
end

function ActivityTurnTable:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.AnimTick))
    g_Game.ServiceManager:AddResponseCallback(ExchangeMultiItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnExchange))
    g_Game.EventManager:AddListener(EventConst.ON_UIMEDIATOR_OPENED, Delegate.GetOrCreate(self, self.OnUIMediatorOpened))

    self.btnToken.gameObject:SetActive(ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(TurnTablePayGroupId))

    self.delayedTimers = {}
    ModuleRefer.HeroModule:AddItemHeroPopupChecker(self._ItemAddHeroChecker)
    if not self.isInited and self.isDataFeeded then
        self:BuildPage()
        self:UpdateTurnTable({shouldPlayAnim = false})
    end
end

function ActivityTurnTable:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.AnimTick))
    g_Game.ServiceManager:RemoveResponseCallback(ExchangeMultiItemParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnExchange))
    g_Game.EventManager:RemoveListener(EventConst.ON_UIMEDIATOR_OPENED, Delegate.GetOrCreate(self, self.OnUIMediatorOpened))

    self:DestroyComponents()
    self:KillTurnTableAnimOnHide()
    self:ResetUpdateTurnTableAnim()
    ModuleRefer.HeroModule:RemoveItemHeroPopupChecker(self._ItemAddHeroChecker)

    for _, timer in pairs(self.delayedTimers) do
        TimerUtility.StopAndRecycle(timer)
    end
end

function ActivityTurnTable:OnBtnDetailClicked()
    ---@type TextToastMediatorParameter
    local tipParam = {}
    tipParam.clickTransform = self.btnDetail.gameObject.transform
    tipParam.content = I18N.Get('activity_turn_table_txt')
    ModuleRefer.ToastModule:ShowTextToast(tipParam)
end

function ActivityTurnTable:OnToggleSkipClicked(value)
    self.isSkipAnim = value
    g_Game.PlayerPrefsEx:SetIntByUid('turntable_toggle', value and 1 or 0)
    if value and self.isAnimPlaying ~= 0 then
        self:KillTurnTableAnimOnHide()
        self:ResetUpdateTurnTableAnim()
        self:ShowRewardPopup(self.newlyAcquiredGroupIds)
    end
end

function ActivityTurnTable:OnBtnTokenClicked()
    local pGroupId = ConfigRefer.Turntable:Find(self.configId):RefPayGroup()
    local isPackAvaliable = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(pGroupId) ~= nil
    if isPackAvaliable then
        local provider = require("PayGroupBundleListDataProvider").new(pGroupId)
        g_Game.UIManager:Open(UIMediatorNames.CommonPopupBundleListMediator, provider)
    end
end

function ActivityTurnTable:BuildPage()
    self:DestroyComponents()
    self:DuplicateComponents()
    for i, lDisk in pairs(self.leftDisks) do
        if i == 0 then
            lDisk.Lua:SetTransparency()
        else
            lDisk:FeedData({itemId = self.normalItems[i].id})
        end
    end
    self.isInited = true
end

function ActivityTurnTable:DuplicateComponents()
    self.normalItemTemplate:SetVisible(true)
    self.leftDiskTemplate:SetVisible(true)

    local leftLength = ConfigRefer.Turntable:Find(self.configId):LeftTurnNormalItemsLength()
    local rightLength = ConfigRefer.Turntable:Find(self.configId):RightTurnNormalItemsLength() + 1

    for _ = 1, leftLength do
        table.insert(self.leftRewards, UIHelper.DuplicateUIComponent(self.normalItemTemplate))
        table.insert(self.leftDisks, UIHelper.DuplicateUIComponent(self.leftDiskTemplate))
    end
    self.leftDisks[0] = UIHelper.DuplicateUIComponent(self.leftDiskTemplate)
    self.normalItemTemplate:SetVisible(false)
    self.leftDiskTemplate:SetVisible(false)

    self.highItemTemplate = self:LuaBaseComponent('p_item_big')
    self.highItemTemplate:SetVisible(true)
    for _ = 1, rightLength do
        table.insert(self.rightRewards, UIHelper.DuplicateUIComponent(self.highItemTemplate))
    end
    self.highItemTemplate:SetVisible(false)
end

function ActivityTurnTable:DestroyComponents()
    for _, comp in pairs(self.leftRewards) do
        UIHelper.DeleteUIComponent(comp)
    end
    for _, comp in pairs(self.leftDisks) do
        UIHelper.DeleteUIComponent(comp)
    end
    for _, comp in pairs(self.rightRewards) do
        UIHelper.DeleteUIComponent(comp)
    end
    table.clear(self.leftRewards)
    table.clear(self.leftDisks)
    table.clear(self.rightRewards)
    self.isInited = false
end

--- 监听回调 ---

function ActivityTurnTable:OnExchange()
    local param = {}
    param.updateMask = DATA_UPDATE_MASK.BTN
    self:UpdateTurnTable(param)
end

function ActivityTurnTable:OnUIMediatorOpened(mediatorName)
    if mediatorName == UIMediatorNames.ActivityShopMediator then
        self.isInited = false
    end
end

--- end of 监听回调 ---

--- 数据更新 ---

function ActivityTurnTable:UpdateNormalItemsStatus(isManully, newReceivedGId)
    if isManully then
        table.insert(self.receivedNormalItems, newReceivedGId)
    else
        self.receivedNormalItems = self:GetReceivedNormalItems()
    end
    for _, item in pairs(self.normalItems) do
        item.isReceived = table.ContainsValue(self.receivedNormalItems, item.groupId)
    end
end

function ActivityTurnTable:UpdateAdvancedItemsStatus()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self.receivedAdvancedItems = {}
    Utils.CopyArray(player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.RightTurnItems, self.receivedAdvancedItems)
    for _, item in pairs(self.advancedItems) do
        item.isReceived = table.ContainsValue(self.receivedAdvancedItems, item.groupId)
    end
end

function ActivityTurnTable:UpdateNewlyAcquiredGroupIds(rsp)
    self.newlyAcquiredGroupIds = {}
    for _, gId in ipairs(rsp.Reply.TurntableRightRewards) do
        table.insert(self.newlyAcquiredGroupIds, gId)
    end
    for _, gId in ipairs(rsp.Reply.TurntableLeftRewards) do
        table.insert(self.newlyAcquiredGroupIds, gId)
    end
end

---@param params UpdateTurnTableParam
function ActivityTurnTable:UpdateTurnTable(params)
    local paramsOrEmpty = params or {}
    local updateMask = paramsOrEmpty.updateMask
    local isManully = paramsOrEmpty.isManully
    local newReceivedGId = paramsOrEmpty.newReceivedGId
    local shouldPlayAnim = paramsOrEmpty.shouldPlayAnim
    self.statusRecordParent:ApplyStatusRecord(0)
    if not updateMask then
        updateMask = DATA_UPDATE_MASK.ALL
    end
    if updateMask & DATA_UPDATE_MASK.LEFT ~= 0 then
        self:UpdateLeftTurnTable(isManully, newReceivedGId, shouldPlayAnim)
    end
    if updateMask & DATA_UPDATE_MASK.RIGHT ~= 0 then
        self:UpdateRightTurnTable()
    end
    if updateMask & DATA_UPDATE_MASK.BTN ~= 0 then
        self:UpdateBtns()
    end

    self.btnToken.gameObject:SetActive(ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(TurnTablePayGroupId))
end

---@param isManully boolean 设置为true时手动更新数据，用于客户端表现，此时转盘内容与服务器数据不一致
---@param newReceivedGid number 本轮抽到的奖励组id，仅在isManully为true时传入
function ActivityTurnTable:UpdateLeftTurnTable(isManully, newReceivedGid, shouldPlayAnim)
    self:UpdateNormalItemsStatus(isManully, newReceivedGid)
    if shouldPlayAnim == nil then shouldPlayAnim = true end
    if shouldPlayAnim then
        self:PlayUpdateTurnTableAnim()
    end
    self.leftItemNum = #self.leftRewards + 1 - #self.receivedNormalItems
    local paddingOrder = 0
    for i = 1, #self.leftRewards do
        if self.normalItems[i].isReceived then
            self.leftRewards[i]:SetVisible(false)
            self.leftDisks[i]:SetVisible(false)
            goto continue
        else
            self.leftRewards[i]:SetVisible(true)
            self.leftDisks[i]:SetVisible(true)
            self.leftDisks[i].Lua:SetSelect(false)
        end
        paddingOrder  = paddingOrder + 1
        local data = {
            itemId = self.normalItems[i].id,
            count = self.normalItems[i].count,
            type = ITEM_TYPE.NORMAL
        }
        self.leftRewards[i]:FeedData(data)
        self.leftDisks[i].Lua:SetFillAmount((1 + FILL_DELTA) / self.leftItemNum)
        local angle = 360 * paddingOrder / self.leftItemNum
        self.leftDisks[i].Lua:SetOffset(angle)
        self.normalItems[i].angle = angle
        local shouldGray = isManully and not newReceivedGid
        self.leftRewards[i].Lua:SetGrayDisplay(shouldGray)
        if shouldGray then
            self.leftRewards[i].Lua:PlayNormalRewardReceivedAnim()
        end
        ::continue::
    end
    self.layoutLeftRewards.PaddingAngle = 360 / self.leftItemNum
    self.goLeftDisk.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, 0, 180 / self.leftItemNum)
    self.leftDisks[0].Lua:SetFillAmount(1 / self.leftItemNum)
    self.leftDisks[0].Lua:SetOffset(0)
    self.normalItems[0].angle = 0
    self:UpdateBaseImgAngle(360 - 360 / self.leftItemNum)
    self:RemoveAnimPlayingStatus(ANIM_MASK.LEFT_UPDATE)
    self:RemoveAnimPlayingStatus(ANIM_MASK.NORMAL_TURNTABLE)
end

function ActivityTurnTable:UpdateRightTurnTable()
    self:UpdateAdvancedItemsStatus()
    for i, item in pairs(self.advancedItems) do
        local itemSolt = self.rightRewards[i + 1]
        itemSolt.Lua:SetGrayDisplay(item.isReceived)
        local data = {
            itemId = item.id,
            count = item.count,
            type = ITEM_TYPE.HIGH
        }
        itemSolt:FeedData(data)
    end
    self:RemoveAnimPlayingStatus(ANIM_MASK.RIGHT_UPDATE)
    self:RemoveAnimPlayingStatus(ANIM_MASK.ADV_TURNTABLE)
end

function ActivityTurnTable:UpdateBtns()
    local cfg = ConfigRefer.Turntable:Find(self.configId)
    local icon, neededValue, neededValueMulti, curValue
    local isResetCostItemAvaliable = (cfg:ResetCostItem() and cfg:ResetCostItem() ~= 0)
    if self:IsFinished() and not self.finishBlocker and not self.isAutoReset then
        local costItemGid = cfg:ResetCostItem()
        if not costItemGid or costItemGid == 0 then
            g_Logger.Error('转盘重置方式为手动重置，但没有配置重置道具')
            return
        end
        self.btnDrawSingle.gameObject:SetActive(false)
        self.textDrawMulti.text = I18N.Get('*重置')
        self.goHint:SetActive(false)
        local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(costItemGid)[1]
        local costItemId = costItem.configCell:Id()
        icon = costItem.configCell:Icon()
        neededValue = costItem.count
        neededValueMulti = costItem.count
        -- curValue = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
        curValue = self:GetCostItemAmount()
    else
        self.btnDrawSingle.gameObject:SetActive(true)
        self.textDrawMulti.text = I18N.GetWithParams('activity_turn_table_btn2_nagetive', self.leftItemNum)
        self.goHint:SetActive(true)
        self.textHint.text = I18N.GetWithParams('activity_turn_table_btn2_txt', self.leftItemNum)
        local costLength = cfg:TurnCostItemLength()
        local curRound = math.min(self:GetCurRound(), costLength)
        local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:TurnCostItem(curRound))[1]
        local costItemId = costItem.configCell:Id()
        icon = costItem.configCell:Icon()
        neededValue = costItem.count
        neededValueMulti = neededValue * self.leftItemNum
        -- curValue = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
        curValue = self:GetCostItemAmount()
    end
    self.textNumCostItemSingleGreen.text = curValue
    self.textNumCostItemSingleRed.text = curValue
    self.textNumCostItemSingle.text = ' / ' .. neededValue
    self.textNumCostItemSingleGreen.gameObject:SetActive(curValue >= neededValue)
    self.textNumCostItemSingleRed.gameObject:SetActive(curValue < neededValue)

    self.textNumCostItemMultiGreen.text = curValue
    self.textNumCostItemMultiRed.text = curValue
    self.textNumCostItemMulti.text = ' / ' .. neededValueMulti
    self.textNumCostItemMultiGreen.gameObject:SetActive(curValue >= neededValueMulti)
    self.textNumCostItemMultiRed.gameObject:SetActive(curValue < neededValueMulti)

    g_Game.SpriteManager:LoadSprite(icon, self.imgIconCostItemSingle)
    g_Game.SpriteManager:LoadSprite(icon, self.imgIconCostItemMulti)
end

function ActivityTurnTable:UpdateBaseImgAngle(angle)
    self.imgTurnBase.fillAmount = angle / 360
    local offset = (angle - 360) / 2
    self.imgTurnBase.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, offset)
end

--- end of 数据更新 ---

--- 动画 ---

function ActivityTurnTable:AnimTick(dt)
    if not self.isAnimTickStart then
        return
    end
    self.animTimerSec = self.animTimerSec + dt
    if self.animTimerSec >= self.animCheckPoints[self.curCheckPointIndex] then
        if self.curCheckPointIndex == #self.animCheckPoints then
            self.isAnimTickStart = false
            self:RemoveAnimPlayingStatus(ANIM_MASK.ADV_TURNTABLE)
            self.finishBlocker = false
            local updateMask = DATA_UPDATE_MASK.ALL
            if self:IsFinished() then
                updateMask = updateMask ~ DATA_UPDATE_MASK.LEFT
            end
            if self.curSelectAdvIndex == 0 then self.curSelectAdvIndex = #self.rightRewards end
            self:AddAnimPlayingStatus(ANIM_MASK.ADV_REWARD)
            self.rightRewards[self.curSelectAdvIndex].Lua:PlayAdvancedRewardAnim(Delegate.GetOrCreate(self, function()
                self:ShowRewardPopup(self.newlyAcquiredGroupIds, updateMask)
                self:ResetSwitch2AdvancedRewardAnim()
                self.curSelectAdvIndex = 0
                self:RemoveAnimPlayingStatus(ANIM_MASK.ADV_REWARD)
            end))
            return
        end
        local curSelectAdvIndex = self.curSelectAdvIndex or 0
        while self.advancedItems[curSelectAdvIndex].isReceived do
            curSelectAdvIndex = (curSelectAdvIndex + 1) % #self.rightRewards
        end
        self.curSelectAdvIndex = curSelectAdvIndex
        for i, _ in pairs(self.advancedItems) do
            local itemSolt = self.rightRewards[i + 1]
            -- itemSolt.Lua:SetGetDisplay(self.curSelectAdvIndex == i)
            itemSolt.Lua:SetSelect(self.curSelectAdvIndex == i)
        end
        self.curSelectAdvIndex = (self.curSelectAdvIndex + 1) % #self.rightRewards
        self.curCheckPointIndex = self.curCheckPointIndex + 1
    end
end

function ActivityTurnTable:PlayTurnTableAnimOnce(targetIndexs, curPos)
    local curve = self.animCtrlArrow.animationCurve
    local duration = self.animCtrlArrow.duration
    local minTurns, maxTurns = self.animCtrlArrow.minTurns, self.animCtrlArrow.maxTurns
    local numTurns = math.random(minTurns, maxTurns)
    local targetIndex = targetIndexs[curPos]
    local targetItemAngle = (self.normalItems[targetIndex].angle) % 360
    local curArrowAngle = self.goArrow.transform.localRotation.eulerAngles.z % 360
    local angleDiff = (targetItemAngle - curArrowAngle) % -360 + (-360 * numTurns)
    local endValue = CS.UnityEngine.Vector3(0, 0, angleDiff)
    self:AddAnimPlayingStatus(ANIM_MASK.NORMAL_TURNTABLE)
    -- self:SetBtnsDisable(true)
    local animHandle = self.goArrow.transform:DOLocalRotate(endValue, duration, CS.DG.Tweening.RotateMode.LocalAxisAdd):SetEase(curve)
    animHandle:OnComplete(function()
        if targetIndex ~= 0 then
            local param = {}
            param.isManully = #targetIndexs > 1
            param.newReceivedGId = self.normalItems[targetIndex].groupId
            param.updateMask = DATA_UPDATE_MASK.LEFT | DATA_UPDATE_MASK.BTN
            if not param.isManully then
                self.leftRewards[targetIndex].Lua:PlayNormalRewardAnim(Delegate.GetOrCreate(self, function()
                    self:ShowRewardPopup(self.newlyAcquiredGroupIds, param.updateMask)
                end))
            end
            if curPos < #targetIndexs then
                self.leftRewards[targetIndex].Lua:PlayNormalRewardAnim(Delegate.GetOrCreate(self, function()
                    self:PlayUpdateTurnTableAnim(function()
                        param.shouldPlayAnim = false
                        self:UpdateTurnTable(param)
                        self:PlayTurnTableAnimOnce(targetIndexs, curPos + 1)
                    end)
                end))
            else
                -- self.isAnimPlaying = false
            end
        else
            local player = ModuleRefer.PlayerModule:GetPlayer()
            self.receivedAdvancedItems = player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.RightTurnItems
            local targetAdvItemIndex = self:GetAdvancedRewardIndex(#self.receivedAdvancedItems)
            self:PlaySwitch2AdvancedRewardAnim()
            self:UpdateTurnTable({
                updateMask = DATA_UPDATE_MASK.LEFT,
                isManully = true,
                shouldPlayAnim = false})
            local delayedTimer = TimerUtility.DelayExecute(function()
                self:PlayAdvancedTurnTableAnim(targetAdvItemIndex)
                self:RemoveAnimPlayingStatus(ANIM_MASK.SWITCH_TO_ADV)
            end, self.animGroupLight:GetClip('anim_vx_activity2_tube').length)
            table.insert(self.delayedTimers, delayedTimer)
        end
    end)
    animHandle:OnUpdate(function()
        local curIndex = self:GetArrowPointingItem(targetIndex)
        if curIndex == self.lastIndex then
            return
        end
        self.lastIndex = curIndex
        for i, disk in pairs(self.leftDisks) do
            disk.Lua:SetSelect(i == curIndex)
        end
    end)
end

function ActivityTurnTable:KillTurnTableAnimOnHide()
    if self.isAnimPlaying ~= 0 then
        self.goArrow.transform:DOKill()
        self.isAnimPlaying = 0
        self.isAnimTickStart = false
        self.finishBlocker = false
        self:ResetSwitch2AdvancedRewardAnim()
    end
end

function ActivityTurnTable:PlayAdvancedTurnTableAnim(targetIndex)
    local curve = self.animCtrlPanel.animationCurve
    local duration = self.animCtrlPanel.duration
    local minTurns, maxTurns = self.animCtrlPanel.minTurns, self.animCtrlPanel.maxTurns
    local numTurns = math.random(minTurns, maxTurns)
    local curSelectAdvIndex = self.curSelectAdvIndex or 0
    while self.advancedItems[curSelectAdvIndex].isReceived do
        curSelectAdvIndex = (curSelectAdvIndex + 1) % #self.rightRewards
    end
    self.curSelectAdvIndex = curSelectAdvIndex
    local targetDist = 1
    -- local advItemLength = #self.rightRewards - #self.receivedAdvancedItems + 1
    while curSelectAdvIndex ~= targetIndex do
        if self.advancedItems[curSelectAdvIndex].isReceived then
            curSelectAdvIndex = (curSelectAdvIndex + 1) % #self.rightRewards
            goto continue
        end
        targetDist = targetDist + 1
        curSelectAdvIndex = (curSelectAdvIndex + 1) % #self.rightRewards
        ::continue::
    end
    local numCheckPoints = targetDist + self.advItemsLengthCache * numTurns + 1
    self.animCheckPoints = {}
    for i = 1, numCheckPoints do
        local percent = i / numCheckPoints
        self.animCheckPoints[i] = self:FindTimeForValue(curve, percent) * duration
    end
    self.animTimerSec = 0
    self.curCheckPointIndex = 1
    self:AddAnimPlayingStatus(ANIM_MASK.ADV_TURNTABLE)
    self.isAnimTickStart = true
    -- self.statusRecordParent:ApplyStatusRecord(1)
end

---@param callback fun()
function ActivityTurnTable:PlayUpdateTurnTableAnim(callback)
    self:AddAnimPlayingStatus(ANIM_MASK.LEFT_UPDATE)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, callback)
end

function ActivityTurnTable:ResetUpdateTurnTableAnim()
    if self.vxTrigger then
        self.vxTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    end
end

---@param callback fun()
function ActivityTurnTable:PlaySwitch2AdvancedRewardAnim(callback)
    self:AddAnimPlayingStatus(ANIM_MASK.SWITCH_TO_ADV)
    self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, callback)
end

function ActivityTurnTable:ResetSwitch2AdvancedRewardAnim()
    self.vxTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom3)
end

function ActivityTurnTable:FindTimeForValue(curve, value)
    local startTime = curve.keys[0].time
    local endTime = curve.keys[curve.length - 1].time
    local time = startTime
    local step = (endTime - startTime) / 100
    while time < endTime do
        local curValue = curve:Evaluate(time)
        if math.abs(curValue - value) < 0.01 then
            return time
        end
        time = time + step
    end
end

function ActivityTurnTable:AddAnimPlayingStatus(animType)
    -- g_Logger.Error('AddAnimPlayingStatus: ' .. animType)
    self.isAnimPlaying = self.isAnimPlaying | animType
end

function ActivityTurnTable:RemoveAnimPlayingStatus(animType)
    -- g_Logger.Error('RemoveAnimPlayingStatus: ' .. animType)
    self.isAnimPlaying = self.isAnimPlaying & ~animType
end

--- end of 动画 ---

--- 抽卡 ---

function ActivityTurnTable:DrawSingle()
    if self.isAnimPlaying ~= 0 then
        return
    end
    local isEnough, _, curValue, neededValue, _ = self:IsItemEnough()
    if not isEnough then
        self:ShowGetMore(curValue, neededValue)
        return
    end
    self.advItemsLengthCache = #self.rightRewards - #self.receivedAdvancedItems
    local op = wrpc.PlayerAutoRewardOperation()
    op.ConfigId = self.actId
    op.OperationType = wrpc.AutoRewardOperationType.AutoRewardOperationSingleTurn
    local msg = PlayerAutoRewardOpParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(self.btnDrawSingle.gameObject.transform, nil, nil, function(_, isSuccess, rsp)
        if isSuccess then
            if not self:IsFinished() then
                self:UpdateBtns()
            else
                self.finishBlocker = true
            end
            self:UpdateNewlyAcquiredGroupIds(rsp)
            -- self:UpdateNormalItemsStatus()
            local gId = rsp.Reply.TurntableLeftRewards[1]
            if #rsp.Reply.TurntableRightRewards > 0 then
                gId = 0
            end
            if self.isSkipAnim then
                self.finishBlocker = false
                self:ShowRewardPopup(self.newlyAcquiredGroupIds)
            else
                local targetIndex = self:GetNormalRewardIndexByGId(gId)
                self:PlayTurnTableAnimOnce({targetIndex}, 1)
            end
        end
    end)
end

function ActivityTurnTable:DrawMulti()
    if self.isAnimPlaying ~= 0 then
        return
    end
    if self:IsFinished() then
        if not self.isAutoReset then
            self:ResetTurnTable(function()
                self:UpdateTurnTable()
            end)
        else
            g_Logger.Error('Not Avaliable')
        end
        return
    end
    local _, isEnoughMulti, curValue, _, neededValueMulti = self:IsItemEnough()
    if not isEnoughMulti then
        self:ShowGetMore(curValue, neededValueMulti)
        return
    end
    self.advItemsLengthCache = #self.rightRewards - #self.receivedAdvancedItems
    local op = wrpc.PlayerAutoRewardOperation()
    op.ConfigId = self.actId
    op.OperationType = wrpc.AutoRewardOperationType.AutoRewardOperationFullTurn
    local msg = PlayerAutoRewardOpParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(self.btnDrawMulti.gameObject.transform, nil, nil, function(_, isSuccess, rsp)
        if isSuccess then
            self:UpdateNewlyAcquiredGroupIds(rsp)
            if self.isSkipAnim then
                self.finishBlocker = false
                self:ShowRewardPopup(self.newlyAcquiredGroupIds)
                return
            end
            local turnCount = rsp.Reply.TurntableTurnCount
            local leftRewards = rsp.Reply.TurntableLeftRewards
            local targetIndexs = {}
            for i = 1, turnCount do
                local targetIndex
                if i == turnCount then
                    targetIndex = 0
                else
                    targetIndex = self:GetNormalRewardIndexByGId(leftRewards[i])
                end
                table.insert(targetIndexs, targetIndex)
            end
            if not self:IsFinished() then
                self:UpdateBtns()
            else
                self.finishBlocker = true
            end
            self:PlayTurnTableAnimOnce(targetIndexs, 1)
        end
    end)
end

function ActivityTurnTable:ResetTurnTable(callback)
    local op = wrpc.PlayerAutoRewardOperation()
    op.ConfigId = self.actId
    op.OperationType = wrpc.AutoRewardOperationType.AutoRewardOperationResetTurn
    local msg = PlayerAutoRewardOpParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(self.btnDrawMulti.gameObject.transform, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            callback()
        end
    end)
end

function ActivityTurnTable:ShowGetMore(curValue, neededValue)
    local pGroupId = ConfigRefer.Turntable:Find(self.configId):RefPayGroup()
    local isPackAvaliable = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(pGroupId) ~= nil
    if isPackAvaliable then
        local provider = require("PayGroupBundleListDataProvider").new(pGroupId)
        g_Game.UIManager:Open(UIMediatorNames.CommonPopupBundleListMediator, provider)
        return
    end
    local insufficientCount = neededValue - curValue
    local costItemId = self:GetCostItem().configCell:Id()
    PayConfirmHelper.ShowSimpleConfirmationPopupForInsufficientItem(costItemId, insufficientCount, function()
        g_Game.UIManager:Open(UIMediatorNames.ActivityShopMediator, {tabId = 9})
        self.isInited = false
    end)
end

--- end of 抽卡 ---

--- Getters ---

function ActivityTurnTable:GetReceivedNormalItems()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local ret = {}
    Utils.CopyArray(player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.LeftTurnItems, ret)
    return ret
end

function ActivityTurnTable:GetCurRound()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.Round + 1
end

function ActivityTurnTable:GetNormalItems()
    self.receivedNormalItems = self:GetReceivedNormalItems()
    local items = {}
    local config = ConfigRefer.Turntable:Find(self.configId)
    for i = 1, config:LeftTurnNormalItemsLength() do
        local groupId = config:LeftTurnNormalItems(i)
        local itemInfo = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(groupId)[1]
        itemInfo.isReceived = table.ContainsValue(self.receivedNormalItems, groupId)
        itemInfo.groupId = groupId
        table.insert(items, itemInfo)
    end
    return items
end

function ActivityTurnTable:GetCostItemAmount()
    local costItemId = self:GetCostItem().configCell:Id()
    local costItemUid = ModuleRefer.InventoryModule:GetUidByConfigId(costItemId)
    local amount = ModuleRefer.InventoryModule:GetAmountByUid(costItemUid)
    return amount
end

function ActivityTurnTable:GetAdvancedItems()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self.receivedAdvancedItems = {}
    Utils.CopyArray(player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.RightTurnItems, self.receivedAdvancedItems)
    local items = {}
    local config = ConfigRefer.Turntable:Find(self.configId)
    for i = 1, config:RightTurnNormalItemsLength() do
        local groupId = config:RightTurnNormalItems(i)
        local itemInfo = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(groupId)[1]
        itemInfo.isReceived = table.ContainsValue(self.receivedAdvancedItems, groupId)
        itemInfo.groupId = groupId
        table.insert(items, itemInfo)
    end
    local vipItemGroupId = ConfigRefer.Turntable:Find(self.configId):RightTurnVIPItem()
    local vipItemInfo = ModuleRefer.InventoryModule:ItemGroupId2ItemIds(vipItemGroupId)[1]
    vipItemInfo.isReceived = table.ContainsValue(self.receivedAdvancedItems, vipItemGroupId)
    vipItemInfo.groupId = vipItemGroupId
    items[0] = vipItemInfo
    return items
end

function ActivityTurnTable:GetNormalRewardIndex(newReceivedIndex)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local receivedGroupId = player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.LeftTurnItems[newReceivedIndex]
    return self:GetNormalRewardIndexByGId(receivedGroupId)
end

function ActivityTurnTable:GetNormalRewardIndexByGId(receivedGroupId)
    if not receivedGroupId or receivedGroupId == 0 then
        return 0
    end
    for i, item in ipairs(self.normalItems) do
        if item.groupId == receivedGroupId then
            return i
        end
    end
end

function ActivityTurnTable:GetAdvancedRewardIndex(newReceivedIndex)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local receivedGroupId = player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.RightTurnItems[newReceivedIndex]
    if not receivedGroupId or newReceivedIndex == #self.rightRewards then
        return 0
    end
    for i, item in pairs(self.advancedItems) do
        if item.groupId == receivedGroupId then
            return i
        end
    end
end

function ActivityTurnTable:GetArrowPointingItem(targetIndex)
    local curArrowAngle = self.goArrow.transform.localRotation.eulerAngles.z % 360
    for i, item in pairs(self.normalItems) do
        if item.isReceived and i ~= targetIndex then
            goto continue
        end
        local itemAngle = ((item.angle or 0)) % 360
        local halfDiskAngle = 360 / self.leftItemNum / 2
        local lb, rb = itemAngle - halfDiskAngle, itemAngle + halfDiskAngle
        if curArrowAngle > lb and curArrowAngle <= rb then
            return i
        end
        ::continue::
    end
end

function ActivityTurnTable:GetCostItem()
    local cfg = ConfigRefer.Turntable:Find(self.configId)
    local costLength = cfg:TurnCostItemLength()
    local curRound = math.min(self:GetCurRound(), costLength)
    local costItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(cfg:TurnCostItem(curRound))[1]
    return costItem
end

--- end of Getters ---

function ActivityTurnTable:IsItemEnough()
    local costItem = self:GetCostItem()
    local costItemId = costItem.configCell:Id()
    local neededValue = costItem.count
    local neededValueMulti = neededValue * self.leftItemNum
    -- local curValue = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
    local curValue = self:GetCostItemAmount()
    return curValue >= neededValue, curValue >= neededValueMulti, curValue, neededValue, neededValueMulti
end

function ActivityTurnTable:IsFinished()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].TurntableParam.Empty
end

function ActivityTurnTable:ShowRewardPopup(itemGroupIds, updateMask, ...)
    local items = {}
    local isManully, newReceivedGId = ...
    ---@type table<number, UIAsyncDataProvider>
    local popUpProviders = {}
    for _, itemGroupId in pairs(itemGroupIds) do
        local itemList = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(itemGroupId)
        for _, item in pairs(itemList) do
            if item.configCell:FunctionClass() == FunctionClass.AddHero then
                local param = {
                    heroId = tonumber(item.configCell:UseParam(1)),
                }
                ---@type UIAsyncDataProvider
                local provider = UIAsyncDataProvider.new()
                provider:Init(
                    UIMediatorNames.UIOneDaySuccessMediator,
                    UIAsyncDataProvider.PopupTimings.AnyTime,
                    UIAsyncDataProvider.CheckTypes.None,
                    UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable,
                    false, param
                )
                table.insert(popUpProviders, provider)
            end
            table.insert(items, item)
        end
    end
    ---@type UIRewardMediatorParameter
    local param = {}
    param.itemInfo = {}
    for _, itemData in pairs(items) do
        local item = {}
        item.id = itemData.configCell:Id()
        item.count = itemData.count
        table.insert(param.itemInfo, item)
    end
    param.closeCallback = function()
        if Utils.IsNull(self.CSComponent) then return end
        self:UpdateTurnTable({
            updateMask = updateMask,
            isManully = isManully,
            newReceivedGId = newReceivedGId})
    end
    ---@type UIAsyncDataProvider
    local provider = UIAsyncDataProvider.new()
    provider:Init(
        UIMediatorNames.UIRewardMediator,
        UIAsyncDataProvider.PopupTimings.AnyTime,
        UIAsyncDataProvider.CheckTypes.None,
        UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable,
        false, param
    )
    -- provider:SetOtherMediatorCheckType(UIAsyncDataProvider.MediatorTypes.Popup)
    table.insert(popUpProviders, provider)
    g_Game.UIAsyncManager:AddAsyncMediatorsList(popUpProviders, true)
end

return ActivityTurnTable
