local Delegate = require("Delegate")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceBuildingDetailItemSkillCellData
---@field techConfig AllianceTechnologyConfigCell

---@class AllianceBuildingDetailItemSkillCell:BaseTableViewProCell
---@field new fun():AllianceBuildingDetailItemSkillCell
---@field super BaseTableViewProCell
local AllianceBuildingDetailItemSkillCell = class('AllianceBuildingDetailItemSkillCell', BaseTableViewProCell)

function AllianceBuildingDetailItemSkillCell:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickBtnCell))
    self._p_icon_skill = self:Image("p_icon_skill")
    self._p_type_b_skill = self:Image("p_type_b_skill")
    self._p_type_c_skill = self:Image("p_type_c_skill")
    self._p_text_name_skill = self:Text("p_text_name_skill")
    self._p_img_jump = self:Image("p_img_jump")
end

---@param data AllianceBuildingDetailItemSkillCellData
function AllianceBuildingDetailItemSkillCell:OnFeedData(data)
    self._data = data
    self._p_type_b_skill:SetVisible(false)
    self._p_type_c_skill:SetVisible(false)
    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(data.techConfig:Icon()), self._p_icon_skill)
    self._p_text_name_skill.text = I18N.Get(data.techConfig:Name())
end

function AllianceBuildingDetailItemSkillCell:OnClickBtnCell()
    if not self._data or not self._data.techConfig then
        return
    end
    self:GetParentBaseUIMediator():CloseSelf()
    ---@type AllianceTechResearchMediatorParameter
    local mediatorParameter = {}
    mediatorParameter.enterFocusSelect = true
    mediatorParameter.enterFocusOnGroup = self._data.techConfig:Group()
    g_Game.UIManager:Open(UIMediatorNames.AllianceTechResearchMediator, mediatorParameter)
end

return AllianceBuildingDetailItemSkillCell