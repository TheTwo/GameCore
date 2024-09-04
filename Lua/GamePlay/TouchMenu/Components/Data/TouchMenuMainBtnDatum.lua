---@class TouchMenuMainBtnDatum
---@field new fun(label, onClick:fun(onClickDatum:any, trans:CS.UnityEngine.Transform), onClickDatum,extraLabel,extraLabelColor,extraImage,enable,onClickDisable):TouchMenuMainBtnDatum
---@field onClick fun(onClickDatum:any, trans:CS.UnityEngine.Transform)
local TouchMenuMainBtnDatum = class("TouchMenuMainBtnDatum")
local TouchMenuMainBtnStyle = {
    Pink = 1,
    Black = 2,
}
TouchMenuMainBtnDatum.Style = TouchMenuMainBtnStyle

function TouchMenuMainBtnDatum:ctor(label, onClick, onClickDatum, extraLabel, extraLabelColor, extraImage, enable, onClickDisable, customImage, customDisableImage, style)
    self.label = label
    self.onClick = onClick
    self.onClickDatum = onClickDatum
    self.extraLabel = extraLabel
    self.extraLabelColor = extraLabelColor
    self.extraImage = extraImage
    self.enable = (enable == nil) and true or enable
    self.onClickDisable = onClickDisable
    self.customImage = customImage or "sp_btn_green_nml_s_u2"
    self.customDisableImage = customDisableImage or "sp_btn_gray_nml_s_u2"
    self.style = style or TouchMenuMainBtnStyle.Pink
    if UNITY_EDITOR or UNITY_DEBUG then
        self.where = debug.traceback()
    end
end

---@param onClick fun(onClickDatum:any, trans:CS.UnityEngine.Transform)
---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetOnClick(onClick)
    self.onClick = onClick
    if UNITY_EDITOR or UNITY_DEBUG then
        self.where = debug.traceback()
    end
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetExtraLabel(label)
    self.extraLabel = label
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetExtraLabelColor(color)
    self.extraLabelColor = color
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetExtraImage(image)
    self.extraImage = image
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetEnable(enable)
    self.enable = enable
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetOnClickDisable(onClickDisable)
    self.onClickDisable = onClickDisable
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetCustomImage(image)
    self.customImage = image
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetCustomDisableImage(image)
    self.customDisableImage = image
    return self
end

---@return TouchMenuMainBtnDatum
function TouchMenuMainBtnDatum:SetOnClickDatum(datum)
    self.onClickDatum = datum
    return self
end

function TouchMenuMainBtnDatum:SetStyle(style)
    self.style = style
    return self
end

return TouchMenuMainBtnDatum