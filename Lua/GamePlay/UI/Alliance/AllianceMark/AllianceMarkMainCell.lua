local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceWarTabHelper  = require("AllianceWarTabHelper")
local UIHelper = require("UIHelper")
local DBEntityType = require("DBEntityType")
local AllianceMapLabelType = require("AllianceMapLabelType")
local TimeFormatter = require("TimeFormatter")
local BattleSignalConfig = require("BattleSignalConfig")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local ArtResourceUtils = require("ArtResourceUtils")
local ChatShareUtils = require("ChatShareUtils")
local ChatShareType = require("ChatShareType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceMarkMainCellData
---@field id number
---@field serverData wds.AllianceMapLabel
---@field index number

---@class AllianceMarkMainCell:BaseTableViewProCell
---@field new fun():AllianceMarkMainCell
---@field super BaseTableViewProCell
local AllianceMarkMainCell = class('AllianceMarkMainCell', BaseTableViewProCell)

function AllianceMarkMainCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._eventsAdd = false
    self._useTick = false
end

function AllianceMarkMainCell:OnCreate(param)
    self._p_icon = self:Image("p_icon")
    self._p_text_name = self:Text("p_text_name")
    --self._p_text_number = self:Text("p_text_number")
    self._p_text_content = self:Text("p_text_content")
    self._p_text_position = self:Text("p_text_position")
    self._p_btn_share = self:Button("p_btn_share", Delegate.GetOrCreate(self, self.OnClickBtnShare))
    self._p_btn_mark = self:Button("p_btn_mark", Delegate.GetOrCreate(self, self.OnClickBtnEdit))
    self._p_btn_delete = self:Button("p_btn_delete", Delegate.GetOrCreate(self, self.OnClickBtnDelete))
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickBtnGoto))
    self._p_text = self:Text("p_text", "alliance_bj_qianwang")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
end

---@param data AllianceMarkMainCellData
function AllianceMarkMainCell:OnFeedData(data)
    self._data = data
    local canEdit = ModuleRefer.AllianceModule:HasAuthorityAllianceMapLabel() and data.serverData.Type ~= AllianceMapLabelType.ConveneCenter
    self._p_btn_mark:SetVisible(canEdit)
    self._p_btn_delete:SetVisible(canEdit)
    self._p_btn_share:SetVisible(self:IsCanShowShare())
    local config = ConfigRefer.AllianceMapLabel:Find(data.serverData.ConfigId)
    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(config and config:Icon()), self._p_icon)
    self:RefreshDynamicInfo()
    self:SetupNotify(true)
    self:SetupEvents(true)
    local mediator = self:GetParentBaseUIMediator()
    if not mediator then
        return
    end
    local func = mediator.MarkToCancelRedDot
    if func then
        func(mediator, self._data.id)
    end
end

function AllianceMarkMainCell:OnRecycle(data)
    self:SetupNotify(false)
    self:SetupEvents(false)
    if not self._data then
        return
    end
end

function AllianceMarkMainCell:OnClose(param)
    self:SetupNotify(false)
    self:SetupEvents(false)
end

function AllianceMarkMainCell:OnClickBtnShare()
    local dbType = ChatShareType.AllianceMark
    local markCfgId = self._data.serverData.ConfigId
    local shareContent = ModuleRefer.AllianceModule.BuildContentInfo(self._data.serverData)
    ---@type ShareChannelChooseParam
    local param = {type = dbType, configID = markCfgId, payload = {name = self._data.serverData.SourceName, content = shareContent}}
    param.x, param.y = self._data.serverData.X,self._data.serverData.Y
    param.blockPrivateChannel = true
    param.blockWorldChannel = true
    g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
end

function AllianceMarkMainCell:OnClickBtnEdit()
    ---@type UIBattleSignalPopupMediatorModifyParameter
    local modifyParameter = {}
    modifyParameter.id = self._data.id
    modifyParameter.label = self._data.serverData
    modifyParameter.fromMediatorId = self:GetParentBaseUIMediator():GetRuntimeId()
    g_Game.UIManager:Open(UIMediatorNames.UIBattleSignalPopupMediator, modifyParameter)
end

function AllianceMarkMainCell:OnClickBtnDelete()
    if not self._data then
        return
    end
    local id = self._data.id
    ---@type CommonConfirmPopupMediatorParameter
    local parameter = {}
    parameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    parameter.content = I18N.Get("alliance_bj_quedingshanchu")
    parameter.confirmLabel = I18N.Get("confirm")
    parameter.cancelLabel = I18N.Get("cancle")
    parameter.onConfirm = function()
        ModuleRefer.SlgModule:RemoveSignal(id)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, parameter)
end

function AllianceMarkMainCell:OnClickBtnGoto()
    if not self._data then
        return
    end
    local x = self._data.serverData.X
    local y = self._data.serverData.Y
    if x <= 0 or y <= 0 then
        return
    end
    AllianceWarTabHelper.GoToCoord(x, y)
    g_Game.UIManager:UIMediatorCloseSelfByName(UIMediatorNames.AllianceMainMediator)
    self:GetParentBaseUIMediator():CloseSelf()
end

function AllianceMarkMainCell:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    end
end

function AllianceMarkMainCell:Tick(dt)
    if not self._useTick then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local serverData = self._data.serverData
    if serverData.Type == AllianceMapLabelType.Construct then
        local leftTime = serverData.DynamicParam.ConstructEndTime.ServerSecond - nowTime
        if leftTime > 0 then
            self._p_text_content.text = I18N.GetWithParams("alliance_bj_jianzaozhong", TimeFormatter.SimpleFormatTime(leftTime))
        else
            self._useTick = false
            self._p_text_position:SetVisible(true)
            self._p_text_content.text = string.Empty
        end
    end
end

function AllianceMarkMainCell:SetupNotify(add)
    local redDot = self._child_reddot_default
    local node = ModuleRefer.AllianceModule:GetLabelUnReadNotify(self._data.id)
    local notificationModule = ModuleRefer.NotificationModule
    if node and add then
        redDot:SetVisible(true)
        notificationModule:AttachToGameObject(node, redDot.go, redDot.redDot)
    else
        notificationModule:RemoveFromGameObject(redDot.go, false)
        redDot:SetVisible(false)
    end
end

function AllianceMarkMainCell:RefreshDynamicInfo()
    self._useTick = false
    local serverData = self._data.serverData
    self._p_text_content.text = serverData.SourceName
    local content = ModuleRefer.AllianceModule.BuildContentInfo(serverData)
    self._p_text_name.text = content
    self:Tick(0)
end

function AllianceMarkMainCell:SetupBuilding()
    local serverData = self._data.serverData
    local typeHash = serverData.TargetTypeHash
    if BattleSignalConfig.FixedMapBuildingType[typeHash] then
        local config = ConfigRefer.FixedMapBuilding:Find(serverData.TargetConfigId)
        self._p_text_name.text = config and ("Lv.%d %s"):format(config:Level(), I18N.Get(config:Name()) ) or string.Empty
    elseif BattleSignalConfig.FlexibleMapBuildingType[typeHash] then
        local config = ConfigRefer.FlexibleMapBuilding:Find(serverData.TargetConfigId)
        self._p_text_name.text = config and ("Lv.%d %s"):format(config:Level(), I18N.Get(config:Name())) or string.Empty
    elseif typeHash == DBEntityType.CastleBrief then
        self:SetupPlayer()
    end
end

function AllianceMarkMainCell:SetupMapMob()
    local serverData = self._data.serverData
    local name,_,level,_ = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfigId(serverData.TargetConfigId)
    self._p_text_name.text = ("Lv.%d %s"):format(level, name)
end

function AllianceMarkMainCell:SetupPlayer()
    local serverData = self._data.serverData
    local dynamicData = serverData.DynamicParam
    if string.IsNullOrEmpty(dynamicData.TargetAllianceName) then
        self._p_text_name.text = dynamicData.TargetName
    else
        self._p_text_name.text = ("[%s]%s"):format(dynamicData.TargetAllianceName, dynamicData.TargetName)
    end
end

function AllianceMarkMainCell:IsCanShowShare()
    if not self._data or not self._data.serverData then
        return false
    end
    local typeHash = self._data.serverData.TargetTypeHash
    return typeHash ~= nil
end

return AllianceMarkMainCell