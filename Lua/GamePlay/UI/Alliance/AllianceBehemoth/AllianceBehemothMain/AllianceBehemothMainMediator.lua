--- scene:scene_league_behemoth_main

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local AllianceBehemothMainOperationProvider = require("AllianceBehemothMainOperationProvider")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local FlexibleMapBuildingType = require("FlexibleMapBuildingType")
local AllianceModuleDefine = require("AllianceModuleDefine")
local NotificationType = require("NotificationType")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceBehemothMainMediator:BaseUIMediator
---@field new fun():AllianceBehemothMainMediator
---@field super BaseUIMediator
local AllianceBehemothMainMediator = class('AllianceBehemothMainMediator', BaseUIMediator)

function AllianceBehemothMainMediator:ctor()
    AllianceBehemothMainMediator.super.ctor(self)
    self._operator = AllianceBehemothMainOperationProvider.new()
end

function AllianceBehemothMainMediator:OnCreate(param)
    self._p_btn_all_brhrmoth = self:Button("p_btn_all_brhrmoth", Delegate.GetOrCreate(self, self.OnClickAll))
    self._p_text_all_behemoth = self:Text("p_text_all_behemoth", "alliance_behemoth_button_list")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_img_control_behemoth = self:GameObject("p_img_control_behemoth")
    self._p_base_bg = self:Image("p_base_bg")
    self._p_turtle_fg = self:Image("p_turtle_fg")
    self._p_lion_fg = self:Image("p_lion_fg")
    self._p_icon_behemoth = self:Image("p_icon_behemoth")
    ---@see AllianceBehemothInfoComponent
    self._p_league_behemoth_info = self:LuaBaseComponent("p_league_behemoth_info")
    self._p_empty = self:GameObject("p_empty")
    self._p_text_empty = self:Text("p_text_empty", "alliance_behemoth_system_vacant")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
    self._p_text_goto = self:Text("p_text_goto", "alliance_behemoth_button_build")
    ---@see CommonBackButtonComponent
    self._child_common_btn_back = self:LuaBaseComponent("child_common_btn_back")
    
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_vx_trigger = self:AnimTrigger("p_vx_trigger")
end

function AllianceBehemothMainMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local backBtnData = {}
    backBtnData.title = I18N.Get("alliance_behemoth_title_name")
    self._child_common_btn_back:FeedData(backBtnData)

    local behemothListNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(AllianceModuleDefine.NotifyNodeType.BehemothListEntry, NotificationType.ALLIANCE_BEHEMOTH_LIST_ENTRY)
    ModuleRefer.NotificationModule:AttachToGameObject(behemothListNode, self._child_reddot_default.go, self._child_reddot_default.redDot)
end

function AllianceBehemothMainMediator:RefreshUI(isEnter)
    local behemoth =  ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
    if behemoth then
        self._p_empty:SetVisible(false)
        self._p_base_bg:SetVisible(true)
        self._p_league_behemoth_info:SetVisible(true)
        self._p_img_control_behemoth:SetVisible(true)
        ---@type AllianceBehemothInfoComponentData
        local data = {}
        data.behemothInfo = behemoth
        data.operationProvider = self._operator
        self._p_league_behemoth_info:FeedData(data)
        self._p_icon_behemoth:SetVisible(true)
        local monster = behemoth:GetRefKMonsterDataConfig(ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel() or 1)
        local _,_,_,_,_,bodyPaint = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(monster)
        g_Game.SpriteManager:LoadSprite(bodyPaint, self._p_icon_behemoth)
        self:LoadSprite(monster:BackgroundImg(), self._p_base_bg)
        local isturtle = behemoth:GetBehemothGroupId() == 1000
        self._p_turtle_fg:SetVisible(isturtle)
        self._p_lion_fg:SetVisible(not isturtle)
        if isEnter then
            if isturtle then
                self._p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
            else
                self._p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
        end
    else
        self._p_empty:SetVisible(true)
        self._p_base_bg:SetVisible(false)
        self._p_league_behemoth_info:SetVisible(false)
        self._p_icon_behemoth:SetVisible(false)
        self._p_img_control_behemoth:SetVisible(false)
        self._p_turtle_fg:SetVisible(false)
        self._p_lion_fg:SetVisible(false)
        if isEnter then
            self._p_vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
        end
    end
end

function AllianceBehemothMainMediator:OnClickAll()
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothListMediator)
end

function AllianceBehemothMainMediator:OnClickGoto()
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.BuildBehemothDevice) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Alliance_no_permission_toast"))
        return
    end
    local toastNoAllianceCenter = false
    local mapBuildings = ModuleRefer.VillageModule:GetAllVillageMapBuildingBrief()
    local allianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId()
    local building = allianceCenter and mapBuildings[allianceCenter]
    if not allianceCenter then
        building = ModuleRefer.VillageModule:GetCurrentEffectiveOrInUpgradingAllianceCenterVillage()
        toastNoAllianceCenter = true
    end
    local targetPosX = nil
    local targetPosY = nil
    if building then
        targetPosX,targetPosY = building.Pos.X,building.Pos.Y
    else
        local p = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
        targetPosX,targetPosY = p.X,p.Y
    end
    self:CloseSelf()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceMainMediator)
    AllianceWarTabHelper.GoToCoord(targetPosX, targetPosY, false, nil, nil, nil, function()
        ---@type KingdomConstructionModeUIMediatorParameter
        local param = {}
        param.chooseTab = 0
        param.chooseType = FlexibleMapBuildingType.BehemothDevice
        g_Game.UIManager:Open(UIMediatorNames.KingdomConstructionModeUIMediator, param)
        if toastNoAllianceCenter then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemothActivity_tips_condition"))
        end
    end)
end

function AllianceBehemothMainMediator:OnShow(param)
    self:RefreshUI(true)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, Delegate.GetOrCreate(self, self.RefreshUI))
end

function AllianceBehemothMainMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, Delegate.GetOrCreate(self, self.RefreshUI))
end

function AllianceBehemothMainMediator:OnLeaveAlliance()
    self:CloseSelf()
end

return AllianceBehemothMainMediator