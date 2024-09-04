local UIRaisePowerPopupMediatorContentProvider = require("UIRaisePowerPopupMediatorContentProvider")
---@class CommonNpcServiceGotoProvider:UIRaisePowerPopupMediatorContentProvider
---@field new fun():CommonNpcServiceGotoProvider
local CommonNpcServiceGotoProvider = class("CommonNpcServiceGotoProvider", UIRaisePowerPopupMediatorContentProvider)
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local NpcServiceUnlockCondType = require("NpcServiceUnlockCondType")
local I18N = require("I18N")
local Delegate = require("Delegate")

---@param objectType number @NpcServiceObjectType
---@param objectId number
function CommonNpcServiceGotoProvider:ctor(objectType, objectId)
    UIRaisePowerPopupMediatorContentProvider.ctor(self)
    self.objectType = objectType
    self.objectId = objectId
end

function CommonNpcServiceGotoProvider:ShowBottomBtnRoot()
    return false
end

function CommonNpcServiceGotoProvider:GetContinueCallback()
    return nil
end

function CommonNpcServiceGotoProvider:GenerateTableCellData()
    ---@type UIRaisePowerPopupItemCellData[]
    local ret = {}
    local FinishedBitMap = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper.Task.FinishedBitMap or {}
    local playerNpcService = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(self.objectType)[self.objectId].Services or {}
    local NpcService = ConfigRefer.NpcService
    local QuestModule = ModuleRefer.QuestModule
    for serviceId, vStruct in pairs(playerNpcService) do
        local v = vStruct.State
        if wds.NpcServiceState.NpcServiceStateFinished == v then
            goto continue
        end
        if wds.NpcServiceState.NpcServiceStateBeLocked == v then
            local config = NpcService:Find(serviceId)
            if not config then
                goto continue
            end
            local unlockCondCount = config:UnlockCondLength()
            for i = 1, unlockCondCount do
                local unlockCond = config:UnlockCond(i)
                local unlockType = unlockCond:UnlockCondType()
                local condTask = unlockCond:UnlockCondParam()
                if unlockType == NpcServiceUnlockCondType.FinishTask and condTask > 0 then
                    local preTaskConfig = ConfigRefer.Task:Find(condTask)
                    if preTaskConfig then
                        ---@type UIRaisePowerPopupItemCellData
                        local cell = {}
                        if not QuestModule:IsInBitMap(condTask, FinishedBitMap) then
                            local property = preTaskConfig:Property()
                            cell.text = I18N.Get(preTaskConfig:Property():Name())
                            cell.gotoId = property and property:Goto()
                            cell.gotoCallback = Delegate.GetOrCreate(self.hostUIMediator, self.hostUIMediator.CloseSelf)
                        else
                            cell.text = I18N.Get(preTaskConfig:Property():Name())
                            cell.showAsFinished = true
                        end
                        table.insert(ret, cell)
                    end
                end
            end
        end
        ::continue::
    end
    return ret
end

return CommonNpcServiceGotoProvider