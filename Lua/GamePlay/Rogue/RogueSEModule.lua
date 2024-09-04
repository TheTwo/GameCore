local BaseModule = require ('BaseModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class RogueSEModule:BaseModule
local RogueSEModule = class('RogueSEModule', BaseModule)

function RogueSEModule:OnRegister()
    self.createHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("RogueSEModule")
end

function RogueSEModule:OnRemove()
    self.createHelper:DeleteAll()
    self.createHelper = nil
end

function RogueSEModule:GetPooledCreateHelper()
    return self.createHelper
end

---@return number[]
function RogueSEModule:GetHeroListInTroop()
    return {}
end

return RogueSEModule