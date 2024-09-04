local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
local City3DBubbleStandard = require("City3DBubbleStandard")
local NpcServiceType = require("NpcServiceType")
local AudioConsts = require("AudioConsts")

local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateService:CitizenBubbleState
---@field new fun():CitizenBubbleStateService
---@field super CitizenBubbleState
local CitizenBubbleStateService = class('CitizenBubbleStateService', CitizenBubbleState)

function CitizenBubbleStateService:Enter()
    self._bubble = self._bubbleMgr:QueryBubble(2)
    if self._bubble then
        self._bubble._attachTrans = self._citizen.model:Transform()
        self._bubble:SetActive(true)
        self._bubble:Reset()
        local icon = "sp_city_icon_chat"
        local iconBg = City3DBubbleStandard.GetDefaultNormalBg()
        local iconEffect = string.Empty
        local triggerAni = nil
        local servicesGroup = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.Citizen)[self._citizen._data._id]
        if servicesGroup then
            if (ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(servicesGroup, NpcServiceType.ReceiveItem)) then
                triggerAni = 1
            end
            local has = ModuleRefer.PlayerServiceModule:HasInteractableService(servicesGroup)
            if has then
                local c = ConfigRefer.NpcServiceGroup:Find(servicesGroup.ServiceGroupTid)
                if c then
                    if not string.IsNullOrEmpty(c:Icon()) then
                        icon = c:Icon()
                    end
                    if not string.IsNullOrEmpty(c:BubbleIconBg()) then
                        iconBg = c:BubbleIconBg()
                    end
                    iconEffect = c:BubbleIconEffect()
                end
            end
        end
        ---@type CityCitizenBubbleTipTaskContext
        local context = {}
        context.icon = icon
        context.callback = Delegate.GetOrCreate(self, self.OnClickIcon)
        context.bg = iconBg
        context.effect = iconEffect
        context.triggerAni = triggerAni
        self._bubble:SetupTask(context)
    end
end

function CitizenBubbleStateService:OnClickIcon()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    self:OnClickTask()
end

function CitizenBubbleStateService:OnClickTask()
    ModuleRefer.PlayerServiceModule:InteractWithTarget(NpcServiceObjectType.Citizen, self._citizen._data._id, true)
end

function CitizenBubbleStateService:GetCurrentBubbleTrans()
    if not self._bubble then return nil end
    local tipHandle = self._bubble
    if not tipHandle or not tipHandle._tip then return nil end
    if Utils.IsNull(tipHandle._tip.p_bubble_npc_trigger) then return nil end
    return tipHandle._tip.p_bubble_npc_trigger.transform
end

return CitizenBubbleStateService