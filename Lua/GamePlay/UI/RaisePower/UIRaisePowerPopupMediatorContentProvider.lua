local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local RPPType = require("RPPType")
local ConfigRefer = require("ConfigRefer")

---@class UIRaisePowerPopupMediatorContentProvider
---@field new fun():UIRaisePowerPopupMediatorContentProvider
local UIRaisePowerPopupMediatorContentProvider = class('UIRaisePowerPopupMediatorContentProvider')

function UIRaisePowerPopupMediatorContentProvider:ctor()
    ---@protected
    ---@type BaseUIMediator
    self.hostUIMediator = nil
    ---@private
    self.continueCallback = nil
    ---@private
    ---@type number RPPType
    self.type = nil
end

---@param param RaisePowerPopupParam
---@param hostMediator BaseUIMediator
function UIRaisePowerPopupMediatorContentProvider:SetDefault(param, hostMediator)
    self.continueCallback = param.continueCallback
    self.hostUIMediator = hostMediator
    self.type = param.type
end

function UIRaisePowerPopupMediatorContentProvider:GetTitle()
    return I18N.Get("rpp_title")    
end

function UIRaisePowerPopupMediatorContentProvider:GetHintText()
    return I18N.Get("rpp_des")
end

function UIRaisePowerPopupMediatorContentProvider:GetContinueCallback()
    return self.continueCallback
end

---@return UIRaisePowerPopupItemCellData[]
function UIRaisePowerPopupMediatorContentProvider:GenerateTableCellData()
    local type = self.type or RPPType.Default
    local cityLevel = ModuleRefer.PlayerModule:StrongholdLevel()
    local ret = {}
    for _, cell in ConfigRefer.RaisePowerPopup:ipairs() do
        local level = cell.UnlockLevel and cell:UnlockLevel() or 0
        if (cell:RPPTypeEnum() == type and cityLevel >= level) then
            ---@type UIRaisePowerPopupItemCellData
            local data = {
                iconId = cell:EntryPic(),
                text = I18N.Get(cell:EntryDes()),
                gotoId = cell:EntryGoto(),
                gotoCallback = Delegate.GetOrCreate(self.hostUIMediator, self.hostUIMediator.CloseSelf),
            }
            table.insert(ret, data)
        end
    end
    return ret
end

---@return boolean
function UIRaisePowerPopupMediatorContentProvider:ShowBottomBtnRoot()
    return true
end

return UIRaisePowerPopupMediatorContentProvider