local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local OnChangeHelper = require("OnChangeHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceMemberAppliesCellListData
---@field Id number
---@field Data wds.AllianceApplicant

---@class AllianceMemberAppliesComponent:BaseUIComponent
---@field new fun():AllianceMemberAppliesComponent
---@field super BaseUIComponent
local AllianceMemberAppliesComponent = class('AllianceMemberAppliesComponent', BaseUIComponent)

function AllianceMemberAppliesComponent:ctor()
    BaseUIComponent.ctor(self)
    ---@type AllianceMemberAppliesCellListData[]
    self._data = {}
end

function AllianceMemberAppliesComponent:OnCreate(param)
    self._p_table_application = self:TableViewPro("p_table_application")
    self._p_text_application_empty = self:Text("p_text_application_empty", "alliance_member_no_application")
    self._p_group_application_empty = self:GameObject("p_group_application_empty")
end

function AllianceMemberAppliesComponent:OnShow(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._p_table_application:Clear()
    table.clear(self._data)
    local applicants = ModuleRefer.AllianceModule:GetMyAllianceApplicants()
    for id, v in pairs(applicants) do
        ---@type AllianceMemberAppliesCellListData
        local cellData = {
            Id = id,
            Data = v
        }
        self._p_table_application:AppendData(cellData)
        table.insert(self._data, cellData)
    end
    self._p_group_application_empty:SetVisible(#self._data <= 0)
    self._p_table_application:SetVisible(#self._data > 0)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceApplicants.Applicants.MsgPath, Delegate.GetOrCreate(self, self.OnApplicantsChanged))
end

function AllianceMemberAppliesComponent:OnHide(param)
    self._allianceId = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceApplicants.Applicants.MsgPath, Delegate.GetOrCreate(self, self.OnApplicantsChanged))
end

---@param entity wds.Alliance
---@param changedData table
function AllianceMemberAppliesComponent:OnApplicantsChanged(entity, changedData)
    if not changedData or not self._allianceId or self._allianceId == 0 or self._allianceId ~= entity.ID then
        return
    end
    local addMap,removeMap,_ = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.AllianceApplicant)
    local count = #self._data
    if removeMap then
        for i = count, 1, -1 do
            local cellData = self._data[i]
            if removeMap[cellData.Id] then
                table.remove(self._data, i)
                self._p_table_application:RemData(cellData)
            end
        end
    end
    if addMap then
        for id, v in pairs(addMap) do
            ---@type AllianceMemberAppliesCellListData
            local cellData = {
                Id = id,
                Data = v
            }
            table.insert(self._data, cellData)
            self._p_table_application:AppendData(v)
        end
    end
    count = #self._data
    self._p_group_application_empty:SetVisible(count <= 0)
    self._p_table_application:SetVisible(count > 0)
end

return AllianceMemberAppliesComponent