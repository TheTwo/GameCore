local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local RPPType = require("RPPType")
local ConfigRefer = require("ConfigRefer")

local UIStrengthenProvider = class('UIStrengthenProvider')

function UIStrengthenProvider:ctor()
    self.hostUIMediator = nil
    self.index = nil
end

function UIStrengthenProvider:SetDefault(param, hostMediator)
    self.hostUIMediator = hostMediator
    self.index = param.index
    local strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    local recommendCfg = ConfigRefer.RecommendPowerTable:Find(strongHoldLv)
    local subTypePower = recommendCfg:SubTypePowers(self.index)
    self.config = self:GetProviderConfig(subTypePower)
end

function UIStrengthenProvider:GetTitle()
    return I18N.Get(self.config:Name())
end

function UIStrengthenProvider:GetHintText()
    return I18N.Get(self.config:ResourceDes())
end

function UIStrengthenProvider:GetContinueCallback()
    return nil
end

function UIStrengthenProvider:GenerateTableCellData()
    local ret = {}
    for i = 1, self.config:ResourceOutputWayLength() do
        local wayCfg = self.config:ResourceOutputWay(i)
        local data = {
            text = I18N.Get(wayCfg:ResourceGetName()),
            gotoId = wayCfg:WayGoto(),
            gotoCallback = Delegate.GetOrCreate(self.hostUIMediator, self.hostUIMediator.CloseSelf),
            systemEntryId = wayCfg:Unlock(),
        }
        table.insert(ret, data)
    end
    return ret
end

function UIStrengthenProvider:GetProviderConfig(subTypePower)
    for _, config in ConfigRefer.PowerProgressResource:ipairs() do
        if config:PowerSubTypes() == subTypePower:SubType() then
            local sysIndex = config:Unlock()
            if sysIndex and sysIndex > 0 then
                local isOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex)
                if isOpen then
                    return config
                end
            else
                return config
            end
        end
    end
    return nil
end

function UIStrengthenProvider:ShowBottomBtnRoot()
    return false
end

return UIStrengthenProvider