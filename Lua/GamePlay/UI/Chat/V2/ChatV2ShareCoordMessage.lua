local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ChatShareUtils = require("ChatShareUtils")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local UIMediatorNames = require("UIMediatorNames")
local ChatShareType = require("ChatShareType")

---@class ChatV2ShareCoordMessage:BaseUIComponent
local ChatV2ShareCoordMessage = class('ChatV2ShareCoordMessage', BaseUIComponent)

function ChatV2ShareCoordMessage:OnCreate()
    self._item = self:BindComponent("", typeof(CS.SuperScrollView.LoopListViewItem2))

    self._p_head_left = self:GameObject("p_head_left")
    self._p_text_name_l = self:Text("p_text_name_l")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_l = self:LuaObject("child_ui_head_player_l")
    self._child_ui_head_player_l:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnPortraitClick))
    self._p_head_icon = self:Image("p_head_icon")
    
    self._p_head_right = self:GameObject("p_head_right")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_r = self:LuaObject("child_ui_head_player_r")
    self._p_text_name_r = self:Text("p_text_name_r")

    self._coord = self:GameObject("coord")
    self._p_text_coord = self:Text("p_text_coord")
    self._p_text_coord_num = self:Text("p_text_coord_num")

    self._layout = self:GameObject("layout")
    self._name = self:GameObject("name")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_name_item = self:Text("p_text_name_item")

    self._p_reward = self:GameObject("p_reward")
    self._p_text_reward = self:Text("p_text_reward")

    self._p_item_1 = self:GameObject("p_item_1")
    self._p_item_2 = self:GameObject("p_item_2")
    self._p_item_3 = self:GameObject("p_item_3")
    self._p_items = {self._p_item_1, self._p_item_2, self._p_item_3}

    ---@type BaseItemIcon
    self._child_item_standard_s1 = self:LuaObject("child_item_standard_s1")
    ---@type BaseItemIcon
    self._child_item_standard_s2 = self:LuaObject("child_item_standard_s2")
    ---@type BaseItemIcon
    self._child_item_standard_s3 = self:LuaObject("child_item_standard_s3")
    self._child_item_standards = {self._child_item_standard_s1, self._child_item_standard_s2, self._child_item_standard_s3}

    self._p_text_quantity_1 = self:Text("p_text_quantity_1")
    self._p_text_quantity_2 = self:Text("p_text_quantity_2")
    self._p_text_quantity_3 = self:Text("p_text_quantity_3")
    self._p_text_quantities = {self._p_text_quantity_1, self._p_text_quantity_2, self._p_text_quantity_3}

    self._p_item = self:GameObject("p_item")
    self._p_icon_item_l = self:Image("p_icon_item_l")
    self._p_icon_power_l = self:Image("p_icon_power_l")
    self._p_text_number_l = self:Text("p_text_number_l")

    self._p_icon_coord = self:Image("p_icon_coord")
    self._p_btn_coord = self:Button("p_btn_coord", Delegate.GetOrCreate(self, self.OnClick))
end

---@class ChatV2ShareCoordMessageData
---@field sessionId number
---@field imId number
---@field time number
---@field text string
---@field uid number
---@field extInfo table @json
---@field shareParam ShareChatItemParam

---@param message ChatV2ShareCoordMessageData
function ChatV2ShareCoordMessage:OnFeedData(message)
    self._message = message
    self._isLeft = message.uid ~= ModuleRefer.PlayerModule:GetPlayerId()
    self._p_head_left:SetActive(self._isLeft)
    self._p_head_right:SetActive(not self._isLeft)

    local name = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(self._message.extInfo, self._message.uid)
    if self._isLeft then
        self._p_text_name_l.text = name
    else
        self._p_text_name_r.text = name
    end

    ---@type wds.PortraitInfo
    local portraitInfo = wds.PortraitInfo.New()
    portraitInfo.PlayerPortrait = self._message.extInfo.p
    portraitInfo.PortraitFrameId = self._message.extInfo.fp
    portraitInfo.CustomAvatar = self._message.extInfo.ca and self._message.extInfo.ca or ""
    if self._isLeft then
        self._child_ui_head_player_l:FeedData(portraitInfo)
    else
        self._child_ui_head_player_r:FeedData(portraitInfo)
    end

    self:HideAllShareNode()
    self.param = self._message.shareParam
    self.isActive = true
    if self.param == nil then
        return
    end

    self._coord:SetActive(true)
    if self.param.x and self.param.y then
        self._p_text_coord_num.text = string.format("X:%d Y:%d", self.param.x, self.param.y)
    else
        self._p_text_coord_num.text = ""
    end
    
    self._name:SetActive(true)
    if self.param.level then
        self._p_text_lv.text = string.format("Lv.%d", self.param.level)
    else
        self._p_text_lv.text = ""
    end

    if self.param.name then
        self._p_text_name_item.text = self.param.name
    else
        self._p_text_name_item.text = ""
    end

    local configID = ChatShareUtils.GetConfigIDByType(self.param.type)
    self.shareConfig = ConfigRefer.ChatShare:Find(configID)
    if not string.IsNullOrEmpty(self.param.customPic) then
        self._p_icon_coord:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(self.param.customPic, self._p_icon_coord)
    elseif self.shareConfig and not string.IsNullOrEmpty(self.shareConfig:RightIcon()) then
        self._p_icon_coord:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(self.shareConfig:RightIcon(), self._p_icon_coord)
    end

    if self.shareConfig then
        self._p_text_coord.text = I18N.Get(self.shareConfig:Title())
    else
        self._p_text_coord.text = ""
    end
    if not self.shareConfig then return end

    if self.param.type == ChatShareType.WorldEvent then
        self:UpdateWorldEventCoordShare()
    elseif self.param.type == ChatShareType.ResourceField and self.param.resourceYield then
        self:UpdateResourceFieldCoordShare()
    elseif self.param.type == ChatShareType.SlgMonster and self.param.combatValue then
        self:UpdateSlgMonsterCoordShare()
    elseif self.param.type == ChatShareType.AllianceMark then
        self:UpdateAllianceMarkCoordShare()
    elseif self.param.type == ChatShareType.AllianceTask then
        self:UpdateAllianceTaskCoordShare()
    elseif self.param.type == ChatShareType.SlgBuilding then
        self:UpdateSlgBuildingCoordShare()
    end
end

function ChatV2ShareCoordMessage:HideAllShareNode()
    self._coord:SetActive(false)
    self._layout:SetActive(false)
    self._p_icon_coord:SetVisible(false)
end

function ChatV2ShareCoordMessage:OnClick()
    if not self.isActive then
        if self.shareConfig then
            self:ToastShareTimesUp()
            return
        end
    end

    if self.param.shareTime and self.shareConfig then
        local endTime = self.param.shareTime + self.shareConfig:ExpireTime()
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        if curTime > endTime then
            self:ToastShareTimesUp()
            return
        end
    end

    if not self.param.x or not self.param.y then return end

    if self.param.context and self.param.context.__name == "VillageFastForwardToSelectTroopDelegate" then
        if self.param.context.__isBehemothCage then
            local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
            AllianceWarTabHelper.GoToCoord(self.param.x,self.param.y, true, nil, nil, self.param.context, nil, size, 0)
        else
            AllianceWarTabHelper.GoToCoord(self.param.x,self.param.y, true, nil, nil, self.param.context)
        end
        g_Game.UIManager:CloseByName(UIMediatorNames.ChatV2UIMediator)
        return
    end

    local scene = g_Game.SceneManager.current
    if not scene then return end

    if scene:IsInCity() then
        scene:LeaveCity(Delegate.GetOrCreate(self, self.OnClick))
        return
    end

    g_Game.UIManager:CloseByName(UIMediatorNames.ChatV2UIMediator)
    local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(self.param.x,self.param.y, KingdomMapUtils.GetMapSystem())
	KingdomMapUtils.GetBasicCamera():LookAt(pos, 2)
    KingdomMapUtils.GetBasicCamera():SetSize(KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
end

function ChatV2ShareCoordMessage:ToastShareTimesUp()
    local text = I18N.Get(self.shareConfig:ExpireTips())   
    if not string.IsNullOrEmpty(text) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(self.shareConfig:ExpireTips()))
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("guide_failed"))
    end
end

function ChatV2ShareCoordMessage:UpdateWorldEventCoordShare()
    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(self.param.configID)
    if not eventCfg then
        return
    end
    local itemGroupConfig = ConfigRefer.ItemGroup:Find(eventCfg:FullProgressReward())
    if itemGroupConfig == nil then return end

    self._p_reward:SetActive(true)
    self._p_item:SetActive(false)

    self._p_text_reward:SetVisible(true)
    self._p_text_reward.text = I18N.Get("chat_share_reward_text")
    
    local maxCount = math.min(3, itemGroupConfig:ItemGroupInfoListLength())
    for i = 1, maxCount do
        local itemGroup = itemGroupConfig:ItemGroupInfoList(i)
        self._p_items[i]:SetActive(true)
        self._child_item_standards[i]:FeedData({configCell = ConfigRefer.Item:Find(itemGroup:Items()), showTips = false})
    end
    for i = maxCount + 1, 3 do
        self._p_items[i]:SetActive(false)
    end
end

function ChatV2ShareCoordMessage:UpdateResourceFieldCoordShare()
    self._p_reward:SetActive(false)
    self._p_item:SetActive(true)
    self._p_icon_item_l:SetVisible(true)
    self._p_icon_power_l:SetVisible(false)

    local resourceCfg = ConfigRefer.FixedMapBuilding:Find(self.param.configID)
    if not resourceCfg then return end
    local outputItemCfg = ConfigRefer.Item:Find(resourceCfg:OutputResourceItem())
    if not outputItemCfg then return end
    
    g_Game.SpriteManager:LoadSprite(outputItemCfg:Icon(), self._p_icon_item_l)
    self._p_text_number_l.text = string.format("+%d/h", self.param.resourceYield)
end

function ChatV2ShareCoordMessage:UpdateSlgMonsterCoordShare()
    self._p_reward:SetActive(false)
    self._p_item:SetActive(true)
    self._p_icon_item_l:SetVisible(false)
    self._p_icon_power_l:SetVisible(true)

    self._p_text_number_l.text = string.format("%d", self.param.combatValue)
    g_Game.SpriteManager:LoadSprite(self.shareConfig:LeftIcon(), self._p_icon_power_l)
end

function ChatV2ShareCoordMessage:UpdateAllianceMarkCoordShare()
    self._p_reward:SetActive(false)
    self._p_item:SetActive(true)
    
    self._p_icon_item_l:SetVisible(false)
    self._p_icon_power_l:SetVisible(false)

    self._p_text_number_l.text = self.param.shareDesc
end

function ChatV2ShareCoordMessage:UpdateAllianceTaskCoordShare()
    self._p_icon_coord:SetVisible(false)
end

function ChatV2ShareCoordMessage:UpdateSlgBuildingCoordShare()
    local showItem = type(self.param.shareDesc) == "number"
    self._p_reward:SetActive(false)
    self._p_item:SetActive(showItem)
    self._p_icon_item_l:SetVisible(false)
    self._p_icon_power_l:SetVisible(false)

    if showItem then
        self._p_text_number_l.text = I18N.GetWithParams("village_outpost_info_under_construction_2", self.param.shareDesc) .. "%"
    end
end

function ChatV2ShareCoordMessage:OnPortraitClick()
    ModuleRefer.PlayerModule:ShowPlayerInfoPanel(self._message.uid, self._child_ui_head_player_l.CSComponent.gameObject)
end

return ChatV2ShareCoordMessage