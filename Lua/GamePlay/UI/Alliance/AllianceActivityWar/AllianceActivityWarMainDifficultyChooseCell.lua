local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceActivityWarMainDifficultyChooseCellData
---@field isLocked boolean
---@field title string
---@field content string

---@class AllianceActivityWarMainDifficultyChooseCell:BaseUIComponent
---@field new fun():AllianceActivityWarMainDifficultyChooseCell
---@field super BaseUIComponent
local AllianceActivityWarMainDifficultyChooseCell = class('AllianceActivityWarMainDifficultyChooseCell', BaseUIComponent)

function AllianceActivityWarMainDifficultyChooseCell:ctor()
    self.clickFunc = nil
    self.index = nil
end

function AllianceActivityWarMainDifficultyChooseCell:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtnSelf))
    self._p_lock = self:GameObject('p_lock')
    self._p_text_difficulty = self:Text("p_text_difficulty")
    self._p_text_num = self:Text("p_text_num")
end

---@param data AllianceActivityWarMainDifficultyChooseCellData
function AllianceActivityWarMainDifficultyChooseCell:OnFeedData(data)
    self._p_lock:SetVisible(data.isLocked)
    self._p_text_difficulty.text = data.title
    self._p_text_num.text = data.content
end

function AllianceActivityWarMainDifficultyChooseCell:OnClickBtnSelf()
    if self.clickFunc then
        self.clickFunc(self.index)
    end
end

return AllianceActivityWarMainDifficultyChooseCell