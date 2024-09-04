local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local BasicCamera = require("BasicCamera")

local BaseBehaviour = require('BaseBehaviour')

---@class ShowBubbleDialog:BaseBehaviour
local ShowBubbleDialog = class("ShowBubbleDialog", BaseBehaviour)
local m_Instance

---@return ShowBubbleDialog
function ShowBubbleDialog.Instance()
    if m_Instance == nil then
        m_Instance = ShowBubbleDialog.new()
    end
    return m_Instance
end

function ShowBubbleDialog:ctor()
    ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
    self._goCreator = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create()
    self._inUsing = {}
    self._created = {}
end

---@param args any
---@return void
function ShowBubbleDialog:OnStart(args)
    local bubbleId = args[1]
    ---@type CS.UnityEngine.GameObject
    local targetNpc = args[2]
    ---@type CS.UnityEngine.Camera
    local camera = args[3]
    if not bubbleId or Utils.IsNull(targetNpc) then
        return
    end
    local goId = tostring(bubbleId) .. '_' .. tostring(targetNpc:GetInstanceID())
    self._inUsing[goId] = true
    local asset = ArtResourceConsts.ui3d_bubble_timeline_npc_talk
    self._goCreator:Create(ArtResourceUtils.GetItem(asset), targetNpc.transform, function(go)
        ---@type CS.UnityEngine.GameObject
        if Utils.IsNull(go) then
            return
        end
        if not self._inUsing[goId] then
            CS.DragonReborn.AssetTool.GameObjectCreateHelper.DestroyGameObject(go)
            return
        end
        self._created[goId] = go
        local luaScript = go:GetLuaBehaviour("StoryTimelineTalkBubble")
        if luaScript then
            ---@type StoryTimelineTalkBubble
            local bubble = luaScript.Instance
            if bubble then
                if Utils.IsNull(camera) then
                    if BasicCamera.CurrentBasicCamera then
                        camera = BasicCamera.CurrentBasicCamera:GetUnityCamera()
                    end
                end
                bubble:SetContent(bubbleId, camera)
            end
        end
    end)
end

---@param args any
---@return void
function ShowBubbleDialog:OnEnd(args)
    local dialogId = args[1]
    local targetNpc = args[2]
    if not dialogId or Utils.IsNull(targetNpc) then
        return
    end
    local goId = tostring(dialogId) .. '_' .. tostring(targetNpc:GetInstanceID())
    if not self._inUsing[goId] then
        return
    end
    self._inUsing[goId] = nil
    local go = self._created[goId]
    if Utils.IsNotNull(go) then
        CS.DragonReborn.AssetTool.GameObjectCreateHelper.DestroyGameObject(go)
    end
    self._created[goId] = nil
end

return ShowBubbleDialog