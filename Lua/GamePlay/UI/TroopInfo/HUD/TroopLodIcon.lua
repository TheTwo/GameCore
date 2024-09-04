local KingdomMapUtils = require("KingdomMapUtils")
local EventConst = require('EventConst')
local Delegate = require("Delegate")

local One = CS.UnityEngine.Vector3.one
local Up = CS.UnityEngine.Vector3.up
local Vector3 = CS.UnityEngine.Vector3
local Quaternion = CS.UnityEngine.Quaternion

---@class TroopLodIcon
---@field facingCamera CS.U2DFacingCamera
---@field p_status_player CS.UnityEngine.GameObject
---@field p_status_enemy CS.UnityEngine.GameObject
---@field p_status_friend CS.UnityEngine.GameObject
---@field p_icon_arrow CS.UnityEngine.GameObject
---@field p_progress_player CS.U2DSpriteMesh
---@field p_progress_enemy CS.U2DSpriteMesh
---@field p_progress_friend CS.U2DSpriteMesh
local TroopLodIcon = class("TroopLodIcon")

function TroopLodIcon:Awake()
    self.facingCamera.FacingCamera = KingdomMapUtils.GetBasicCamera().mainCamera
end

---@param troopCtrl TroopCtrl
function TroopLodIcon:FeedData(troopCtrl)
    if troopCtrl:IsSelf() then
        self.p_status_player:SetVisible(true)
        self.p_status_enemy:SetVisible(false)
        self.p_status_friend:SetVisible(false)
    elseif troopCtrl:IsFriendly() then
        self.p_status_player:SetVisible(false)
        self.p_status_enemy:SetVisible(false)
        self.p_status_friend:SetVisible(true)
    else
        self.p_status_player:SetVisible(false)
        self.p_status_enemy:SetVisible(true)
        self.p_status_friend:SetVisible(false)
    end
end

---@param troopCtrl TroopCtrl
function TroopLodIcon:UpdateHP(troopCtrl)
    local progress = troopCtrl._data.Battle.Hp / troopCtrl._data.Battle.MaxHp
    if troopCtrl:IsSelf() then
        self.p_progress_player.fillAmount = progress
    elseif troopCtrl:IsFriendly() then
        self.p_progress_friend.fillAmount = progress
    else
        self.p_progress_enemy.fillAmount = progress
    end
end

---@param forward CS.UnityEngine.Vector3
function TroopLodIcon:UpdateDirection(forward)
    local angle = 315 - Quaternion.LookRotation(forward, Up).eulerAngles.y
    self.p_icon_arrow.transform.localEulerAngles = Vector3(0, 0, angle)
end

function TroopLodIcon:SetVisible(state)
    self.facingCamera.transform:SetVisible(state)
end

return TroopLodIcon