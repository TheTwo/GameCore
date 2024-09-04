-- auto gen. do not modify

---@class skillclient.gen
local gen = {
  
    Type = {
      Animation = 0,
      Effect = 1,
      Move = 2,
      CameraShake = 3,
      GlowEffect = 4,
      AdjustDirection = 5,
      ModelShake = 6,
      Alert = 7,
      DamageText = 8,
      SkillAudio = 9,
      ProjectileEffect = 10,
      SkillEvent = 11,
      TimeProgressTip = 12,
      KeyEvent = 13,
      AdjustPos = 14,
      AddBuff = 15,
      AnimState = 16,
      Empty = 17,
      AnimatorParameters = 18,
      ModelHide = 19,
      MoveY = 20,
      EnergyRestoreEffect = 21,
      SlgCameraShake = 22,
      MaterialAppend = 23,
    },
  
    Type2name = {
      [0] = "skillclient.behavior.Animation",
      [1] = "skillclient.behavior.Effect",
      [2] = "skillclient.behavior.Move",
      [3] = "skillclient.behavior.CameraShake",
      [4] = "skillclient.behavior.GlowEffect",
      [5] = "skillclient.behavior.AdjustDirection",
      [6] = "skillclient.behavior.ModelShake",
      [7] = "skillclient.behavior.Alert",
      [8] = "skillclient.behavior.DamageText",
      [9] = "skillclient.behavior.SkillAudio",
      [10] = "skillclient.behavior.ProjectileEffect",
      [11] = "skillclient.behavior.SkillEvent",
      [12] = "skillclient.behavior.TimeProgressTip",
      [13] = "skillclient.behavior.KeyEvent",
      [14] = "skillclient.behavior.AdjustPos",
      [15] = "skillclient.behavior.AddBuff",
      [16] = "skillclient.behavior.AnimState",
      [17] = "skillclient.behavior.Empty",
      [18] = "skillclient.behavior.AnimatorParameters",
      [19] = "skillclient.behavior.ModelHide",
      [20] = "skillclient.behavior.MoveY",
      [21] = "skillclient.behavior.EnergyRestoreEffect",
      [22] = "skillclient.behavior.SlgCameraShake",
      [23] = "skillclient.behavior.MaterialAppend",
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


---@class skillclient.data.Animation
---@field AnimName string @AnimName
---@field SpeedScale System.Collections.Generic.List @SpeedScale
---@field OtherElementScale boolean @OtherElementScale
---@field Priority number @Priority
---@field FadeTime number @FadeTime
---@field Layer number @Layer
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.Effect
---@field EffectPath string @EffectPath
---@field Attach number @Attach
---@field AttachNodeName string @AttachNodeName
---@field AttachTarget number @AttachTarget
---@field AttachTargetNodeName string @AttachTargetNodeName
---@field Scale SkillEditor.EditorVector3 @Scale
---@field Offset SkillEditor.EditorVector3 @Offset
---@field Rotation SkillEditor.EditorVector3 @Rotation
---@field IsFollow boolean @IsFollow
---@field KeepWorldRotation boolean @KeepWorldRotation
---@field WorldRotation SkillEditor.EditorVector3 @WorldRotation
---@field IsBallistic boolean @IsBallistic
---@field DestroyWhenOwnerDie boolean @DestroyWhenOwnerDie
---@field DestroyWhenSkillCancel boolean @DestroyWhenSkillCancel
---@field IsHitEffect boolean @IsHitEffect
---@field BeHitTag number @BeHitTag
---@field HitEffectScaleWithModel boolean @HitEffectScaleWithModel
---@field ProjectileType number @ProjectileType
---@field CancelLoopingOnHit boolean @CancelLoopingOnHit
---@field DelayDestruct number @DelayDestruct
---@field TraceTarget boolean @TraceTarget
---@field Speed number @Speed
---@field FixedTime number @FixedTime
---@field Acceleration number @Acceleration
---@field Height number @Height
---@field Gravity number @Gravity
---@field IsAlertRange boolean @IsAlertRange
---@field AlertRangeShape number @AlertRangeShape
---@field AlertRangeFanAngle number @AlertRangeFanAngle
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.Move
---@field UseNotDistance boolean @UseNotDistance
---@field DirectionType number @DirectionType
---@field Distance number @Distance
---@field StartPosType number @StartPosType
---@field EndPosType number @EndPosType
---@field Offset number @Offset
---@field AnimClipPath string @AnimClipPath
---@field Curve UnityEngine.AnimationCurve @Curve
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.CameraShake
---@field Params System.Collections.Generic.List @Params
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.GlowEffect
---@field Color SkillEditor.EditorColor @Color
---@field EndColor SkillEditor.EditorColor @EndColor
---@field EaseTime number @EaseTime
---@field Priority number @Priority
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.AdjustDirection
---@field DirTarget number @DirTarget
---@field Angle number @Angle
---@field Tweening boolean @Tweening
---@field PlayRotAnim boolean @PlayRotAnim
---@field AutoAimTarget boolean @AutoAimTarget
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.ModelShake
---@field Range SkillEditor.EditorVector3 @Range
---@field AngularFrequency number @AngularFrequency
---@field Damping number @Damping
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.Alert
---@field Shape number @Shape
---@field Length number @Length
---@field Width number @Width
---@field Angle number @Angle
---@field ShiftDistance number @ShiftDistance
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.DamageText
---@field DamageTextType number @DamageTextType
---@field Rate number @Rate
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.SkillAudio
---@field EventName string @EventName
---@field DestroyWhenOwnerDie boolean @DestroyWhenOwnerDie
---@field DestroyWhenSkillCancel boolean @DestroyWhenSkillCancel
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.ProjectileEffect
---@field ProjectileType number @ProjectileType
---@field EffectPath string @EffectPath
---@field AttachNodeName string @AttachNodeName
---@field Scale SkillEditor.EditorVector3 @Scale
---@field Offset SkillEditor.EditorVector3 @Offset
---@field CancelLoopingOnHit boolean @CancelLoopingOnHit
---@field DelayDestruct number @DelayDestruct
---@field TraceTarget boolean @TraceTarget
---@field Speed number @Speed
---@field Acceleration number @Acceleration
---@field Height number @Height
---@field Gravity number @Gravity
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.SkillEvent
---@field SkillEventType number @SkillEventType
---@field Param string @Param
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.TimeProgressTip
---@field Direction number @Direction
---@field Text string @Text
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.KeyEvent
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.AdjustPos
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.AddBuff
---@field BuffId number @BuffId
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.AnimState
---@field IgnoreRunRotation boolean @IgnoreRunRotation
---@field PlayAttackMove boolean @PlayAttackMove
---@field KeepDirection boolean @KeepDirection
---@field IgnoreKeepDirection boolean @IgnoreKeepDirection
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.Empty
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.AnimatorParameters
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

---@class skillclient.data.ModelHide
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.MoveY
---@field MaxDistance number @MaxDistance
---@field AnimClipPath string @AnimClipPath
---@field Curve UnityEngine.AnimationCurve @Curve
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.EnergyRestoreEffect
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.SlgCameraShake
---@field Shake number @Shake
---@field Noise number @Noise
---@field MoveExtents SkillEditor.EditorVector3 @MoveExtents
---@field RotateExtents SkillEditor.EditorVector3 @RotateExtents
---@field Speed number @Speed
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName

---@class skillclient.data.MaterialAppend
---@field MaterialName string @MaterialName
---@field Type number @Type
---@field Des string @Des
---@field TimeBegin number @TimeBegin
---@field Time number @Time
---@field TrackName string @TrackName


return gen
