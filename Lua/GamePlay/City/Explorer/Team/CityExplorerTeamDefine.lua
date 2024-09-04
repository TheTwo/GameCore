---@type CS.UnityEngine.Vector3
local Vec3 = CS.UnityEngine.Vector3
---@type CS.UnityEngine.Quaternion
local Quaternion = CS.UnityEngine.Quaternion

---@class CityExplorerTeamDefine
local CityExplorerTeamDefine = {}

CityExplorerTeamDefine.Radius = 0.2
CityExplorerTeamDefine.RadiusPet = 0.6
CityExplorerTeamDefine.MaxMemberCount = 3
CityExplorerTeamDefine.StatusIcon = {
    Back = {
        [1] = "sp_common_btn_back_03",
        [2] = "sp_troop_img_state_base_3",
    },
    Attack = {
        [1] = "sp_troop_icon_status_battle",
        [2] = "sp_troop_img_state_base_4",
    },
    Camp = {
        [1] = "sp_city_icon_refugee",
        [2] = "sp_troop_img_state_base_2",
    },
    Move = {
        [1] = "sp_troop_img_state_walk",
        [2] = "sp_troop_img_state_base_1",
    }
}

---@class CityExplorerTeamDefine.InteractEndAction
CityExplorerTeamDefine.InteractEndAction = {
    ToIdle = 0,
    AutoRemove = 1,
    WaitBattleEnd = 2,
    ToIdleAndResetExpectSpawnerId = 3,
}

---@param leaderPos CS.UnityEngine.Vector3
---@param leaderDir CS.UnityEngine.Quaternion
---@return CS.UnityEngine.Vector3
function CityExplorerTeamDefine.CalculateTeamCenterPosition(leaderPos, leaderDir)
    local leaderDirVec = leaderDir * Vec3.forward
    local teamRadius = CityExplorerTeamDefine.Radius
    return leaderPos - leaderDirVec.normalized * teamRadius
end

---@param leaderPos CS.UnityEngine.Vector3
---@param leaderDir CS.UnityEngine.Quaternion
---@param teamRadius number
---@return CS.UnityEngine.Vector3
function CityExplorerTeamDefine.CalculateTeamPetPosition(leaderPos, leaderDir, teamRadius)
    local leaderDirVec = leaderDir * Vec3.forward
    teamRadius = teamRadius or CityExplorerTeamDefine.RadiusPet
    return leaderPos - leaderDirVec.normalized * teamRadius
end

---@param leaderPos CS.UnityEngine.Vector3
---@param leaderDir CS.UnityEngine.Quaternion
---@param index number
---@return CS.UnityEngine.Vector3
function CityExplorerTeamDefine.CalculateTeamUnitPosition(leaderPos, leaderDir, index)
    if index < 2 then
        return leaderPos
    end
    local leaderDirEulerAngles = leaderDir.eulerAngles
    local teamRadius = CityExplorerTeamDefine.Radius
    local teamCenter = CityExplorerTeamDefine.CalculateTeamCenterPosition(leaderPos, leaderDir)
    local dir
    if index < 3 then
        dir = Vec3(leaderDirEulerAngles.x, leaderDirEulerAngles.y + 120, leaderDirEulerAngles.z)
    elseif index < 4 then
        dir = Vec3(leaderDirEulerAngles.x, leaderDirEulerAngles.y - 120, leaderDirEulerAngles.z)
    else
        dir = Vec3(leaderDirEulerAngles.x, leaderDirEulerAngles.y + 180, leaderDirEulerAngles.z)
        teamRadius = teamRadius * (index - CityExplorerTeamDefine.MaxMemberCount)
    end
    local dirVec = Quaternion.Euler(dir) * Vec3.forward
    local pos = teamCenter + dirVec.normalized * teamRadius
    return pos
end

---@param leaderPos CS.UnityEngine.Vector3
---@param leaderDir CS.UnityEngine.Quaternion
---@return CS.UnityEngine.Vector3
function CityExplorerTeamDefine.CalculatePetFollowUnitPosition(leaderPos, leaderDir, teamRadius)
    local teamCenter = CityExplorerTeamDefine.CalculateTeamPetPosition(leaderPos, leaderDir, teamRadius)
    return teamCenter
end

return CityExplorerTeamDefine

