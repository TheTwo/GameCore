local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceWarCell:BaseTableViewProCell
---@field new fun():AllianceWarCell
---@field super BaseTableViewProCell
local AllianceWarCell = class('AllianceWarCell', BaseTableViewProCell)

function AllianceWarCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._useTick = false
    self._eventAdd = false
end

function AllianceWarCell:OnCreate(param)
    self._p_btn_content = self:Button("p_btn_content", Delegate.GetOrCreate(self, self.OnClickBtnSelf))
    self._p_base_attack = self:GameObject("p_base_attack")
    self._p_base_defence = self:GameObject("p_base_defence")
    
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_distance = self:GameObject("p_distance")
    self._p_text_distance = self:Text("p_text_distance")
    self._p_text_name_player = self:Text("p_text_name_player")
    self._p_text_position_player = self:Text("p_text_position_player")
    self._p_btn_position = self:Button("p_btn_position", Delegate.GetOrCreate(self, self.OnClickPlayerPosition))
    self._p_icon_attack = self:GameObject("p_icon_attack")
    self._p_icon_defence = self:GameObject("p_icon_defence")
    self._p_text_vs = self:Text("p_text_vs")
    self._p_text_status_war = self:Text("p_text_status_war")
    self._p_text_time_war = self:Text("p_text_time_war")
    
    ---@type PlayerInfoComponent
    self._child_ui_head_enemy = self:LuaObject("child_ui_head_enemy")
    self._p_monster = self:GameObject("p_monster")
    self._p_img_monster = self:Image("p_img_monster")
    self._p_text_position_enemy = self:Text("p_text_position_enemy")
    self._p_text_name_enemy = self:Text("p_text_name_enemy")
    self._p_btn_position_enemy = self:Button("p_btn_position_enemy", Delegate.GetOrCreate(self, self.OnClickEnemyPosition))
    
    self._p_btn_join = self:Button("p_btn_join", Delegate.GetOrCreate(self, self.OnClickJoin))
    self._p_btn_quit = self:Button("p_btn_quit", Delegate.GetOrCreate(self, self.OnClickQuit))
    
    self._p_progress_attack = self:Slider("p_progress_attack")
    self._p_progress_walking = self:Slider("p_progress_walking")
    self._p_progress_defence = self:Slider("p_progress_defence")
    
    self._p_status_joined = self:GameObject("p_status_joined")
    self._p_text_num_1 = self:Text("p_text_num_1")
    self._p_text_num = self:Text("p_text_num")
    self._p_text_quit_num = self:Text("p_text_quit_num")
    self._p_text_join_num = self:Text("p_text_join_num_info")
end

---@param data AllianceWarCellData
function AllianceWarCell:OnFeedData(data)
    if not data or not data.is or not data:is(require("AllianceWarCellData")) then
        return
    end
    self._data = data
    local leftPlayer = data:GetLeftPlayerInfo()
    self._child_ui_head_player:SetVisible(leftPlayer ~= nil)
    if leftPlayer then
        self._child_ui_head_player:FeedData(data:GetLeftPortraitInfo())
    end
    local distance = data:GetLeftDistance()
    self._p_distance:SetVisible(distance ~= nil)
    if distance then
        if distance > 1000 then
            self._p_text_distance.text = ("%dKM"):format(math.floor(distance / 1000 + 0.5))
        else
            self._p_text_distance.text = ("%dM"):format(math.floor(distance + 0.5))
        end
        
    end
    self._p_text_name_player.text = data:GetLeftName()
    local leftPos = data:GetLeftCoord()
    self._p_text_position_player:SetVisible(leftPos ~= nil)
    if leftPos then
        self._p_text_position_player.text = ("X:%d Y:%d"):format(leftPos.x, leftPos.y)
    end

    local rightPlayer = data:GetRightPlayerInfo()
    self._child_ui_head_enemy:SetVisible(rightPlayer ~= nil)
    self._p_monster:SetVisible(rightPlayer == nil)
    if rightPlayer then
        self._child_ui_head_enemy:FeedData(data:GetRightPortraitInfo())
    else
        g_Game.SpriteManager:LoadSprite(data:GetRightImage(), self._p_img_monster)
    end
    self._p_text_name_enemy.text = data:GetRightName()
    local rightPos = data:GetRightCoord()
    self._p_text_position_enemy:SetVisible(rightPos ~= nil)
    if rightPos then
        self._p_text_position_enemy.text = ("X:%d Y:%d"):format(rightPos.x, rightPos.y)
    end
    
    local isAttack = data:IsLeftAttacker()
    self._p_icon_attack:SetVisible(isAttack)
    self._p_icon_defence:SetVisible(not isAttack)
    
    self._p_text_vs.text = data:GetVsCenterText()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self._p_btn_join:SetVisible(data:ShowJoin(nowTime))
    self._p_btn_quit:SetVisible(data:ShowQuit(nowTime))
    
    local index, progress = data:GetProgress(nowTime)
    self._p_progress_attack:SetVisible(index == 1)
    self._p_progress_defence:SetVisible(index == 2)
    self._p_progress_walking:SetVisible(index == 3)
    if progress then
        self._p_progress_attack.value = progress
        self._p_progress_defence.value = progress
        self._p_progress_walking.value = progress
        self._p_progress_attack:SetVisible(true)
        self._p_progress_defence:SetVisible(true)
        self._p_progress_walking:SetVisible(true)
    else
        self._p_progress_attack:SetVisible(false)
        self._p_progress_defence:SetVisible(false)
        self._p_progress_walking:SetVisible(false)
    end
    
    local showJoined, num1, num = data:ShowJoined(nowTime)
    self._p_status_joined:SetVisible(showJoined)
    if showJoined then
        self._p_text_num_1.text = num1
        self._p_text_num.text = num
    end
    self._p_text_quit_num.text = num
    self._p_text_join_num.text = num
    self._useTick = data:UseTick()
    self:Tick(0)
    self:SetupEvent(true)
end

function AllianceWarCell:OnRecycle(param)
    self:SetupEvent(false)
end

function AllianceWarCell:OnClose(param)
    self:SetupEvent(false)
end

function AllianceWarCell:Tick(dt)
    if not self._useTick then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self._p_text_status_war.text = self._data:GetStatusString(nowTime)
    local warTimeStr = self._data:GetTimeString(nowTime)
    self._p_text_time_war.text = warTimeStr
    self._p_text_time_war:SetVisible(not string.IsNullOrEmpty(warTimeStr))
    self._p_btn_join:SetVisible(self._data:ShowJoin(nowTime))
    self._p_btn_quit:SetVisible(self._data:ShowQuit(nowTime))
    local index, progress = self._data:GetProgress(nowTime)
    self._p_progress_attack:SetVisible(index == 1)
    self._p_progress_defence:SetVisible(index == 2)
    self._p_progress_walking:SetVisible(index == 3)
    if progress then
        self._p_progress_attack.value = progress
        self._p_progress_defence.value = progress
        self._p_progress_walking.value = progress
        self._p_progress_attack:SetVisible(true)
        self._p_progress_defence:SetVisible(true)
        self._p_progress_walking:SetVisible(true)
    else
        self._p_progress_attack:SetVisible(false)
        self._p_progress_defence:SetVisible(false)
        self._p_progress_walking:SetVisible(false)
    end
    self._useTick = self._data:UseTick()

    local showJoined, num1, num = self._data:ShowJoined(nowTime)
    self._p_status_joined:SetVisible(showJoined)
    if showJoined then
        self._p_text_num_1.text = num1
        self._p_text_num.text = num
    end
end

function AllianceWarCell:OnClickBtnSelf()
    local tableView = self:GetTableViewPro()
    self._data:SetExpanded(not self._data:IsExpanded())
    tableView:UpdateData(self._data)
end

function AllianceWarCell:OnClickJoin()
    self._data:OnClickJoin()
end

function AllianceWarCell:OnClickQuit()
    self._data:OnClickQuit()
end

function AllianceWarCell:OnClickPlayerPosition()
    if self._data:OnClickPlayerPosition() then
        self:GetParentBaseUIMediator():CloseSelf()
    end
end

function AllianceWarCell:OnClickEnemyPosition()
    if self._data:OnClickEnemyPosition() then
        self:GetParentBaseUIMediator():CloseSelf()
    end
end

function AllianceWarCell:SetupEvent(add)
    if self._eventAdd and not add then
        self._eventAdd = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    elseif not self._eventAdd and add then
        self._eventAdd = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    end
end

return AllianceWarCell