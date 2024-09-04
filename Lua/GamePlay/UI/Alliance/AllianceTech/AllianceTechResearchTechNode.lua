local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceTechResearchHostProvider = require("AllianceTechResearchHostProvider")
local UIHelper = require("UIHelper")
local AllianceTechConditionHelper = require("AllianceTechConditionHelper")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTechResearchTechNode:BaseUIComponent
---@field new fun():AllianceTechResearchTechNode
---@field super BaseUIComponent
local AllianceTechResearchTechNode = class('AllianceTechResearchTechNode', BaseUIComponent)

function AllianceTechResearchTechNode:ctor()
    BaseUIComponent.ctor(self)
    ---@type AllianceTechGroupChain
    self._data = nil
    self._eventAdd = false
    self._workEndTime = nil
    self._preOrNextNodeGroupIdMap = {}
end

function AllianceTechResearchTechNode:OnCreate(param)
    self._p_line_l = self:GameObject("p_line_l")
    self._p_line_l_lock = self:GameObject("p_line_l_lock")
    self._p_line_l_unlock = self:GameObject("p_line_l_unlock")
    self._p_line_r = self:GameObject("p_line_r")
    self._p_line_r_lock = self:GameObject("p_line_r_lock")
    self._p_line_r_unlock = self:GameObject("p_line_r_unlock")

    self._p_line_t = self:GameObject("p_line_t")
    self._p_line_t_lock = self:GameObject("p_line_t_lock")
    self._p_line_t_unlock = self:GameObject("p_line_t_unlock")
    self._p_line_b = self:GameObject("p_line_b")
    self._p_line_b_lock = self:GameObject("p_line_b_lock")
    self._p_line_b_unlock = self:GameObject("p_line_b_unlock")
    
    self._p_btn_notes = self:Button("p_btn_notes", Delegate.GetOrCreate(self, self.OnClickSelfBtn))
    ---@type CS.UnityEngine.RectTransform
    self._p_btn_notes_rect = self._p_btn_notes.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._p_img_select = self:GameObject("p_img_select")
    self._p_icon_item_1 = self:Image("p_icon_item_1")
    self._p_text_name_task = self:Text("p_text_name_task")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_icon_update = self:GameObject("p_icon_update")
    self._p_icon_recommend = self:GameObject("p_icon_recommend")
    self._p_progress = self:GameObject("p_progress")
    self._p_progress_bar = self:Image("p_progress_bar")
    ---@see CommonTimer
    self._child_time = self:LuaBaseComponent("child_time")
    self._p_work = self:GameObject("p_work")
end

---@param data AllianceTechGroupChain
function AllianceTechResearchTechNode:OnFeedData(data)
    self._data = data
    table.clear(self._preOrNextNodeGroupIdMap)
    table.clear(self._assignAllianceCurrency)
    for i, v in pairs(data.next) do
        self._preOrNextNodeGroupIdMap[i] = true
    end
    for i, v in pairs(data.pre) do
        self._preOrNextNodeGroupIdMap[i] = true
    end
    self._groupId = data.id
    self._groupData = ModuleRefer.AllianceTechModule:GetTechGroupStatus(self._groupId)
    self:RefreshNode()
    self:SetupEvent(true)
end

function AllianceTechResearchTechNode:OnRecycle()
    self:SetupEvent(false)
    self._groupId = nil
end

function AllianceTechResearchTechNode:OnClose(param)
    self:SetupEvent(false)
    self._groupId = nil
end

function AllianceTechResearchTechNode:OnClickSelfBtn()
    self:DoSetSelectedSelf()
end

function AllianceTechResearchTechNode:DoSetSelectedSelf()
    if not self._data then
        return
    end
    local max = self._p_btn_notes_rect.rect.max
    local maxV3 = self._p_btn_notes_rect:TransformPoint(max.x, max.y, 0)
    AllianceTechResearchHostProvider.Instance():SetSelectedGroup(self._data.id, maxV3)
end

function AllianceTechResearchTechNode:RefreshNode()
    self:RefreshLink()
    self:RefreshSelected(AllianceTechResearchHostProvider.Instance():GetSelectedGroup())
    self:RefreshRecommend()
    self:RefreshStatus()
end

function AllianceTechResearchTechNode:RefreshLink()
    -- local noPre = table.isNilOrZeroNums(self._data.pre)
    -- local noNext = table.isNilOrZeroNums(self._data.next)

    self:SetLines()

    -- self._p_line_l:SetVisible(not noPre)
    -- self._p_line_r:SetVisible(not noNext)
    -- local preUnlocked = self._groupData and self._groupData.Status ~= wds.AllianceTechnologyNodeStatus.AlisTechStatusNotWorked and self._groupData.Level > 0
    -- self._p_line_l_lock:SetVisible(not preUnlocked)
    -- self._p_line_l_unlock:SetVisible(preUnlocked)
    -- local nextUnLocked = false
    -- if preUnlocked and not noNext then
    --     for i, v in pairs(self._data.next) do
    --         local nextGroup = ModuleRefer.AllianceTechModule:GetTechGroupStatus(v.id)
    --         if nextGroup and nextGroup.Status ~= wds.AllianceTechnologyNodeStatus.AlisTechStatusNotWorked and nextGroup.Level > 0 then
    --             nextUnLocked = true
    --             break
    --         end
    --     end
    -- end
    -- self._p_line_r_lock:SetVisible(not nextUnLocked)
    -- self._p_line_r_unlock:SetVisible(nextUnLocked)
end

function AllianceTechResearchTechNode:SetLines()
    local noPre = table.isNilOrZeroNums(self._data.pre)
    local noNext = table.isNilOrZeroNums(self._data.next)
    self.lineDir = {0, 0, 0, 0} -- 四方向
    for k, v in pairs(self._data.pre) do
        self:CheckVerticalDir(v, true)
    end
    for k, v in pairs(self._data.next) do
        self:CheckVerticalDir(v, false)
    end

    local preUnlocked = self._groupData and self._groupData.Status ~= wds.AllianceTechnologyNodeStatus.AlisTechStatusNotWorked and self._groupData.Level > 0
    local nextUnLocked = false
    if preUnlocked and not noNext then
        for i, v in pairs(self._data.next) do
            local nextGroup = ModuleRefer.AllianceTechModule:GetTechGroupStatus(v.id)
            if nextGroup and nextGroup.Status ~= wds.AllianceTechnologyNodeStatus.AlisTechStatusNotWorked and nextGroup.Level > 0 then
                nextUnLocked = true
                break
            end
        end
    end

    self._p_line_t:SetVisible(self.lineDir[1] == 1)
    self._p_line_b:SetVisible(self.lineDir[2] == 1)
    self._p_line_l:SetVisible(self.lineDir[3] == 1)
    self._p_line_r:SetVisible(self.lineDir[4] == 1)
    self._p_line_t_lock:SetVisible(not preUnlocked and not nextUnLocked and self.lineDir[1] == 1)
    self._p_line_b_lock:SetVisible(not preUnlocked and not nextUnLocked and self.lineDir[2] == 1)
    self._p_line_l_lock:SetVisible(not preUnlocked and not nextUnLocked and self.lineDir[3] == 1)
    self._p_line_r_lock:SetVisible(not preUnlocked and not nextUnLocked and self.lineDir[4] == 1)
    self._p_line_t_unlock:SetVisible(preUnlocked or nextUnLocked and self.lineDir[1] == 1)
    self._p_line_b_unlock:SetVisible(preUnlocked or nextUnLocked and self.lineDir[2] == 1)
    self._p_line_l_unlock:SetVisible(preUnlocked or nextUnLocked and self.lineDir[3] == 1)
    self._p_line_r_unlock:SetVisible(preUnlocked or nextUnLocked and self.lineDir[4] == 1)
end

function AllianceTechResearchTechNode:CheckVerticalDir(node, isPre)
    if self._data.columnDepth == node.columnDepth then
        if self._data.id < node.id then
            self.lineDir[2] = 1
        else
            self.lineDir[1] = 1
        end
    else
        if isPre then
            self.lineDir[3] = 1
        else
            self.lineDir[4] = 1
        end
    end
end

function AllianceTechResearchTechNode:RefreshSelected(groupId)
    self._p_img_select:SetVisible(self._data and groupId == self._data.id)
end

function AllianceTechResearchTechNode:RefreshRecommend()
    local recommendTech = ModuleRefer.AllianceTechModule:GetRecommendTech()
    self._p_icon_recommend:SetVisible(self._data and recommendTech == self._data.id)
end

function AllianceTechResearchTechNode:RefreshStatus()
    self._workEndTime = nil
    local serverUnlockNextLevel  = self._groupData and self._groupData.UnlockNextLevel or false
    local lv = self._groupData and self._groupData.Level or 0
    local lvCount = #self._data.group
    local config = self._data.group[math.clamp(lv, 1, lvCount)]
    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(config:Icon()), self._p_icon_item_1)
    self._p_text_name_task.text = I18N.Get(config:Name())
    if not self._groupData or self._groupData.Level <= 0 then
        self._p_text_quantity.text = ("%d/%d"):format(0, lvCount)
    else
        self._p_text_quantity.text = ("%d/%d"):format(lv, lvCount)
    end
    local inWork = self._groupData and self._groupData.Status == wds.AllianceTechnologyNodeStatus.AlisTechStatusInStudy
    self._p_work:SetVisible(inWork)
    self._p_progress:SetVisible(inWork)
    self._child_time:SetVisible(inWork)
    if inWork then
        local nextLvConfig = self._data.group[lv + 1]
        local startTime = self._groupData.LevelUpTime.Seconds
        self._workEndTime = startTime + ModuleRefer.AllianceTechModule:CalculateTechCostTime(nextLvConfig)
    end
    self._p_icon_update:SetVisible(ModuleRefer.AllianceTechModule:IsReadyToNextLevel(self._groupData))
    self:TickProgress(0)
    UIHelper.SetGray(self._p_icon_item_1.gameObject, not inWork and lv == 0 and not serverUnlockNextLevel)
end

function AllianceTechResearchTechNode:OnNodeChanged(changedIdMap)
    if not self._groupId then
        return
    end
    if changedIdMap[self._groupId] then
        self._groupData = ModuleRefer.AllianceTechModule:GetTechGroupStatus(self._groupId)
        self:RefreshNode()
    else
        for i, v in pairs(changedIdMap) do
            if self._preOrNextNodeGroupIdMap[i] then
                self:RefreshLink()
                return
            end
        end
    end
end

function AllianceTechResearchTechNode:OnAllianceCurrencyChanged(changedId)
    self:RefreshStatus()
end

function AllianceTechResearchTechNode:SetupEvent(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_TECH_NODE_UPDATED, Delegate.GetOrCreate(self, self.OnNodeChanged))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_TECH_RECOMMEND_UPDATED, Delegate.GetOrCreate(self, self.RefreshRecommend))
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickProgress))
        g_Game.EventManager:AddListener(EventConst.UI_ALLIANCE_TECH_GROUP_SELECTED, Delegate.GetOrCreate(self, self.RefreshSelected))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TECH_NODE_UPDATED, Delegate.GetOrCreate(self, self.OnNodeChanged))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TECH_RECOMMEND_UPDATED, Delegate.GetOrCreate(self, self.RefreshRecommend))
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickProgress))
        g_Game.EventManager:RemoveListener(EventConst.UI_ALLIANCE_TECH_GROUP_SELECTED, Delegate.GetOrCreate(self, self.RefreshSelected))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_CURRENCY_UPDATED_IDS, Delegate.GetOrCreate(self, self.OnAllianceCurrencyChanged))
    end
end

function AllianceTechResearchTechNode:TickProgress(dt)
    if not self._workEndTime then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local leftTime = self._workEndTime - nowTime
    if leftTime < 0 then
        self._workEndTime = nil
        return
    end
    ---@type CommonTimerData
    local timeData = {}
    timeData.fixTime = leftTime
    timeData.needTimer = false
    self._child_time:FeedData(timeData)
    self._p_progress_bar.fillAmount = math.inverseLerp(self._groupData.LevelUpTime.Seconds, self._workEndTime, nowTime)
end

return AllianceTechResearchTechNode