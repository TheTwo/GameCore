---@class CityExplorerStateDefine
local CityExplorerStateDefine = {}

---@class CityExplorerStateDefine.BlackboardKey
CityExplorerStateDefine.BlackboardKey = {
    TargetPos = "TargetPos",
    TargetGridCell = "TargetGridCell",
    TargetId = "TargetId",
    TargetRadius = "TargetRadius",
    TargetWayPoints = "TargetWayPoints",
    TargetIdleWalkRange = "TargetIdleWalkRange",
    TargetIsGround = "TargetIsGround",
    TargetFromPlayerClick = "TargetFromPlayerClick",
}

---@class CityExplorerStateDefine.AnimatorState
CityExplorerStateDefine.AnimatorState = {
    idle = CS.UnityEngine.Animator.StringToHash("idle"),
    walk = CS.UnityEngine.Animator.StringToHash("walk"),
    run = CS.UnityEngine.Animator.StringToHash("run"),
    operate = CS.UnityEngine.Animator.StringToHash("pickup"),
    talk = CS.UnityEngine.Animator.StringToHash("pickup"),
}

return CityExplorerStateDefine

