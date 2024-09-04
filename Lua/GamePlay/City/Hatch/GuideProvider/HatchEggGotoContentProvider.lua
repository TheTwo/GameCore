local UIRaisePowerPopupMediatorContentProvider = require("UIRaisePowerPopupMediatorContentProvider")

---@class HatchEggGotoContentProvider:UIRaisePowerPopupMediatorContentProvider
---@field super UIRaisePowerPopupMediatorContentProvider
---@field new fun():HatchEggGotoContentProvider
local HatchEggGotoContentProvider = class("HatchEggGotoContentProvider", UIRaisePowerPopupMediatorContentProvider)
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local Delegate = require("Delegate")

---@param zoneManager CityZoneManager
---@param zone CityZone
function HatchEggGotoContentProvider:ctor()
    self.cellData = {}
    ---NOTE:写死的GetMore配置Id，设计来源自赵薏寒
    local getmoreList = {69002, 700003, 700004}
    for _, cfgId in ipairs(getmoreList) do
        local getmoreCfg = ConfigRefer.GetMore:Find(cfgId)
        if getmoreCfg then
            for i = 1, getmoreCfg:GotoLength() do
                local gotoCfg = getmoreCfg:Goto(i)
                if gotoCfg:Goto() > 0 then
                    table.insert(self.cellData, {
                        text = I18N.Get(gotoCfg:Desc()),
                        showAsFinished = false,
                        gotoId = gotoCfg:Goto(),
                        gotoCallback = Delegate.GetOrCreate(self, self.GotoCallback),
                    })
                end
            end
        end
    end
end

function HatchEggGotoContentProvider:ShowBottomBtnRoot()
    return false
end

function HatchEggGotoContentProvider:GetTitle()
    return I18N.Get("getmore_goto")
end

function HatchEggGotoContentProvider:GetHintText()
    return string.Empty
end

---@param param RaisePowerPopupParam
---@param mediator UIRaisePowerPopupMediator
function HatchEggGotoContentProvider:SetDefault(param, mediator)
    self.param = param
    self.mediator = mediator
end

---@return UIRaisePowerPopupItemCellData[]
function HatchEggGotoContentProvider:GenerateTableCellData()
    return self.cellData
end

function HatchEggGotoContentProvider:GotoCallback()
    if not self.mediator then return end
    self.mediator:CloseSelf()
end

return HatchEggGotoContentProvider