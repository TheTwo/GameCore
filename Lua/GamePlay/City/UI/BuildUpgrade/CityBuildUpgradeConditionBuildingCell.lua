local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local I18N = require("I18N")

---@class CityBuildUpgradeConditionBuildingCell:BaseUIComponent
local CityBuildUpgradeConditionBuildingCell = class('CityBuildUpgradeConditionBuildingCell', BaseUIComponent)

---@class CityBuildUpgradeConditionBuildingCellData
---@field info BuildingLevelPrecondition
---@field buildings wds.CastleBuildingInfo[]

local countStr = "x%d"
local hintLevel = "build_resourceneeds"
local hintBuild = "build_preneeds"

function CityBuildUpgradeConditionBuildingCell:OnCreate()
    self._p_btn_icon = self:Button("p_btn_icon", Delegate.GetOrCreate(self, self.OnHintClick))
    self._p_img_building_need = self:Image("p_img_building_need")
    self._p_quantity = self:GameObject("p_quantity")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_lv = self:GameObject("p_lv")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_name = self:Text("p_text_name")
    self._p_base_save = self:GameObject("p_base_save")

    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClick))
    self._p_text_goto = self:Text("p_text_goto")
end

---@param data CityBuildUpgradeConditionBuildingCellData
function CityBuildUpgradeConditionBuildingCell:OnFeedData(data)
    self.data = data
    
    self.typCell = ConfigRefer.BuildingTypes:Find(data.info:BuildingType())
    g_Game.SpriteManager:LoadSprite(self.typCell:Image(), self._p_img_building_need)

    local count = data.info:Count()
    local multiNeed = count > 1
    self._p_quantity:SetActive(multiNeed)
    if multiNeed then
        self._p_text_quantity.text = countStr:format(count)
    end
    self._p_base_save:SetActive(multiNeed)
    self._p_text_lv.text = tostring(data.info:Level())
    self._p_text_name.text = I18N.Get(self.typCell:Name())

    if #data.buildings < count then
        self._p_text_goto.text = I18N.Get("build_btn_building")
    else
        self._p_text_goto.text = I18N.Get("build_btn_levelup")
    end
end

function CityBuildUpgradeConditionBuildingCell:OnHintClick()
    if self.data.info:Count() > 1 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(hintLevel, self.data.info:Count(), self.data.info:Level(), I18N.Get(self.typCell:Name())))
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(hintBuild, self.data.info:Count(), I18N.Get(self.typCell:Name())))
    end
end

function CityBuildUpgradeConditionBuildingCell:OnGotoClick()
    
end

return CityBuildUpgradeConditionBuildingCell