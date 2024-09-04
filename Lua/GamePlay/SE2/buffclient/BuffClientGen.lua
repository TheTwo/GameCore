-- auto gen. do not modify

---@class buffclient.gen
local gen = {
  
    Type = {
      Effect = 0,
      ScreenEffect = 1,
      BuffUI = 2,
      ModelModify = 3,
      AnimatorParameters = 4,
      NodeVisible = 5,
      MaterialAppend = 6,
    },
  
    Type2name = {
      [0] = "buffclient.behavior.BuffEffect",
      [1] = "buffclient.behavior.BuffScreenEffect",
      [2] = "buffclient.behavior.BuffBuffUI",
      [3] = "buffclient.behavior.BuffModelModify",
      [4] = "buffclient.behavior.BuffAnimatorParameters",
      [5] = "buffclient.behavior.BuffNodeVisible",
      [6] = "buffclient.behavior.BuffMaterialAppend",
    },
  
    Priority = {
      Sneak = 0,
      General = 1,
      Strong = 2,
    },
  
    AnimLayer = {
      Base = 0,
      OverrideDown = 1,
      OverrideUp = 2,
    },
  
    Attach = {
      SelfRoot = 0,
      OtherRoot = 1,
      AttachNodeSelf = 2,
      AttachNodeOther = 3,
    },
  
    DirTarget = {
      Attacker = 0,
      Defender = 1,
      Server = 2,
    },
  
    Shape = {
      Rectangle = 0,
      Round = 1,
      Sector = 2,
      RoundFriendly = 4,
    },
  
    DamageTextType = {
      Normal = 0,
      Skill = 1,
    },
  
    SkillEventType = {
      LockSelf = 0,
    },
  
    MoveDirectionType = {
      SkillPos = 1,
      SkillDir = 2,
      ConnectionDir = 3,
      TargetPos = 4,
      FixedDistance = 5,
    },
  
    SkillMovePosType = {
      None = 0,
      ReleaserPos = 1,
      RoundPos = 2,
      TargetPos = 3,
    },
  
    Direction = {
      Forward = 0,
      Reverse = 1,
    },
  
    BuffUIType = {
      Icon = 1,
      Text = 2,
    },
  
    EParamType = {
      UseFloat = 0,
      AttackAngle = 10,
    },
  
    ProjectileType = {
      Immediate = 0,
      Line = 1,
      HeightFixedParabola = 2,
      HorizontalDominantParabola = 3,
      TrackingTarget = 4,
    },
  
    FanAngle = {
      _45 = 0,
      _90 = 1,
      _135 = 2,
      _180 = 3,
    },
  
    ShakeType = {
      Constant = 0,
      EaseIn = 1,
      EaseOut = 2,
      EaseInOut = 3,
    },
  
    NoiseType = {
      Perlin = 0,
      Sin = 1,
    },
  
}

---@class SkillEditor.EditorVector3
---@field x number
---@field y number
---@field z number

---@class SkillEditor.EditorColor
---@field r number
---@field g number
---@field b number
---@field a number


---@class buffclient.data.Effect
---@field EffectPath string @EffectPath
---@field Attach number @Attach
---@field AttachNodeName string @AttachNodeName
---@field Scale SkillEditor.EditorVector3 @Scale
---@field Offset SkillEditor.EditorVector3 @Offset
---@field Rotation SkillEditor.EditorVector3 @Rotation
---@field IsFollow boolean @IsFollow
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class buffclient.data.ScreenEffect
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class buffclient.data.BuffUI
---@field BuffUIType number @BuffUIType
---@field IconPath string @IconPath
---@field BuffText string @BuffText
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class buffclient.data.ModelModify
---@field ReplaceModel boolean @ReplaceModel
---@field NewModelPath string @NewModelPath
---@field Scale SkillEditor.EditorVector3 @Scale
---@field Tweening boolean @Tweening
---@field CurveX UnityEngine.AnimationCurve @CurveX
---@field CurveY UnityEngine.AnimationCurve @CurveY
---@field CurveZ UnityEngine.AnimationCurve @CurveZ
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class buffclient.data.AnimatorParameters
---@field ParamKey string @ParamKey
---@field ParamType number @ParamType
---@field ParamValue number @ParamValue
---@field Tweening boolean @Tweening
---@field AutoAimTarget boolean @AutoAimTarget
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class buffclient.data.NodeVisible
---@field NodeName string @NodeName
---@field Visible boolean @Visible
---@field RestoreOnEnd boolean @RestoreOnEnd
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class buffclient.data.MaterialAppend
---@field MaterialName string @MaterialName
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName


return gen
