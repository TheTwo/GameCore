local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local TurnTableConst = require('TurnTableConst')
local UIHelper = require('UIHelper')
---@class TurnTableDisk : BaseUIComponent
local TurnTableDisk = class('TurnTableDisk', BaseUIComponent)

local QUALITY_COLOR = {
    "#EEE5DD",
    "#7EB56C",
    "#758BB3",
    "#A97DC0",
    "#E68855"
}

function TurnTableDisk:OnCreate()
    -- self.imgBase = self:Image('p_base')
    self.imgSelect = self:Image('p_img_select')
    self.imgQuality = self:Image('p_img_quality')
    self.imgLine = self:Image('p_line')
    self.goDisk = self:GameObject('')
    self.goLine = self:GameObject('p_line')
end

function TurnTableDisk:OnFeedData(param)
    if not param then
        return
    end
    self.itemId = param.itemId
    self.quality = ConfigRefer.Item:Find(self.itemId):Quality()
    local color = QUALITY_COLOR[self.quality]
    self.imgQuality.color = UIHelper.TryParseHtmlString(color)
    self:SetSelect(false)
    self.goLine.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, -90)
end

function TurnTableDisk:SetFillAmount(fillAmount)
    -- self.imgBase.fillAmount = fillAmount
    self.imgSelect.fillAmount = fillAmount
    self.imgQuality.fillAmount = fillAmount
end

function TurnTableDisk:SetOffset(offset)
    local z = self.goDisk.transform.localRotation.z
    local zLine = self.goLine.transform.localRotation.z
    self.goDisk.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, z + offset)
    -- self.goLine.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, zLine + offset)
end

function TurnTableDisk:SetSelect(isSelect)
    -- self.imgBase.gameObject:SetActive(true)
    self.imgSelect.gameObject:SetActive(isSelect)
end

function TurnTableDisk:SetTransparency()
    -- self.imgBase.color = CS.UnityEngine.Color(1, 1, 1, 0)
    self.imgSelect.color = CS.UnityEngine.Color(1, 1, 1, 0)
    self.imgQuality.color = CS.UnityEngine.Color(1, 1, 1, 0)
    self.imgLine.color = CS.UnityEngine.Color(1, 1, 1, 0)
end

return TurnTableDisk