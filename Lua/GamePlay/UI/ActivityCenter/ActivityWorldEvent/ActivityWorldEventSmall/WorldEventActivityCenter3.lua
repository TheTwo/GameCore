local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')
local TimerUtility = require('TimerUtility')
local TimeFormatter = require('TimeFormatter')
local ConfigRefer = require('ConfigRefer')
local OpenAllianceExpeditionParameter = require('OpenAllianceExpeditionParameter')
local ReceiveExpeditionPartProgressRewardParameter = require('ReceiveExpeditionPartProgressRewardParameter')
local DBEntityType = require('DBEntityType')
local AllianceExpeditionOpenType = require('AllianceExpeditionOpenType')
local ActivityWorldEventConst = require('ActivityWorldEventConst')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local ProtocolId = require('ProtocolId')
local SearchEntityType = require('SearchEntityType')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local WorldEventDefine = require('WorldEventDefine')
local CommonGotoDetailDefine = require("CommonGotoDetailDefine")
local GuideUtils = require('GuideUtils')
local KingdomMapUtils = require('KingdomMapUtils')
local ObjectType = require('ObjectType')

---@class WorldEventActivityCenter3 : BaseUIComponent
local WorldEventActivityCenter3 = class('WorldEventActivityCenter3', BaseUIComponent)

function WorldEventActivityCenter3:OnCreate()
    self.p_text_time = self:Text('p_text_time')
    -- self.p_text_info = self:Text('p_text_info', I18N.Get("alliance_worldevent_rule"))
    self.p_btn_reward = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnClickDetail))
    self.p_text_count_down = self:Text('p_text_count_down')
    self.p_text_count_down_1 = self:Text('p_text_count_down_1', I18N.Get(":"))
    self.p_text_count_down_2 = self:Text('p_text_count_down_2')
    self.p_text_count_down_3 = self:Text('p_text_count_down_3', I18N.Get(":"))
    self.p_text_count_down_4 = self:Text('p_text_count_down_4')

    self.p_text_title = self:Text('p_text_title', "alliance_activity_pet_01")
    self.p_text_start = self:Text('p_text_start')
    self.p_text_describe = self:Text('p_text_describe', I18N.Get("alliance_activity_pet_03"))
    self.p_text_reward_name = self:Text('p_text_reward_name', "alliance_activity_pet_13")
    self.p_text_pet_desc = self:Text('p_text_pet_desc')

    self.p_icon_item_al_n = self:Image('p_icon_item_al_n')
    self.p_icon_item_al = self:Image('p_icon_item_al')
    self.p_text_n = self:Text('p_text_n', "alliance_activity_pet_04")
    self.p_text = self:Text('p_text', "alliance_activity_pet_05")

    self.p_text_num_green_al_n = self:Text('p_text_num_green_al_n')
    self.p_text_num_wilth_al_n = self:Text('p_text_num_wilth_al_n')

    self.p_text_num_green_al = self:Text('p_text_num_green_al')
    self.p_text_num_wilth_al = self:Text('p_text_num_wilth_al')

    self.p_table_award = self:TableViewPro('p_table_award')
    self.p_text_hint = self:Text('p_text_hint')
    self.p_img_pet = self:Image('p_img_pet')

    self.isFirstOpen = true
    self.vxTrigger = self:AnimTrigger('vx_trigger')

    self.p_btn_n = self:Button('p_btn_n', Delegate.GetOrCreate(self, self.OnBtnClickNormalItem))
    self.p_btn_special = self:Button('p_btn_special', Delegate.GetOrCreate(self, self.OnBtnClickSpecialItem))
    self.p_btn_goto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGoto))

    self.p_btn_hero_detail = self:Button('p_btn_hero_detail', Delegate.GetOrCreate(self, self.OnBtnClickMoreDetails))
    self.p_text_hero_detail = self:Text('p_text_hero_detail', I18N.Get("#MORE DETAILS"))

    self.child_activity_detail = self:LuaObject('child_activity_detail')
    self.p_btn_join = self:Button('p_btn_join', Delegate.GetOrCreate(self, self.OnBtnClickJoinAlliance))
    self.p_text_join = self:Text('p_text_join', 'join_league')
    self.p_text_goto = self:Text('p_text_goto', "goto")
    self.p_text_pet_desc_1 = self:Text('p_text_pet_desc_1', "alliance_activity_pet_23")

    self.reddot_normal = self:LuaObject('child_reddot_default_normal')
    self.reddot_special = self:LuaObject('child_reddot_default_special')

end
function WorldEventActivityCenter3:OnShow()
    if self.isFirstOpen then
        self.isFirstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
end

function WorldEventActivityCenter3:OnHide()
    self:StopTimer()
end

function WorldEventActivityCenter3:OnFeedData(param)
    self.param = param
    local tabCfg = ConfigRefer.ActivityCenterTabs:Find(param.tabId)
    self.cfgId = tabCfg:RefAllianceActivityExpedition(1)
    local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId)
    local expedition = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByConfigID(self.cfgId)
    self.ExpeditionEntityId = expedition and expedition.ExpeditionEntityId or nil
    self.item1 = allianceCfg:UseItems(1)
    self.item2 = allianceCfg:UseItems(2)
    local status
    local expeditionID

    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceInfo then
        -- 大事件可能在没有联盟的时候刷新出来
        expeditionID = allianceCfg:Expeditions(1)
    else
        self.allianceEventInfo = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByConfigID(self.cfgId)
        expeditionID = self.allianceEventInfo and self.allianceEventInfo.ExpeditionConfigId or allianceCfg:Expeditions(1)
    end

    -- 活动总时间
    local eventStartT
    local eventEndT
    self.activityId = allianceCfg:DisplayTime()
    eventStartT, eventEndT = ModuleRefer.WorldEventModule:GetActivityCountDown(self.activityId)

    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local startTimeStr = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(eventStartT, "yyyy/MM/dd HH:mm:ss")
    local endTimeStr = TimeFormatter.TimeToLocalTimeZoneDateTimeStringUseFormat(eventEndT, "yyyy/MM/dd HH:mm:ss")
    self.p_text_time.text = I18N.GetWithParams("alliance_activity_pet_02", startTimeStr .. "~" .. endTimeStr)

    -- 倒计时
    if curT < eventStartT then
        status = ActivityWorldEventConst.EventStatusEnum.Preveiw
        self.p_text_start.text = I18N.Get("activitynotice_text_start")
        self.activityEndTime = eventStartT
    else
        status = ActivityWorldEventConst.EventStatusEnum.Start
        self.p_text_start.text = I18N.Get("alliance_worldevent_end1")
        self.activityEndTime = eventEndT
    end
    self:SetCountDown()
    self:SetCountDownTimer()

    if not allianceInfo then
        self.p_text_hint.text = I18N.Get("alliance_WorldEvent_big_tips")
        self:SetButtons(false)
        self.p_btn_join:SetVisible(true)
    else
        self.p_btn_join:SetVisible(false)
        if curT < eventStartT then
            self.p_text_hint.text = I18N.Get("alliance_activity_pet_18")
            self:SetButtons(false)
        else
            self:SetButtons(true)
        end
    end

    local config = ConfigRefer.WorldExpeditionTemplate:Find(expeditionID)
    local type = allianceCfg:OpenType()
    self.progressType = type
    self.status = status
    self.config = config
    self.expeditionID = expeditionID
    g_Game.SpriteManager:LoadSprite("sp_pet_img_tigrex_l", self.p_img_pet)

    -- 奖励宠物
    local param = {}
    param.type = CommonGotoDetailDefine.TYPE.PET
    param.configId = allianceCfg:RewardPet()
    self.child_activity_detail:FeedData(param)
    self.p_text_pet_desc.text = I18N.Get(ConfigRefer.Pet:Find(param.configId):Name())

    self:SetPreviewReward()
    self:SetItem()
end

function WorldEventActivityCenter3:SetButtons(isShow)
    self.p_text_hint:SetVisible(not isShow)
    self.p_btn_n:SetVisible(isShow)
    self.p_btn_special:SetVisible(isShow)
end

function WorldEventActivityCenter3:SetItem()
    local itemCfg1 = ConfigRefer.Item:Find(self.item1)
    local itemCfg2 = ConfigRefer.Item:Find(self.item2)
    g_Game.SpriteManager:LoadSprite(itemCfg1:Icon(), self.p_icon_item_al_n)
    g_Game.SpriteManager:LoadSprite(itemCfg2:Icon(), self.p_icon_item_al)

    local uid1 = ModuleRefer.InventoryModule:GetUidByConfigId(self.item1)
    local uid2 = ModuleRefer.InventoryModule:GetUidByConfigId(self.item2)
    self.count1 = 0
    self.count2 = 0
    if uid1 then
        self.count1 = ModuleRefer.InventoryModule:GetItemInfoByUid(uid1).Count
    end
    if uid2 then
        self.count2 = ModuleRefer.InventoryModule:GetItemInfoByUid(uid2).Count
    end

    local color = self.count1 > 0 and ColorConsts.army_green or ColorConsts.army_red
    self.p_text_num_green_al_n.color = UIHelper.TryParseHtmlString(color)
    self.p_text_num_green_al_n.text = "1"
    self.p_text_num_wilth_al_n.text = "/" .. self.count1

    color = self.count2 > 0 and ColorConsts.army_green or ColorConsts.army_red
    self.p_text_num_green_al.color = UIHelper.TryParseHtmlString(color)
    self.p_text_num_green_al.text = "1"
    self.p_text_num_wilth_al.text = "/" .. self.count2

    if self.count1 > 0 then
        self.reddot_normal:ShowRedDot()
    else
        self.reddot_normal:HideAllRedDot()
    end

    if self.count2 > 0 then
        self.reddot_special:ShowRedDot()
    else
        self.reddot_special:HideAllRedDot()
    end
end

function WorldEventActivityCenter3:SetPreviewReward()
    self.p_table_award:Clear()
    self.p_table_award:SetVisible(true)

    local cfg = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId)
    for i = 1, cfg:PreviewRewardItemIdsLength() do
        local item = cfg:PreviewRewardItemIds(i)
        local iconData = {}
        iconData.configCell = ConfigRefer.Item:Find(item)
        self.p_table_award:AppendData(iconData)
    end
end

function WorldEventActivityCenter3:CheckAllianceRecord(record, progress)
    if record then
        for k, v in pairs(record.RewardedProgress) do
            if v == progress then
                return true
            end
        end
    end

    return false
end

function WorldEventActivityCenter3:GetPersonalRewardStatus(rewards)
    local stage = 0
    for k, v in pairs(rewards) do
        if v == true then
            stage = stage + 1
        end
    end
    return stage
end

function WorldEventActivityCenter3:SetCountDown()
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local seconds = self.activityEndTime - curT
    seconds = seconds > 0 and seconds or 0
    self.p_text_count_down.text = TimeFormatter.SimpleFormatTimeWithDayHourSeconds(seconds)

    if self.status == ActivityWorldEventConst.EventStatusEnum.Preveiw and seconds == 0 then
        self.status = ActivityWorldEventConst.EventStatusEnum.Start
        self.p_text_start.text = I18N.Get("alliance_worldevent_end1")
        local eventStartT, eventEndT = ModuleRefer.WorldEventModule:GetActivityCountDown(self.activityId)
        self.activityEndTime = eventEndT
    end
end

function WorldEventActivityCenter3:GetCountDown(seconds)
    local int = math.floor(seconds);
    int = int > 0 and int or 0
    local h = int // TimeFormatter.OneHourSeconds;
    int = int - h * TimeFormatter.OneHourSeconds;
    local m = int // TimeFormatter.OneMinuteSeconds;
    local s = int % TimeFormatter.OneMinuteSeconds;
    return h, m, s
end

function WorldEventActivityCenter3:SetCountDownTimer()
    if not self.countdownTimer then
        self.countdownTimer = TimerUtility.IntervalRepeat(function()
            self:SetCountDown()
        end, 1, -1, true)
    end
end

function WorldEventActivityCenter3:StopTimer()
    if self.countdownTimer then
        TimerUtility.StopAndRecycle(self.countdownTimer)
        self.countdownTimer = nil
    end
end

function WorldEventActivityCenter3:OnBtnClickDetail()
    local reward1 = {}
    local reward2 = {}

    local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(self.cfgId)
    local itemGroupCfg = ConfigRefer.ItemGroup:Find(allianceCfg:MonsterPreviewRewards(1))
    if itemGroupCfg then
        for i = 1, itemGroupCfg:ItemGroupInfoListLength() do
            local info = itemGroupCfg:ItemGroupInfoList(i)
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(info:Items())
            iconData.count = info:Nums()
            table.insert(reward1, iconData)
        end
    end

    itemGroupCfg = ConfigRefer.ItemGroup:Find(allianceCfg:MonsterPreviewRewards(2))
    if itemGroupCfg then
        for i = 1, itemGroupCfg:ItemGroupInfoListLength() do
            local info = itemGroupCfg:ItemGroupInfoList(i)
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(info:Items())
            iconData.count = info:Nums()
            table.insert(reward2, iconData)
        end
    end

    local tabCfg = ConfigRefer.ActivityCenterTabs:Find(self.param.tabId)
    local id = tabCfg:RefAllianceActivityExpedition(1)
    local monsterName1, monsterName2 = ModuleRefer.WorldEventModule:GetMonsterNameByAllianceExpeditionId(id)

    local itemName1 = I18N.Get(ConfigRefer.Item:Find(self.item1):NameKey())
    local itemName2 = I18N.Get(ConfigRefer.Item:Find(self.item2):NameKey())

    local content_page1 = {}
    table.insert(content_page1, {title = I18N.Get("alliance_WorldEvent_rule")})
    table.insert(content_page1, {rule = I18N.GetWithParams("alliance_activity_pet_17", itemName1, itemName1, monsterName1, monsterName1, itemName2, itemName2, monsterName2)})
    ---@type CommonPlainTextContent
    local content1 = {list = content_page1}
    
    local content_page2 = {}
    table.insert(content_page2, {rule = I18N.Get("alliance_activity_pet_14")})
    table.insert(content_page2, {reward = reward1})
    table.insert(content_page2, {rule = I18N.Get("alliance_activity_pet_15")})
    table.insert(content_page2, {hint = I18N.GetWithParams("alliance_activity_pet_16", 10)})
    table.insert(content_page2, {reward = reward2})
    ---@type CommonPlainTextContent
    local content2 = {list = content_page2}

    g_Game.UIManager:Open(UIMediatorNames.CommonPlainTextInfoMediator,
                          {tabs = {"sp_chat_icon_copy", "sp_mail_icon_gift"}, contents = {content1, content2}, title = I18N.Get("alliance_WorldEvent_rule")})
end

function WorldEventActivityCenter3:OnBtnClickAccept()
    ---@type CommonConfirmPopupMediatorParameter
    local confirmParameter = {}
    confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    confirmParameter.confirmLabel = I18N.Get("confirm")
    confirmParameter.cancelLabel = I18N.Get("cancle")
    confirmParameter.content = I18N.GetWithParams("alliance_worldevent_open_pop_second", ModuleRefer.AllianceModule:GetMyAllianceOnlineMemberCount())
    confirmParameter.title = I18N.Get("alliance_worldevent_chat_title")
    confirmParameter.onConfirm = function()
        g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
end

function WorldEventActivityCenter3:OnBtnClickJoinAlliance()
    g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
end

function WorldEventActivityCenter3:OnBtnClickRepairAllianceCenter()
    ---@type AllianceTerritoryMainMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainMediator, param)
end

function WorldEventActivityCenter3:OnBtnGoto()
    --- 【【事件】【小事件优化改】小事件活动界面的前往按钮，点击后需要跳转打开雷达，并自动选中一个打怪的雷达事件
    ---  https://www.tapd.cn/31821045/prong/stories/view/1131821045001424491
    local basicCamera = KingdomMapUtils.GetBasicCamera()
    -- basicCamera.ignoreLimit = true
    -- ModuleRefer.RadarModule:SetRadarState(true)
    local isInCity = g_Game.SceneManager.current:IsInCity()
    ---@type RadarMediatorParam
    local param = 
	{
		isInCity = isInCity,
		stack = basicCamera:RecordCurrentCameraStatus(),
		enterSelectBubbleType = ObjectType.SlgMob,
		mustSelectTarget = true,
	}
    g_Game.UIManager:Open(UIMediatorNames.RadarMediator, param)

    -- local isOwn = ModuleRefer.WorldEventModule:GetPersonalOwnAllianceExpedition()
    -- if isOwn then
    --     ModuleRefer.WorldEventModule:GotoUseItemExpedition()
    -- else
    --     -- 前往搜怪
    --     local selectType = SearchEntityType.EliteMob
    --     local searchLevel = ModuleRefer.WorldSearchModule:GetSearchLevel(selectType)
    --     local scene = g_Game.SceneManager.current
    --     if scene:IsInCity() then
    --         local callback = function()
    --             g_Game.UIManager:CloseAllByName(UIMediatorNames.EarthRevivalMediator)
    --             g_Game.UIManager:Open(UIMediatorNames.UIWorldSearchMediator, {selectType = selectType, searchLv = searchLevel})
    --         end
    --         scene:LeaveCity(callback)
    --     else
    --         g_Game.UIManager:CloseAllByName(UIMediatorNames.EarthRevivalMediator)
    --         g_Game.UIManager:Open(UIMediatorNames.UIWorldSearchMediator, {selectType = selectType, searchLv = searchLevel})
    --     end
    -- end
end

function WorldEventActivityCenter3:OnBtnClickNormalItem()
    if self.count1 <= 0 then
        ---@type CommonItemDetailsParameter
        local param = {}
        param.clickTransform = self.p_btn_n.transform
        param.itemId = self.item1
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ModuleRefer.WorldEventModule:ValidateItemUse(self.item1, self.count1)
    end
end

function WorldEventActivityCenter3:OnBtnClickSpecialItem()
    if self.count2 <= 0 then
        ---@type CommonItemDetailsParameter
        local param = {}
        param.clickTransform = self.p_btn_special.transform
        param.itemId = self.item2
        param.itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ModuleRefer.WorldEventModule:ValidateItemUse(self.item2, self.count2)
    end
end

function WorldEventActivityCenter3:OnBtnClickMoreDetails()
end

return WorldEventActivityCenter3
