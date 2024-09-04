local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')

---@class RadarUpgradeQualityCellComp : BaseUIComponent
local RadarUpgradeQualityCellComp = class('RadarUpgradeQualityCellComp', BaseUIComponent)

---@class RadarUpgradeQualityCellParam
---@field curNum string
---@field nextNum string
---@field color CS.UnityEngine.Color
---@field isMax boolean

function RadarUpgradeQualityCellComp:OnCreate()
    self.textCurNum = self:Text('p_text_num_2')
    self.imgCurNumBase = self:Image('p_base_num_2')
    self.goArrow = self:GameObject('arrow')
    self.textNextNum = self:Text('p_text_add_2')
    self.imgNextNumBase = self:Image('p_base_next_2')
end

---@param param RadarUpgradeQualityCellParam
function RadarUpgradeQualityCellComp:OnFeedData(param)
    if not param then
        return
    end
    if param.isMax then
        self.textCurNum.gameObject:SetActive(false)
        self.goArrow.gameObject:SetActive(false)
    else
        self.textCurNum.gameObject:SetActive(true)
        self.goArrow.gameObject:SetActive(true)
        self.textCurNum.text = param.curNum
    end
    self.textNextNum.text = param.nextNum
    if param.quality then
        local frame = ModuleRefer.RadarModule:GetRadarQualityFrame(param.quality)
        g_Game.SpriteManager:LoadSprite(frame,self.imgCurNumBase)
    end
end

return RadarUpgradeQualityCellComp