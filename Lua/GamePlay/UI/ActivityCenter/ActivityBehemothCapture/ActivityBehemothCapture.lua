local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local ActivityBehemothConst = require("ActivityBehemothConst")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local RewardHelper = require("RewardHelper")
local ItemTableMergeHelper = require("ItemTableMergeHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local UIMediatorNames = require("UIMediatorNames")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local TimerUtility = require("TimerUtility")
local EarthRevivalDefine = require("EarthRevivalDefine")
local ActivityCenterConst = require("ActivityCenterConst")
local KingdomMapUtils = require("KingdomMapUtils")
local TimeFormatter = require("TimeFormatter")

---@class ActivityBehemothCapture : BaseUIComponent
local ActivityBehemothCapture = class("ActivityBehemothCapture", BaseUIComponent)

local I18N_KEY = ActivityBehemothConst.I18N_KEY

local BTN_STATE = {
    DEVICE_NOT_BUILT = 1,
    DEVICE_BUILT = 2,
    BEHEMOTH_LOCKED = 3,
    BEHEMOTH_TIME_NOT_REACHED = 4,
    BEHEMOTH_AVAILABLE = 5,
    NOT_IN_ALLIANCE = 6,
    BUILD_REWARD_NOT_RECEIVED = 7,
    NOT_IN_WAR = 8,
    BEHEMOTH_OCCUPIED = 9,
}

local UI_UPDATE_MASK = {
    BTN = 1 << 0,
    BOTTOM = 1 << 1,
    INFO = 1 << 2,
    ALL = 0xFFFFFFFF,
}

function ActivityBehemothCapture:OnCreate()
    self.textDesc = self:Text("p_text_desc")
    self.textTitle = self:Text("p_text_title")
    self.btnInfo = self:Button("p_btn_info", Delegate.GetOrCreate(self, self.OnBtnInfoClick))
    self.goImgBehemoth = self:GameObject("p_icon_behemoth")
    self.imgBehemoth = self:Image("p_icon_behemoth")
    self.goImgDevice = self:GameObject("p_icon_device")
    self.imgDevice = self:Image("p_icon_device")
    self.textLabelReward = self:Text("p_text_subtitle", I18N_KEY.LABEL_REWARD)
    self.goRewardBase = self:GameObject("p_reward_base")
    self.tableReward = self:TableViewPro("p_table_award")
    self.btnGoto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnBtnGotoClick))
    self.textGoto = self:Text("p_text_goto")
    self.btnCheck = self:Button("p_btn_check", Delegate.GetOrCreate(self, self.OnBtnCheckClick))
    self.textCheck = self:Text("p_text_chek")
    self.gobtnState = self:GameObject("p_state")
    self.imgIconState = self:Image("p_icon_state")
    self.textState = self:Text("p_text_states")
    self.stextDeviceDesc = self:Text("p_text_device_desc", I18N_KEY.DESC_DEVICE_BUILT)
    self.tableState = self:TableViewPro("p_table")
    self.luaTimer = self:LuaObject("child_time")

    self.goDevice = self:GameObject("p_icon_device")
    self.goLion = self:GameObject("child_behemoth_lion")
    self.goTurtle = self:GameObject("child_behemoth_turtle")

    -- self.imgBackground = self:Image("p_base_bg")
    -- self.goImgTurtleFg = self:GameObject("p_turtle_fg")
    -- self.goImgLionFg = self:GameObject("p_lion_fg")

    -- self.goImgTurtleCloud = self:GameObject("p_tuetle_cloud")
    -- self.goImgLionCloud = self:GameObject("p_lion_cloud")

    self.goNotBuilt = self:GameObject("p_not_built")
    self.stextNotBuilt = self:Text("p_text_not_built", I18N_KEY.DEVICE_NOT_BUILT)

    -- self.imgSwitchCtrler = {
    --     [2] = {
    --         fg = self.goImgTurtleFg,
    --         cloud = self.goImgTurtleCloud,
    --     },
    --     [3] = {
    --         fg = self.goImgLionFg,
    --         cloud = self.goImgLionCloud,
    --     },
    -- }
    self.bgCtrler = {
        [1] = self.goTurtle,
        [2] = self.goLion,
    }

    self.btnStateCtrler = {
        [BTN_STATE.DEVICE_NOT_BUILT] = {
            go = self.btnCheck.gameObject,
            text = self.textCheck,
            i18n = I18N_KEY.BTN_NOT_BUILT,
            showTips = false,
            timer = false,
            tips_i18n = nil
        },
        [BTN_STATE.DEVICE_BUILT] = {
            go = self.stextDeviceDesc.gameObject,
            text = self.stextDeviceDesc,
            i18n = I18N_KEY.DESC_DEVICE_BUILT,
            showTips = false,
            timer = false,
            tips_i18n = nil
        },
        [BTN_STATE.BEHEMOTH_LOCKED] = {
            go = self.btnCheck.gameObject,
            text = self.textCheck,
            i18n = I18N_KEY.BTN_LOCKED,
            showTips = true,
            timer = false,
            tips_i18n = I18N_KEY.TIPS_LOCKED,
        },
        [BTN_STATE.BEHEMOTH_TIME_NOT_REACHED] = {
            go = self.btnGoto.gameObject,
            text = self.textGoto,
            i18n = I18N_KEY.BTN_GOTO,
            showTips = true,
            timer = true,
            tips_i18n = I18N_KEY.TIPS_TIME_NOT_REACHED,
        },
        [BTN_STATE.BEHEMOTH_AVAILABLE] = {
            go = self.btnGoto.gameObject,
            text = self.textGoto,
            i18n = I18N_KEY.BTN_GOTO,
            showTips = true,
            timer = true,
            tips_i18n = I18N_KEY.TIPS_AVAILABLE,
        },
        [BTN_STATE.NOT_IN_ALLIANCE] = {
            go = self.btnCheck.gameObject,
            text = self.textCheck,
            i18n = 'alliance_behemothactivity_tips_enteralliance',
            showTips = false,
            timer = false,
            tips_i18n = '',
        },
        [BTN_STATE.BUILD_REWARD_NOT_RECEIVED] = {
            go = self.btnGoto.gameObject,
            text = self.textGoto,
            i18n = I18N_KEY.CLAIM_REWARD,
            showTips = false,
            timer = false,
            tips_i18n = I18N_KEY.TIPS_AVAILABLE,
        },
        [BTN_STATE.NOT_IN_WAR] = {
            go = self.btnGoto.gameObject,
            text = self.textGoto,
            i18n = I18N_KEY.BTN_GOTO,
            showTips = false,
            timer = false,
            tips_i18n = '',
        },
        [BTN_STATE.BEHEMOTH_OCCUPIED] = {
            go = self.btnCheck.gameObject,
            text = self.textCheck,
            i18n = I18N_KEY.BTN_LOCKED,
            showTips = true,
            timer = false,
            tips_i18n = I18N_KEY.DESC_CAGE_OCCUPIED,
            color = ""
        },
    }
    self.isFirstOpen = true
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function ActivityBehemothCapture:OnFeedData()
    self:PrepareBottomCellData()
    self:UpdateUI(UI_UPDATE_MASK.BOTTOM)
    self:OnBehemothCellSelect(1)
end

function ActivityBehemothCapture:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    g_Game.EventManager:AddListener(EventConst.ON_ACTIVITY_BEHEMOTH_CELL_SELECT, Delegate.GetOrCreate(self, self.OnBehemothCellSelect))
end

function ActivityBehemothCapture:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ON_ACTIVITY_BEHEMOTH_CELL_SELECT, Delegate.GetOrCreate(self, self.OnBehemothCellSelect))
    if self.delayUpdateBtnTimer then
        TimerUtility.StopAndRecycle(self.delayUpdateBtnTimer)
        self.delayUpdateBtnTimer = nil
    end
end

---@param index number
function ActivityBehemothCapture:OnBehemothCellSelect(index)
    self.selectedCellParamIndex = index
    self.selectedCellParam = self.bottomCellDatas[index]
    self:UpdateUI(UI_UPDATE_MASK.BTN | UI_UPDATE_MASK.INFO)
end

function ActivityBehemothCapture:OnBtnGotoClick()
    local curBtnState = self:GetCurBtnState()
    if curBtnState == BTN_STATE.BEHEMOTH_AVAILABLE or curBtnState == BTN_STATE.BEHEMOTH_TIME_NOT_REACHED or
    curBtnState == BTN_STATE.NOT_IN_WAR then
        self:GotoBehemothCage()
    elseif curBtnState == BTN_STATE.BUILD_REWARD_NOT_RECEIVED then
        ModuleRefer.ActivityBehemothModule:ClaimFirstBuildReward(self.btnGoto.transform, function ()
            self:UpdateUI()
            ModuleRefer.ActivityCenterModule:UpdateRedDotByTabId(ActivityCenterConst.BehemothNest)
        end)
    end
end

function ActivityBehemothCapture:OnBtnCheckClick()
    local curBtnState = self:GetCurBtnState()
    if curBtnState == BTN_STATE.BEHEMOTH_LOCKED then
        self:GotoBehemothCage()
    elseif curBtnState == BTN_STATE.NOT_IN_ALLIANCE then
        g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
    elseif curBtnState == BTN_STATE.DEVICE_NOT_BUILT then
        ---@type AllianceTerritoryMainMediatorParameter
        local data = {}
        data.entryTab = 3
        data.entryFactionTypes = {FlexibleMapBuildingType.BehemothDevice}
        g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainMediator, data)
    elseif curBtnState == BTN_STATE.BEHEMOTH_OCCUPIED then
        local cageCfgId = self.selectedCellParam.beheMothCageCfg:Id()
        local x, y = ModuleRefer.ActivityBehemothModule:GetMyAllianceOwnedCagePos(cageCfgId)
        self:GetParentBaseUIMediator():CloseSelf()
        local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
        AllianceWarTabHelper.GoToCoord(x, y, nil, nil, nil, nil, nil, size, 0)
    end
end

function ActivityBehemothCapture:OnBtnInfoClick()
    ---@type TextToastMediatorParameter
    local data = {}
    data.clickTransform = self.btnInfo.transform
    data.content = I18N.Get(I18N_KEY.TIPS_INFO)
    ModuleRefer.ToastModule:ShowTextToast(data)
end

function ActivityBehemothCapture:GotoBehemothCage()
    local cageCfgId = self.selectedCellParam.beheMothCageCfg:Id()
    local pos = ModuleRefer.ActivityBehemothModule:GetNearestBehemothCagePosByBehemothCageCfgId(cageCfgId, true)
    if not pos or pos == CS.UnityEngine.Vector3.zero then
        pos = ModuleRefer.ActivityBehemothModule:GetNearestBehemothCagePosByBehemothCageCfgId(cageCfgId, false)
    end
    if not pos or pos == CS.UnityEngine.Vector3.zero then
        g_Logger.ErrorChannel("ActivityBehemothCapture", "Behemoth cage position not found, fixedMapBuildingCfgId = %d", cageCfgId)
        return
    end
    self:GetParentBaseUIMediator():CloseSelf()
    local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
    AllianceWarTabHelper.GoToCoord(pos.x, pos.y, nil, nil, nil, nil, nil, size, 0)
end

function ActivityBehemothCapture:UpdateUI(mask)
    if not mask then mask = UI_UPDATE_MASK.ALL end
    if mask & UI_UPDATE_MASK.BOTTOM ~= 0 then
        self:UpdateBottom()
    end
    if mask & UI_UPDATE_MASK.BTN ~= 0 then
        self:UpdateBtns()
    end
    if mask & UI_UPDATE_MASK.INFO ~= 0 then
        self:UpdateInfo()
    end
end

function ActivityBehemothCapture:UpdateBtns()
    for _, v in pairs(self.btnStateCtrler) do
        v.go:SetActive(false)
    end
    local curBtnState = self:GetCurBtnState()
    local ctrler = self.btnStateCtrler[curBtnState]
    self.imgIconState.gameObject:SetActive(curBtnState == BTN_STATE.BEHEMOTH_AVAILABLE)
    self.gobtnState:SetActive(ctrler.showTips)
    ctrler.go:SetActive(true)
    ctrler.text.text = I18N.Get(ctrler.i18n)
    if ctrler.showTips then
        if ctrler.timer then
            ctrler.text.text = I18N.Get(ctrler.i18n)
            self.luaTimer:SetVisible(true)
            ---@type CommonTimerData
            local timerData = {}
            timerData.endTime = ModuleRefer.ActivityBehemothModule:GetBehemothCageExpectedTime()
            timerData.needTimer = true
            timerData.callBack = function ()
                self.delayUpdateBtnTimer = TimerUtility.DelayExecute(function ()
                    self:UpdateUI(UI_UPDATE_MASK.BTN)
                end, 1)
            end
            self.luaTimer:FeedData(timerData)
        else
            self.luaTimer:SetVisible(false)
        end
        self.textState.text = I18N.Get(ctrler.tips_i18n)
        if curBtnState == BTN_STATE.BEHEMOTH_LOCKED then
            local sysId = self.selectedCellParam.beheMothCageCfg:AttackSystemSwitch()
            self.textState.text = ModuleRefer.AllianceModule.Behemoth:GetBehemothUnLockedTips(sysId)
        end
    end
end

function ActivityBehemothCapture:UpdateBottom()
    self:PrepareBottomCellData()
    self.tableState:Clear()
    for i, v in ipairs(self.bottomCellDatas) do
        v.isSelect = i == self.selectedCellParamIndex
        v.index = i
        self.tableState:AppendData(v)
    end
    -- 2024-04-06 隐藏建筑部分 --bug=1207984 --user=胡一帆2 【编队】隐藏建筑部分 https://www.tapd.cn/31821045/s/6511728
    self.goNotBuilt:SetActive(false)--not ModuleRefer.ActivityBehemothModule:IsDeviceEverBuilt())
end

function ActivityBehemothCapture:PrepareBottomCellData()
    ---@type ActivityBehemothCaptureBottomCellParam[]
    self.bottomCellDatas = {}
    -- 2024-04-06 隐藏建筑部分 --bug=1207984 --user=胡一帆2 【编队】隐藏建筑部分 https://www.tapd.cn/31821045/s/6511728
    -- ---@type ActivityBehemothCaptureBottomCellParam
    -- local deviceCellData = {}
    -- deviceCellData.type = ActivityBehemothConst.BOTTOM_CELL_TYPE.DEVICE
    -- deviceCellData.isDeviceBuilt = ModuleRefer.ActivityBehemothModule:IsDeviceEverBuilt()
    -- deviceCellData.showProgress = true
    -- if deviceCellData.isDeviceBuilt then
    --     deviceCellData.progress = 1
    -- else
    --     deviceCellData.progress = 0
    -- end
    -- table.insert(self.bottomCellDatas, deviceCellData)
    ---@type ActivityBehemothCaptureBottomCellParam[]
    local behemothCellDatas = {}
    local behemothCageCfgs = ModuleRefer.ActivityBehemothModule:GetBehemothCageCfgs()
    ---@type number, FixedMapBuildingConfigCell
    for i, v in ipairs(behemothCageCfgs) do
        if not ModuleRefer.ActivityBehemothModule:IsCageDeployed(v:Id()) then
            goto continue
        end
        ---@type ActivityBehemothCaptureBottomCellParam
        local behemothCellData = {}
        behemothCellData.type = ActivityBehemothConst.BOTTOM_CELL_TYPE.BEHEMOTH
        behemothCellData.isLocked = not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(v:AttackSystemSwitch())
        behemothCellData.beheMothCfg = ModuleRefer.ActivityBehemothModule:GetWildBehemothCfgByFixedMapBuildingCfgId(v:Id())
        behemothCellData.beheMothCageCfg = v
        behemothCellData.bgIndex = i
        behemothCellData.isOccupied = ModuleRefer.ActivityBehemothModule:IsOwnCageType(v:Id())
        if behemothCellData.beheMothCfg then
            table.insert(behemothCellDatas, behemothCellData)
        end
        ::continue::
    end
    for i, v in ipairs(behemothCellDatas) do
        if v.isLocked or not v.isDeviceBuilt then
            v.progress = 0
        else
            v.progress = 1
        end
        v.showProgress = i < #behemothCellDatas
        table.insert(self.bottomCellDatas, v)
    end
    if not self.selectedCellParamIndex then
        for i, v in ipairs(self.bottomCellDatas) do
            if v.type == ActivityBehemothConst.BOTTOM_CELL_TYPE.DEVICE then
                self.selectedCellParamIndex = i
            elseif v.type == ActivityBehemothConst.BOTTOM_CELL_TYPE.BEHEMOTH then
                if not v.isLocked then --and ModuleRefer.ActivityBehemothModule:IsDeviceEverBuilt() then
                    self.selectedCellParamIndex = i
                end
            end
        end
        self.selectedCellParam = self.bottomCellDatas[self.selectedCellParamIndex]
    end
end

function ActivityBehemothCapture:UpdateInfo()
    local type = self.selectedCellParam.type
    self.goImgDevice:SetActive(type == ActivityBehemothConst.BOTTOM_CELL_TYPE.DEVICE)
    self.goImgBehemoth:SetActive(type == ActivityBehemothConst.BOTTOM_CELL_TYPE.BEHEMOTH)
    local titleKey = ActivityBehemothConst.TITLE_I18N_KEY[type]
    local descKey = ActivityBehemothConst.DESC_I18N_KEY[type]
    if type == ActivityBehemothConst.BOTTOM_CELL_TYPE.DEVICE then
        local deviceCfg = ModuleRefer.ActivityBehemothModule:GetBehemothDeviceCfgs()[1]
        self.textTitle.text = I18N.Get(titleKey)
        self.textDesc.text = I18N.Get(descKey)
        self.textLabelReward.text = I18N.Get(I18N_KEY.LABEL_REWARD_DEVICE)
        local behemothDeviceCfg = ConfigRefer.BehemothDevice:Find(deviceCfg:BehemothDeviceConfig())
        local rewardId = behemothDeviceCfg:FirstBuildReward()
        local rewardList = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardId)
        self.tableReward:Clear()
        for _, v in pairs(rewardList) do
            v.showCount = true
            v.received = ModuleRefer.ActivityBehemothModule:IsDeviceBuildRewardClaimed()
            self.tableReward:AppendData(v)
        end
        self.goImgDevice:SetActive(true)
        for _, v in pairs(self.bgCtrler) do
            v:SetActive(false)
        end
    elseif type == ActivityBehemothConst.BOTTOM_CELL_TYPE.BEHEMOTH then
        self.textTitle.text = I18N.GetWithParams(titleKey, I18N.Get(self.selectedCellParam.beheMothCfg:Name()))
        self.textDesc.text = I18N.Get(descKey)
        self.textLabelReward.text = I18N.Get(I18N_KEY.LABEL_REWARD)
        local _, _, _, _, _, icon = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(self.selectedCellParam.beheMothCfg)
        g_Game.SpriteManager:LoadSprite(icon, self.imgBehemoth)

        self.tableReward:Clear()
        local dmgRankRewardId = self.selectedCellParam.beheMothCageCfg:FirstOccupyDamageRankReward()
        local desRankRewardId = self.selectedCellParam.beheMothCageCfg:FirstOccupyDestroyRankReward()
        local dmgRankRewards = RewardHelper.GetRankRewardInItemIconDatas(dmgRankRewardId)
        local desRankRewards = RewardHelper.GetRankRewardInItemIconDatas(desRankRewardId)
        ---@type ItemIconData[]
        local totalRewards = {}
        for _, v in pairs(dmgRankRewards) do
            for _, itemIconData in pairs(v) do
                table.insert(totalRewards, itemIconData)
            end
        end
        for _, v in pairs(desRankRewards) do
            for _, itemIconData in pairs(v) do
                table.insert(totalRewards, itemIconData)
            end
        end
        local mergedRewards = ItemTableMergeHelper.MergeItemDataByItemCfgId(totalRewards)
        for _, v in pairs(mergedRewards) do
            v.showCount = false
            self.tableReward:AppendData(v)
        end
        for k, v in pairs(self.bgCtrler) do
            v:SetActive(self.selectedCellParam.bgIndex == k)
        end
    end
end

function ActivityBehemothCapture:GetCurBtnState()
    if self.selectedCellParam.type == ActivityBehemothConst.BOTTOM_CELL_TYPE.DEVICE then
        if ModuleRefer.ActivityBehemothModule:IsDeviceBuildRewardCanClaim() then
            return BTN_STATE.BUILD_REWARD_NOT_RECEIVED
        elseif not ModuleRefer.AllianceModule:IsInAlliance() then
            return BTN_STATE.NOT_IN_ALLIANCE
        elseif self.selectedCellParam.isDeviceBuilt then
            return BTN_STATE.DEVICE_BUILT
        else
            return BTN_STATE.DEVICE_NOT_BUILT
        end
    elseif self.selectedCellParam.type == ActivityBehemothConst.BOTTOM_CELL_TYPE.BEHEMOTH then
        if self.selectedCellParam.isLocked then
            return BTN_STATE.BEHEMOTH_LOCKED
        elseif ModuleRefer.ActivityBehemothModule:IsOwnCageType(self.selectedCellParam.beheMothCageCfg:Id()) then
            return BTN_STATE.BEHEMOTH_OCCUPIED
        elseif not ModuleRefer.VillageModule:HasAnyDeclareWarOnCage() then
            return BTN_STATE.NOT_IN_WAR
        else
            local _, warInfo = next(ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar())
            if warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
                return BTN_STATE.BEHEMOTH_TIME_NOT_REACHED
            else
                return BTN_STATE.BEHEMOTH_AVAILABLE
            end
        end
    end
end

function ActivityBehemothCapture:GetTimeStr()
    return "00:00:00"
end

return ActivityBehemothCapture