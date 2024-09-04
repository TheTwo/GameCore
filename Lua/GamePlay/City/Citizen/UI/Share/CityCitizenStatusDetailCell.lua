local BaseTableViewProCell = require("BaseTableViewProCell")

---@class CityCitizenStatusDetailCellData
---@field buffIconFlag number @0-hide,1-up,2-down,4-green,8-red,16-ignore
---@field icon string
---@field valueFiled string
---@field nameField string
---@field customColor CS.UnityEngine.Color

---@class CityCitizenStatusDetailCell:BaseTableViewProCell
---@field new fun():CityCitizenStatusDetailCell
---@field super BaseTableViewProCell
local CityCitizenStatusDetailCell = class('CityCitizenStatusDetailCell', BaseTableViewProCell)

function CityCitizenStatusDetailCell:OnCreate(param)
    self._p_icon_buff_1 = self:Image("p_icon_buff_1")
    self._p_text_buff_1 = self:Text("p_text_buff_1")
    self._p_icon_buff_2 = self:Image("p_icon_buff_2")
    self._p_text_buff_2 = self:Text("p_text_buff_2")
end

---@param data CityCitizenStatusDetailCellData
function CityCitizenStatusDetailCell:OnFeedData(data)
    local buffIconFlag = data.buffIconFlag or 0
    self._p_icon_buff_1:SetVisible(buffIconFlag == 0)
    if buffIconFlag ~= 0 then
        if (data.buffIconFlag & 1) ~= 0 then
            local p = self._p_icon_buff_1.rectTransform.localScale
            p.y = math.abs(p.y)
            self._p_icon_buff_1.rectTransform.localScale = p
        elseif (data.buffIconFlag & 2) ~= 0 then
            local p = self._p_icon_buff_1.rectTransform.localScale
            p.y = math.abs(p.y) * -1
            self._p_icon_buff_1.rectTransform.localScale = p
        end
        if data.customColor then
            self._p_icon_buff_1.color = data.customColor
        else
            if (data.buffIconFlag & 4) ~= 0 then
                self._p_icon_buff_1.color = CS.UnityEngine.Color.green
            elseif (data.buffIconFlag & 8) ~= 0 then
                self._p_icon_buff_1.color = CS.UnityEngine.Color.red
            elseif (data.buffIconFlag & 16) == 0 then
                self._p_icon_buff_1.color = CS.UnityEngine.Color.white
            end
        end
    end
    self._p_text_buff_1.text = data.valueFiled
    self._p_text_buff_2.text = data.nameField
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_buff_2)
end

return CityCitizenStatusDetailCell