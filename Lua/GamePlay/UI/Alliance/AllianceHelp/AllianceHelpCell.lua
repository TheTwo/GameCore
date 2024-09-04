local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceHelpCellData
---@field serverData wds.AllianceHelpInfo

---@class AllianceHelpCell:BaseTableViewProCell
---@field new fun():AllianceHelpCell
---@field super BaseTableViewProCell
local AllianceHelpCell = class('AllianceHelpCell', BaseTableViewProCell)

function AllianceHelpCell:OnCreate(param)
    ---@see PlayerInfoComponent
    self._child_ui_head_player = self:LuaBaseComponent("child_ui_head_player")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_content = self:Text("p_text_content")
    self._p_progress = self:Slider("p_progress")
    self._p_text_num = self:Text("p_text_num")
    self._p_text_time = self:Text("p_text_time")
end

---@param data AllianceHelpCellData
function AllianceHelpCell:OnFeedData(data)
    local info = data.serverData
    local member = ModuleRefer.AllianceModule:QueryMyAllianceMemberDataByPlayerId(info.PlayerID)
    self._p_text_name.text = member and member.Name or string.Empty
    self._child_ui_head_player:FeedData(member)
    self._p_text_content.text = AllianceHelpCell.GetRequestHelpContent(info)
    self._p_progress.value = math.inverseLerp(0, info.MaxCount, info.Count)
    self._p_text_num.text = ("%d/%d"):format(info.Count, info.MaxCount)
    local time = info.DecreaseTime * info.Count
    if time > 60 then
        self._p_text_time.text = I18N.GetWithParams("alliance_help_timereduce", tostring(time // 60).."min")
    else
        self._p_text_time.text = I18N.GetWithParams("alliance_help_timereduce", tostring(time).."s")
    end
end

---@param info wds.AllianceHelpInfo
function AllianceHelpCell.GetRequestHelpContent(info)
    local furnitureConfig = ConfigRefer.CityFurnitureLevel:Find(info.TargetCfgId)
    if furnitureConfig then
        local furnitureTypeCfg = ConfigRefer.CityFurnitureTypes:Find(furnitureConfig:Type())
        if furnitureTypeCfg then
            local lv = furnitureConfig:Level()
            if lv == 0 then
                return I18N.GetWithParams("alliance_help_buildhelp", I18N.Get(furnitureTypeCfg:Name()))
            end
            return I18N.GetWithParams("alliance_help_lvuphelp", I18N.Get(furnitureTypeCfg:Name()),  tostring(lv + 1))
        end
    end
    return string.Empty
end

return AllianceHelpCell