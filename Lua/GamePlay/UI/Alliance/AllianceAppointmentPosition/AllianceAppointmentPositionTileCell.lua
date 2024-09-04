local Delegate = require("Delegate")
local AllianceModuleDefine = require("AllianceModuleDefine")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceAppointmentPositionTileCellData
---@field player wds.AllianceMember
---@field title AllianceTitleConfigCell
---@field targetPlayer wds.AllianceMember
---@field targetPlayerHasTitle boolean
---@field cdEndTime number|nil
---@field onclick fun(cellData:AllianceAppointmentPositionTileCellData)

---@class AllianceAppointmentPositionTileCell:BaseTableViewProCell
---@field new fun():AllianceAppointmentPositionTileCell
---@field super BaseTableViewProCell
local AllianceAppointmentPositionTileCell = class('AllianceAppointmentPositionTileCell', BaseTableViewProCell)

function AllianceAppointmentPositionTileCell:ctor()
    BaseTableViewProCell.ctor(self)
    ---@type AllianceAppointmentPositionTileCellData
    self._cellData = nil
end

function AllianceAppointmentPositionTileCell:OnCreate(param)
    self._p_icon_logo = self:Image("p_icon_logo")
    self._p_text_position = self:Text("p_text_position")
    self._p_player = self:GameObject("p_player")
    self._p_text_name = self:Text("p_text_name")
    
    self._p_noplayer = self:GameObject("p_noplayer")
    
    self._p_comp_btn_assign = self:Button("p_comp_btn_assign", Delegate.GetOrCreate(self, self.OnClickBtnAssignOrReplace))
    self._p_text_btn_assign = self:Text("p_text_btn_assign")
    self._p_comp_btn_replace = self:Button("p_comp_btn_replace", Delegate.GetOrCreate(self, self.OnClickBtnAssignOrReplace))
    self._p_text_btn_replace = self:Text("p_text_btn_replace")
    self._p_comp_btn_cd = self:Button("p_comp_btn_cd")
    self._p_text_btn_cd = self:Text("p_text_btn_cd")
    
    self._buffers = {}
    for i = 1, 2 do
        self._buffers[i] = {
            root = self:GameObject(string.format("p_buff_%s", i)),
            text = self:Text(string.format("p_text_buff_%s", i)),
            value = self:Text(string.format("p_text_quantity_%s", i))
        }
    end
end

---@param data AllianceAppointmentPositionTileCellData
function AllianceAppointmentPositionTileCell:OnFeedData(data)
    self._cellData = data
    
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetAllianceTitleIcon(data.title), self._p_icon_logo)
    self._p_text_position.text = I18N.Get(data.title:KeyId())
    self._p_noplayer:SetVisible(not data.player)
    self._p_player:SetVisible(data.player and true)
    if data.player then
        self._p_text_name.text = data.player.Name
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if data.cdEndTime and nowTime >= data.cdEndTime then
        self._cd = data.cdEndTime
    else
        self._cd = nil
    end
    self:UpdateBuff()
    self:UpdateButtons()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick)) 
end

function AllianceAppointmentPositionTileCell:OnClickBtnAssignOrReplace()
    if self._cellData.onclick then
        self._cellData.onclick(self._cellData)
    end
end

function AllianceAppointmentPositionTileCell:OnRecycle(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    self._cellData = nil
    self._cd = nil
end

function AllianceAppointmentPositionTileCell:OnTick(dt)
    if not self._cd then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftTime = self._cd - nowTime
    if leftTime > 0 then
    else
        self._cd = nil
        self:UpdateButtons()
    end
end

function AllianceAppointmentPositionTileCell:UpdateBuff()
    for _, v in pairs(self._buffers) do
        v.root:SetVisible(false)
    end
end

function AllianceAppointmentPositionTileCell:UpdateButtons()
    if self._cd then
        self._p_comp_btn_assign:SetVisible(false)
        self._p_comp_btn_replace:SetVisible(false)
        self._p_comp_btn_cd:SetVisible(true)
        return
    end
    self._p_comp_btn_assign:SetVisible(false)
    self._p_comp_btn_replace:SetVisible(false)
    self._p_comp_btn_cd:SetVisible(false)
    if self._cellData.player then
        if self._cellData.targetPlayer.FacebookID == self._cellData.player.FacebookID then
            self._p_comp_btn_replace:SetVisible(true)
            self._p_text_btn_replace.text = I18N.Get("depose")
        else
            self._p_comp_btn_assign:SetVisible(true)
            self._p_text_btn_assign.text = I18N.Get("replace")
        end
    else
        self._p_comp_btn_assign:SetVisible(true)
        if self._cellData.targetPlayerHasTitle then
            self._p_text_btn_assign.text = I18N.Get("replace")
        else
            self._p_text_btn_assign.text = I18N.Get("assign")
        end
    end
end

return AllianceAppointmentPositionTileCell