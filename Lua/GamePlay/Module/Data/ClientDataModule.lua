local BaseModule = require("BaseModule")

---自定义数据模块
---@class ClientDataModule : BaseModule
local ClientDataModule = class("ClientDataModule", BaseModule)

local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

--- 获取数据
---@param self ClientDataModule
---@param key number 请使用ClientDataKeys中定义的值
---@return string
function ClientDataModule:GetData(key)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if (player and player.PlayerWrapper and player.PlayerWrapper.ClientCustomData and player.PlayerWrapper.ClientCustomData.Data) then
        return player.PlayerWrapper.ClientCustomData.Data[key]
    end
end

--- 设置数据
---@param self ClientDataModule
---@param key number 请使用ClientDataKeys中定义的值
---@param value string 数据, 最长100个字节
function ClientDataModule:SetData(key, value)
    local req = require("SetClientCustomDataParameter").new()
    req.args.Data[key] = value
    req:Send()
end

--- 移除数据
---@param self ClientDataModule
---@param key number 请使用ClientDataKeys中定义的值
function ClientDataModule:RemoveData(key)
    local req = require("RemoveClientCustomDataParameter").new()
    table.insert(req.args.Keys, key)
    req:Send()
end

return ClientDataModule
