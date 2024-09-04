---scene:scene_league_popup_addmark

local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local DBEntityType = require("DBEntityType")
local UIHelper = require("UIHelper")
local AllianceMapLabelType = require("AllianceMapLabelType")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local BattleSignalConfig = require("BattleSignalConfig")
local ArtResourceUtils = require("ArtResourceUtils")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local ChatShareType = require("ChatShareType")

---@class UIBattleSignalPopupMediatorParameter
---@field tile MapRetrieveResult
---@field troopId number
---@field entity wds.MapMob|wds.Troop
---@field name string
---@field abbr string
---@field frame number

---@class UIBattleSignalPopupMediatorModifyParameter
---@field id number
---@field label wds.AllianceMapLabel
---@field fromMediatorId number

---@class UIBattleSignalPopupMediator : BaseUIMediator
local UIBattleSignalPopupMediator = class('UIBattleSignalPopupMediator', BaseUIMediator)

function UIBattleSignalPopupMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type UIBattleSignalPopupMediatorParameter
    self._addSignalData = nil
    ---@type UIBattleSignalPopupMediatorModifyParameter
    self._modifySignalData = nil
    self._isEditMode = false
    self._parameter = nil
    ---@type AllianceMapLabelConfigCell
    self._selectedType = nil
    self._contentString = string.Empty
    self._maxContentLength = 40
    self._selectTab = nil
    ---@type UIBattleSignalTableCellData[]
    self._tableData = {}
    self._fromMediatorId = nil
end

function UIBattleSignalPopupMediator:OnCreate()    
    ---@see CommonPopupBackComponent
    self._child_popup_base_s = self:LuaBaseComponent('child_popup_base_s')
    
    self._p_img_building = self:Image("p_img_building")
    self._p_player = self:GameObject("p_player")
    self._p_img_boss = self:Image("p_img_boss")
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_lv = self:GameObject("p_lv")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_position_num = self:Text("p_text_position_num")
    self._p_click_position = self:Button("p_click_position", Delegate.GetOrCreate(self, self.OnClickGoto))
    
    self._p_btn_a = self:Button("p_btn_a", Delegate.GetOrCreate(self, self.OnClickTabPersonal))
    self._p_btn_a_status = self:StatusRecordParent("p_btn_a")
    self._p_text_a = self:Text("p_text_a", "alliance_bj_geren")
    self._p_btn_b = self:Button("p_btn_b", Delegate.GetOrCreate(self, self.OnClickTabAlliance))
    self._p_btn_b_status = self:StatusRecordParent("p_btn_b")
    self._p_text_b = self:Text("p_text_b", "alliance_bj_lianmeng")
    
    self._p_btn_content = self:InputField("p_btn_content"
    , Delegate.GetOrCreate(self, self.OnInputValueChanged)
    , Delegate.GetOrCreate(self, self.OnEditEnd)
    , Delegate.GetOrCreate(self, self.OnSubmitText)
    )
    self._p_btn_content.characterLimit = self._maxContentLength
    self._p_text_place_holder = self:Text("p_text_place_holder", "alliance_bj_biaojiwenben")
    self._p_text_number = self:Text("p_text_number")
    
    self._p_table_icon = self:TableViewPro("p_table_icon")
    
    self._p_text_number_marker = self:Text("p_text_number_marker")
    
    self._p_comp_btn_b_l = self:Button("p_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickBtnSet))
    self._p_text = self:Text("p_text", "confirm")
end

function UIBattleSignalPopupMediator:OnShow(param)
    local titleParam = {}
    titleParam.title = I18N.Get("league_hud_mark")
    self._child_popup_base_s:FeedData(titleParam)
    --g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMessage.MapLabels.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceLabelDataChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceLabelDataChanged))
end

function UIBattleSignalPopupMediator:OnHide(param)
    --g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMessage.MapLabels.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceLabelDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CACHED_MARK_DATA_CHANGED, Delegate.GetOrCreate(self, self.OnAllianceLabelDataChanged))
end

---@param param UIBattleSignalPopupMediatorParameter|UIBattleSignalPopupMediatorModifyParameter
function UIBattleSignalPopupMediator:OnOpened(param)
    self._addSignalData = nil
    self._modifySignalData = nil
    self._isEditMode = param.id ~= nil
    self._fromMediatorId = param.fromMediatorId
    if self._isEditMode then
        ---@type UIBattleSignalPopupMediatorModifyParameter
        self._modifySignalData = param
    else
        ---@type UIBattleSignalPopupMediatorParameter
        self._addSignalData = param
    end
    table.clear(self._tableData)
    self._selectedType = nil
    self._p_table_icon:Clear()
    for _, value in ConfigRefer.AllianceMapLabel:ipairs() do
        ---@type UIBattleSignalTableCellData
        local typeCell = {}
        typeCell.config = value
        self._p_table_icon:AppendData(typeCell)
        table.insert(self._tableData , typeCell)
    end
    self._p_table_icon:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectType))
    self._p_table_icon:SetToggleSelectIndex(0)
    self:SetupTarget()
    self:OnClickTabAlliance()
    self:RefreshTextCountLimit()
end

function UIBattleSignalPopupMediator:OnClose()
    if self._p_table_icon then
        self._p_table_icon:SetSelectedDataChanged(nil)
    end
end

function UIBattleSignalPopupMediator:SetupTarget()
    if self._isEditMode then
        local serverData = self._modifySignalData.label
        self._p_text_position_num.text = ("X:%s,Y:%s"):format(math.floor(serverData.X + 0.5), math.floor(serverData.Y + 0.5))
        for _, v in ipairs(self._tableData) do
            if v.config:Id() == serverData.ConfigId then
                self._p_table_icon:SetToggleSelect(v)
                break
            end
        end
        self._p_btn_content.text = serverData.Content
        if BattleSignalConfig.MobTypeHash[serverData.TargetTypeHash] then
            self:SetupMapMob(nil, serverData.TargetConfigId)
        elseif BattleSignalConfig.BuildingTypeHash[serverData.TargetTypeHash] then
            self:SetupBuilding(nil, serverData)
        else
            self:SetupPlayer(serverData.DynamicParam.Portrait, serverData.DynamicParam.TargetAllianceName, serverData.DynamicParam.TargetName)
        end
    else
        if self._addSignalData.tile then
            self._p_text_position_num.text = ("X:%s,Y:%s"):format(math.floor(self._addSignalData.tile.X + 0.5), math.floor(self._addSignalData.tile.Z + 0.5))
            ---@type wds.DefenceTower|wds.EnergyTower|wds.TransferTower|wds.Village|wds.ResourceField|wds.CastleBrief
            local entity = self._addSignalData.tile.entity
            if BattleSignalConfig.BuildingTypeHash[entity.TypeHash] then
                self:SetupBuilding(entity)
            end
        elseif self._addSignalData.entity then
            local entity = self._addSignalData.entity
            local coord = entity.MapBasics.Position
            self._p_text_position_num.text = ("X:%s,Y:%s"):format(math.floor(coord.X + 0.5), math.floor(coord.Y + 0.5))
            if entity.TypeHash == DBEntityType.MapMob then
                self:SetupMapMob(entity)
            else
                self:SetupPlayer(self._addSignalData.frame, self._addSignalData.abbr, self._addSignalData.name)
            end
        end
    end
end

---@param entity any
---@param mapLabelData wds.AllianceMapLabel
function UIBattleSignalPopupMediator:SetupBuilding(entity, mapLabelData)
    self._p_lv:SetVisible(true)
    local name
    local level
    if entity then
        name = ModuleRefer.MapBuildingTroopModule:GetBuildingName(entity)
        level = ModuleRefer.MapBuildingTroopModule:GetBuildingLevel(entity)
        if entity.TypeHash == DBEntityType.CastleBrief then
            self._p_img_building:SetVisible(false)
            self._p_player:SetVisible(true)
            self._p_img_boss:SetVisible(false)
            self._child_ui_head_player:FeedData(entity.Owner)
        else
            self._p_img_building:SetVisible(true)
            self._p_player:SetVisible(false)
            self._p_img_boss:SetVisible(false)
            local image = ModuleRefer.MapBuildingTroopModule:GetBuildingImage(entity)
            g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(image), self._p_img_building)
        end
    else
        if mapLabelData.TargetTypeHash == DBEntityType.CastleBrief then
            self._p_img_building:SetVisible(false)
            self._p_player:SetVisible(true)
            self._p_img_boss:SetVisible(false)
            ---@type {iconId:number, iconName:string}
            local par= {}
            par.iconId = mapLabelData.DynamicParam.Portrait
            self._child_ui_head_player:FeedData(par)
            if string.IsNullOrEmpty(mapLabelData.DynamicParam.TargetAllianceName) then
                name = mapLabelData.DynamicParam.TargetName
            else
                name = ("[%s]%s"):format(mapLabelData.DynamicParam.TargetAllianceName, mapLabelData.DynamicParam.TargetName)
            end
        else
            self._p_img_building:SetVisible(true)
            self._p_player:SetVisible(false)
            self._p_img_boss:SetVisible(false)
            local configId = mapLabelData.TargetConfigId
            local buildingConfig = ModuleRefer.MapBuildingTroopModule:GetBuildingConfig(configId)
            if buildingConfig then
                name = I18N.Get(buildingConfig:Name())
                level = buildingConfig:Level()
                local imageId = buildingConfig:Image()
                if type(imageId) == "number" then
                    local image = UIHelper.IconOrMissing(imageId ~= 0 and ArtResourceUtils.GetUIItem(imageId))
                    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(image), self._p_img_building)
                else
                    local image = UIHelper.IconOrMissing(imageId)
                    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(image), self._p_img_building)
                end
            end
        end
    end
    self._p_text_lv.text = tostring(level)
    self._p_text_name.text = name
end

---@param mapMob wds.MapMob
function UIBattleSignalPopupMediator:SetupMapMob(mapMob, configId)
    self._p_img_building:SetVisible(false)
    self._p_player:SetVisible(false)
    self._p_img_boss:SetVisible(true)
    self._p_lv:SetVisible(true)
    local name,icon,lv
    if mapMob then
        name,icon,lv = SlgTouchMenuHelper.GetMobNameImageLevelHeadIcons(mapMob)
    else
        name,icon,lv = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfigId(configId)
    end
    g_Game.SpriteManager:LoadSprite(icon, self._p_img_boss)
    self._p_text_lv.text = tostring(lv)
    self._p_text_name.text = name
end

function UIBattleSignalPopupMediator:SetupPlayer(frame, abbr, name)
    self._p_img_building:SetVisible(false)
    self._p_player:SetVisible(true)
    self._p_img_boss:SetVisible(false)
    self._p_lv:SetVisible(false)
    -----@type {iconId:number, iconName:string}
    local par = {}
    par.iconId = frame
    self._child_ui_head_player:FeedData(par)
    self._p_text_name.text = ModuleRefer.PlayerModule.FullName(abbr, name)
end

---@param newData UIBattleSignalTableCellData
function UIBattleSignalPopupMediator:OnSelectType(_, newData)
    self._selectedType = newData and newData.config or nil
    if self._isEditMode then
        return
    end
    if self._selectTab == 2 and self._selectedType then
        local descI18n = newData.config:DefaultDesc()
        if not string.IsNullOrEmpty(descI18n) then
            self._p_btn_content.text = I18N.Get(descI18n)
        else
            self._p_btn_content.text = string.Empty
        end
    end
end

function UIBattleSignalPopupMediator:OnClickTabPersonal()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_bj_kaifangqidai"))
    
    --todo 未来个人标记功能
    --self._selectTab = 1
    --self._p_btn_a_status:SetState(1)
    --self._p_btn_b_status:SetState(0)
end

function UIBattleSignalPopupMediator:OnClickTabAlliance()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_26003"))
        return
    end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyMapLabel) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_bj_wubiaojiquanxian"))
        return
    end
    self._selectTab = 2
    self._p_btn_a_status:SetState(0)
    self._p_btn_b_status:SetState(1)
    self:OnAllianceLabelDataChanged(ModuleRefer.AllianceModule:GetMyAllianceData())
end

function UIBattleSignalPopupMediator:OnClickGoto()
    ---@type {x:number,y:number}
    local gotoCoord = nil
    if self._isEditMode and self._modifySignalData and self._modifySignalData.label then
        gotoCoord = {
            x = self._modifySignalData.label.X,
            y = self._modifySignalData.label.Y,
        }
    elseif self._addSignalData and self._addSignalData.tile then
        gotoCoord = {
            x = self._addSignalData.tile.X,
            y = self._addSignalData.tile.Z,
        }
    elseif self._addSignalData and self._addSignalData.entity and self._addSignalData.entity.MapBasics and self._addSignalData.entity.MapBasics.Position then
        gotoCoord = {
            x = self._addSignalData.entity.MapBasics.Position.X,
            y = self._addSignalData.entity.MapBasics.Position.Y,
        }
    end
    if gotoCoord and gotoCoord.x ~= 0 and gotoCoord.y ~= 0 then
        AllianceWarTabHelper.GoToCoord(gotoCoord.x, gotoCoord.y)
        self:CloseSelf()
        if self._fromMediatorId then
            g_Game.UIManager:Close(self._fromMediatorId)
        end
    end
end

function UIBattleSignalPopupMediator:OnClickBtnSet()
    if not self._selectedType or self._selectTab ~= 2 then
        return
    end
    if self._selectTab == 1 then
        --todo 未来个人标记功能
    elseif self._selectTab == 2 then
        if self._isEditMode then
            local d = self._modifySignalData
            local sd = d.label
            local setType = self._selectedType and self._selectedType:Type() or AllianceMapLabelType.Default
            if setType == AllianceMapLabelType.Unlimited then
                setType = AllianceMapLabelType.Default
            end
            ModuleRefer.SlgModule:ModifySignal(d.id, sd.X, sd.Y, sd.TargetId, setType, self._contentString, self._selectedType:Id(), self._p_comp_btn_b_l.transform, nil, function(cmd, isSuccess, rsp)
                self:CloseSelf()
            end)
        else
            local targetId = self._addSignalData.tile and self._addSignalData.tile.entity.ID or self._addSignalData.troopId or self._addSignalData.entity.ID
            local addType = self._selectedType and self._selectedType:Type() or AllianceMapLabelType.Default
            if addType == AllianceMapLabelType.Unlimited then
                addType = AllianceMapLabelType.Default
            end
            local mobX,mobY
            if self._addSignalData.entity and (self._addSignalData.entity.TypeHash == wds.MapMob.TypeHash or self._addSignalData.entity.TypeHash == wds.Troop.TypeHash) then
                mobX = math.floor(self._addSignalData.entity.MapBasics.Position.X + 0.5)
                mobY = math.floor(self._addSignalData.entity.MapBasics.Position.Y + 0.5)
            end
            ModuleRefer.SlgModule:AddSignal(AllianceMapLabelType.Default,self._addSignalData.tile, targetId, self._contentString, self._selectedType:Id(), self._p_comp_btn_b_l.transform, nil, function(cmd, isSuccess, rsp)
                if isSuccess then
                    local labelData = ModuleRefer.AllianceModule:GetMyAllianceMapLabel(rsp.LabelId)
                    local allianceSession = ModuleRefer.ChatModule:GetAllianceSession()
                    if allianceSession then
                        ---@type ShareChatItemParam
                        local chatParam = {}
                        chatParam.type = ChatShareType.AllianceMark
                        chatParam.configID = self._selectedType:Id()
                        chatParam.x = mobX or labelData and labelData.X or 0
                        chatParam.y = mobY or labelData and labelData.Y or 0
                        chatParam.name = labelData and ModuleRefer.AllianceModule.BuildContentInfo(labelData)
                        chatParam.shareDesc = ModuleRefer.PlayerModule:GetPlayer().Basics.Name
                        chatParam.customPic = self._selectedType:Icon()
                        local allianceSessionId = allianceSession.SessionId
                        ModuleRefer.ChatModule:SendShareMsg(allianceSessionId, chatParam)
                    end
                end
                self:CloseSelf()
            end)
        end
    end
end

function UIBattleSignalPopupMediator:OnInputValueChanged(text)
    self._contentString = text
    self:RefreshTextCountLimit()
end

function UIBattleSignalPopupMediator:OnEditEnd(text)
    self._contentString = text
    self:RefreshTextCountLimit()
end

function UIBattleSignalPopupMediator:OnSubmitText(text)
    self._contentString = text
    self:RefreshTextCountLimit()
end

function UIBattleSignalPopupMediator:RefreshTextCountLimit()
    self._p_text_number.text = ("%d/%d"):format(utf8.len(self._contentString), self._maxContentLength)
end

---@param entity wds.Alliance
function UIBattleSignalPopupMediator:OnAllianceLabelDataChanged(entity, _)
    if self._selectTab ~= 2 then
        UIHelper.ButtonEnable(self._p_comp_btn_b_l, not false)
    else
        if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
            return
        end
        local count = table.nums(ModuleRefer.AllianceModule:GetMyAllianceMapLabels())
        local limitCount = ConfigRefer.AllianceConsts:AllianceMaxMapLabelCount()
        self._p_text_number_marker.text = I18N.GetWithParams("alliance_mark_limitstats", tostring(count), tostring(limitCount))
        local gray = (not entity) or (count > limitCount) or (not self._isEditMode and count == limitCount)
        UIHelper.ButtonEnable(self._p_comp_btn_b_l, not gray)
    end
end

return UIBattleSignalPopupMediator
