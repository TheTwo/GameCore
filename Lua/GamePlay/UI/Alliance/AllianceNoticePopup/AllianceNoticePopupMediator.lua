--- scene:scene_league_popup_notice

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local AllianceModuleDefine = require("AllianceModuleDefine")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local ChatSDK = CS.FunPlusChat.FPChatSdk

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceNoticePopupMediatorParameter
---@field backNoAni boolean

---@class AllianceNoticePopupMediator:BaseUIMediator
---@field new fun():AllianceNoticePopupMediator
---@field super BaseUIMediator
local AllianceNoticePopupMediator = class('AllianceNoticePopupMediator', BaseUIMediator)

function AllianceNoticePopupMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type AllianceNoticePopupCellData[]
    self._cells = {}
    self._allianceId = nil
    self._canSendInfo = false
    self._canDeleteInfo = false
    self._backNoAni = false
    self._waitTranslateTitle = {}
end

function AllianceNoticePopupMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_m = self:LuaObject("child_popup_base_m")
    self._p_table = self:TableViewPro("p_table")
    ---@type CS.TableViewProLayout
    self._p_table_layout = self:BindComponent("p_table", typeof(CS.TableViewProLayout))
    self._p_none = self:GameObject("p_none")
    self._p_text_none = self:Text("p_text_none", "alliance_notice_none")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickBtnGoToSendInfo))
    self._p_text = self:Text("p_text_goto", "alliance_notice_release")
    self._p_ui_common_content = self:StatusRecordParent("p_ui_common_content")
end

---@param param AllianceNoticePopupMediatorParameter
function AllianceNoticePopupMediator:OnOpened(param)
    self._backNoAni = param and param.backNoAni or false
    ---@type CommonBackButtonData
    local commonBackButtonData = {}
    commonBackButtonData.title = I18N.Get("alliance_notice_title3")
    commonBackButtonData.onClose = Delegate.GetOrCreate(self, self.OnClickBackBtn)
    self._child_popup_base_m:FeedData(commonBackButtonData)
    
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._canDeleteInfo = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank >= AllianceModuleDefine.LeaderRank
    self._canSendInfo = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ModifyInform)
    self._p_ui_common_content:SetState(self._canSendInfo and 0 or 1)
    self:GenerateNoticeCellData()
    self._p_table:Clear()
    if #self._cells > 2 then
        self._p_table_layout.childAlignment = CS.UnityEngine.TextAnchor.MiddleLeft
    else
        self._p_table_layout.childAlignment = CS.UnityEngine.TextAnchor.MiddleCenter
    end
    self._p_table_layout:OnTableViewRefresh(self._p_table)
    for _, cellData in ipairs(self._cells) do
        self._p_table:AppendData(cellData)
    end
    self._p_none:SetVisible(#self._cells <= 0)
end

---@param a AllianceNoticePopupCellData
---@param b AllianceNoticePopupCellData
function AllianceNoticePopupMediator.SortForAllianceNoticePopupCellData(a, b)
    return a.info.Time.ServerSecond > b.info.Time.ServerSecond
end

function AllianceNoticePopupMediator:GenerateNoticeCellData()
    table.clear(self._cells)
    local message = ModuleRefer.AllianceModule:GetMyAllianceInforms()
    for i, v in pairs(message) do
        ---@type AllianceNoticePopupCellData
        local cellData = {}
        cellData.Id = i
        cellData.info = v
        cellData.canShowDelete = self._canDeleteInfo
        cellData.translateStatus = 0
        cellData.translated = false
        table.insert(self._cells, cellData)
    end
    if not table.isNilOrZeroNums(self._cells) then
        table.sort(self._cells, AllianceNoticePopupMediator.SortForAllianceNoticePopupCellData)
    end
end

function AllianceNoticePopupMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceMessage.Informs.MsgPath, Delegate.GetOrCreate(self, self.OnMessageDataChanged))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceNoticePopupMediator:OnHide(param)
    table.clear(self._waitTranslateTitle)
    self._allianceId = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceMessage.Informs.MsgPath, Delegate.GetOrCreate(self, self.OnMessageDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.OnLeaveAlliance))
end

function AllianceNoticePopupMediator:OnClose(data)
    BaseUIMediator.OnClose(self, data)
    ModuleRefer.AllianceModule:RefreshNoticeLastReadTime()
end

---@param entity wds.Alliance
---@param changedData table
function AllianceNoticePopupMediator:OnMessageDataChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local needFullRefresh = false
    local AddMap, RemoveMap, ChangedMap = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    local noRemove,removeCount = table.IsNullOrEmpty(RemoveMap)
    local noAdd,addCount = table.IsNullOrEmpty(AddMap)
    local originCount = #self._cells
    local newCount = originCount + addCount - removeCount
    if (originCount > 2 and newCount <= 2) or (originCount <= 2 and newCount > 2) then
        needFullRefresh = true
    end
    if not noRemove then
        for id, v in pairs(RemoveMap) do
            for index = #self._cells, 1, -1 do
                local cellData = self._cells[index]
                if cellData.Id == id then
                    if not needFullRefresh then
                        self._p_table:RemData(cellData)
                    end
                    local remData = table.remove(self._cells, index)
                    self._waitTranslateTitle[remData] = nil
                    break
                end
            end
        end
    end
    if ChangedMap then
        for id, v in pairs(ChangedMap) do
            for index = #self._cells, 1, -1 do
                local cellData = self._cells[index]
                if cellData.Id == id then
                    cellData.info = v
                    cellData.canShowDelete = self._canDeleteInfo
                    if not needFullRefresh then
                        self._p_table:UpdateData(cellData)
                    end
                    break
                end
            end
        end
    end
    if not noAdd then
        ---@type AllianceNoticePopupCellData[]
        local willAddCells = {}
        for id, v in pairs(AddMap) do
            ---@type AllianceNoticePopupCellData
            local willAddCell = {}
            willAddCell.Id = id
            willAddCell.info = v
            willAddCell.canShowDelete = self._canDeleteInfo
            table.insert(willAddCells, willAddCell)
        end
        table.sort(willAddCells, AllianceNoticePopupMediator.SortForAllianceNoticePopupCellData)
        for i = #willAddCells, 1, -1 do
            local addData = willAddCells[i]
            table.insert(self._cells, 1, addData)
            if not needFullRefresh then
                self._p_table:InsertData(0, addData)
            end
        end
    end
    if needFullRefresh then
        self._p_table:Clear()
        self._p_table_layout.childAlignment = #self._cells > 2 and CS.UnityEngine.TextAnchor.MiddleLeft or CS.UnityEngine.TextAnchor.MiddleCenter
        self._p_table_layout:OnTableViewRefresh(self._p_table)
        for _, v in ipairs(self._cells) do
            self._p_table:AppendData(v)
        end
    end
    self._p_none:SetVisible(#self._cells <= 0)
end

function AllianceNoticePopupMediator:OnLeaveAlliance(allianceId)
    self:CloseSelf()
end

function AllianceNoticePopupMediator:OnClickBtnGoToSendInfo()
    local count = #self._cells
    if ConfigRefer.AllianceConsts:AllianceInformNumMax() <= count then
        if self._canDeleteInfo then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_notice_release3"))
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_notice_release4"))
        end
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceReleaseNoticePopupMediator)
end

function AllianceNoticePopupMediator:OnClickBackBtn()
    self:BackToPrevious(nil, self._backNoAni, self._backNoAni)
end

---@param cellData AllianceNoticePopupCellData
function AllianceNoticePopupMediator:TranslateCell(cellData)
    self._waitTranslateTitle[cellData] = cellData
    ChatSDK.Translate(cellData.info.Title, CS.FunPlusChat.FunLang.unknown, ModuleRefer.ChatSDKModule:GetUserLanguage(), function(resultTitle)
        if not self._waitTranslateTitle[cellData] then
            return
        end
        ChatSDK.Translate(cellData.info.Content, CS.FunPlusChat.FunLang.unknown, ModuleRefer.ChatSDKModule:GetUserLanguage(), function(resultContext)
            if not self._waitTranslateTitle[cellData] then
                return
            end
            self._waitTranslateTitle[cellData] = nil
            cellData.translated = true
            cellData.translateStatus = 2
            cellData.tTitle = resultTitle and resultTitle.data and resultTitle.data.targetText
            cellData.tContext = resultContext and resultContext.data and resultContext.data.targetText
            self._p_table:UpdateChild(cellData)
        end, "Livedata")
    end, "Livedata")
end

return AllianceNoticePopupMediator