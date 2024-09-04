--- scene:scene_common_popup_se_detail

local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")

local BaseUIMediator = require("BaseUIMediator")

---@class SeDetailPopupMediatorParameter
---@field isShowMonster boolean
---@field isShowPet boolean
---@field seConfig MapInstanceConfigCell

---@class SeDetailPopupMediator:BaseUIMediator
---@field new fun():SeDetailPopupMediator
---@field super BaseUIMediator
local SeDetailPopupMediator = class('SeDetailPopupMediator', BaseUIMediator)

function SeDetailPopupMediator:OnCreate(param)
    ---@type SeDetailPopupMonstersComponent
    self._p_content_monster_detail = self:LuaObject("p_content_monster_detail")
    
    self._p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnClickBtnClose))
end

---@param data SeDetailPopupMediatorParameter
function SeDetailPopupMediator:OnOpened(data)
    if data.isShowMonster then
        self._p_content_monster_detail:SetVisible(true)
        ---@type SeNpcConfigCell[]
        local cellsData = {}
        for i = 1, data.seConfig:SeNpcConfLength() do
            local seNpcConfigId = data.seConfig:SeNpcConf(i)
            local seNpcConfig = ConfigRefer.SeNpc:Find(seNpcConfigId)
            table.insert(cellsData, seNpcConfig)
        end
        self._p_content_monster_detail:FeedData(cellsData)
    end
end

function SeDetailPopupMediator:OnClickBtnClose()
    self:CloseSelf()
end

return SeDetailPopupMediator