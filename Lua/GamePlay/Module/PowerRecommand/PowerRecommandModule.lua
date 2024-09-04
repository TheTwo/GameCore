local BaseModule = require("BaseModule")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CultivateDataProvider = require("CultivateDataProvider")
---@class PowerRecommandModule : BaseModule
local PowerRecommandModule = class("PowerRecommandModule", BaseModule)

function PowerRecommandModule:ctor()
end

function PowerRecommandModule:OnRegister()
end

function PowerRecommandModule:OnRemove()
end

---@param preset wds.TroopPreset
function PowerRecommandModule:GetCurRecommandTypes(preset)
    local lvl = ModuleRefer.PlayerModule:StrongholdLevel()
    local providers = {}
    local ret = {}
    for _, cfg in ConfigRefer.CultivateType:pairs() do
        ---@type CultivateDataProvider
        local provider = CultivateDataProvider.new(cfg:Id(), preset)
        table.insert(providers, provider)
    end
    table.sort(providers, function(a, b)
        return a:GetCultivatePrecent(lvl) < b:GetCultivatePrecent(lvl)
    end)
    for i = 1, 3 do
        table.insert(ret, providers[i])
    end
    return ret
end

return PowerRecommandModule