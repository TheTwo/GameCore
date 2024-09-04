#if USE_XLUA

using System.Collections.Generic;
using UnityEngine;
using System;
using System.Reflection;
using System.Threading.Tasks;
using System.Linq;
using System.Collections.Concurrent;
using System.Globalization;
using CG.CustomPlayables.GameEventTrack;
using CG.Plot;
using DG.Tweening;
using DG.Tweening.Core;
using DG.Tweening.Plugins.Options;
using DragonReborn;
using DragonReborn.AssetTool;
using DragonReborn.Performance;
using DragonReborn.UI;
using Kingdom;
using SdkAdapter;
using SdkAdapter.SdkModels;
using UnityEngine.Events;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using XLua;
using DragonReborn.AssetTool.ECS;
using DragonReborn.VisualEffect;
using DragonReborn.Projectile;
using Territory;
using Unity.Jobs.LowLevel.Unsafe;
using RenderExtension;
using UnityEngine.UI;
using UnityEngine.Video;
using UnityEngine.Playables;
using UnityEngine.Animations;
using UnityEngine.UI.Extensions;
using FunPlusChat;
using FunPlusChat.Interfaces;
using FunPlusChat.Models;
using FunPlusChat.Common.Interfaces;
using Lod;
using UnityEngine.Experimental.Rendering.Universal;
using Utilities;
using static DragonReborn.SLG.Troop.TroopViewManager;
using BrainFailProductions.PolyFew;
using DragonReborn.City.Creep;
using FunPlusChat.Common.Models;
using Grid;
//using UnityEngine.Animations.Rigging;
using Voronoi;

public static class XLuaConfig
{
	[CSObjectWrapEditor.GenPath]
	public static string GeneratePath = Application.dataPath + "/XLua/XLuaGen/";

	[GenerateLuaHintOutputPath("Generated{0}LuaHint.lua")] 
	public static string GenerateLuaHintOutputPath =
		Application.dataPath + "/../../../../ssr-logic/Lua";

	//lua中要使用到C#库的配置，比如C#标准库，或者Unity API，第三方库等。
	[GenerateLuaHint]
	[LuaCallCSharp]
	public static List<Type> LuaCallCSharp = new List<Type>() {
		//瞬时电流
		typeof(Battery.BatteryManager),
		typeof(DragonReborn.SLG.Troop.TroopOptUtils),
		
		//Lua Memory Profiler
		typeof(LuaMemoryProfiler.Utility),
			
		//LuaBehaviour
		typeof(LuaSchemaSlot),
		typeof(LuaBehaviour),
		typeof(RenderParallelTasks),
		
		// UnityEngine
		typeof(Application),
		typeof(ThreadPriority),
		typeof(RuntimePlatform),
		typeof(Debug),
		typeof(PlayerPrefs),
		typeof(UnityEngine.Device.Screen),
		typeof(UnityEngine.Device.Application),
		typeof(UnityEngine.Device.SystemInfo),
		typeof(SystemInfo),
		typeof(Screen),
		typeof(KeyCode),
		typeof(Rect),
		typeof(Mathf),
		typeof(QualitySettings),
		typeof(DeviceType),
		typeof(BatteryStatus),
		typeof(SystemLanguage),
		typeof(CultureInfo),
		typeof(ApplicationInstallMode),
		typeof(ApplicationSandboxType),
		typeof(ScreenOrientation),
		typeof(TextureFormat),
		typeof(RenderTextureFormat),
		typeof(UnityEngine.Experimental.Rendering.GraphicsFormat),
		typeof(UnityEngine.Experimental.Rendering.FormatUsage),
		typeof(UnityEngine.Experimental.Rendering.DefaultFormat),
		typeof(RaycastHit),
		typeof(RaycastHit2D),
		typeof(Plane),
		typeof(Camera),
		typeof(Material),
		typeof(GraphicsSettings),
		typeof(UniversalRenderPipeline),
		typeof(UniversalRenderPipelineAsset),
		typeof(UniversalAdditionalCameraData),
		typeof(UnityEngine.Rendering.Universal.CameraExtensions),
		typeof(SystemInfo),
		typeof(RenderPiplineUtil),
		typeof(Motion),
		typeof(RenderTexture),
		typeof(RenderTextureDescriptor),
		typeof(GL),
		
		// 框架
		typeof(EnvironmentVariable),
		typeof(AssetManager),
		typeof(ObjectInstantiateManager),
		typeof(AssetHandle),
		typeof(GameObjectCreateHelper),
		typeof(PooledGameObjectHandle),
		typeof(PooledGameObjectCreateHelper),
		typeof(UnityObjectExtension),
		typeof(CinemachineEx),
		typeof(UnityExtensions),
		typeof(Notification.NotificationManager),
		typeof(Notification.NotificationUINode),
		typeof(Notification.NotificationDynamicNode),
		typeof(Dictionary<string, VersionDefine.VersionCell>),
		typeof(Dictionary<ushort, ushort>),
		typeof(Dictionary<ushort, ushort>.Enumerator),
		typeof(Dictionary<ushort, ValueTuple<ushort, ushort, ushort>>),
		typeof(Dictionary<ushort, ValueTuple<ushort, ushort, ushort>>.Enumerator),
		typeof(Dictionary<long, string>),
		typeof(KeyValuePair<ushort, ushort>),
		typeof(KeyValuePair<ushort, ValueTuple<ushort, ushort, ushort>>),
		typeof(PerformanceLevelManager),
		typeof(PerformanceLevelData),
		typeof(PerformanceHelper),
		typeof(DeviceLevel),
		typeof(AABB),
		typeof(VisualEffectHandle),
		typeof(ParticleVisualEffect),
		typeof(PathHelper),
		typeof(LuaSpriteSetNotify),
		typeof(SafetyUtils),
		typeof(NetLockDelayActive),
		typeof(LoadingFlag),
		typeof(SerializableDictionary<string, Renderer>),
		typeof(SerializableDictionary<string, Renderer>.Enumerator),
		typeof(DragonReborn.AssetTool.AssetBundleAsyncLoadTracker),

		// Utility Core
		typeof(Util.GeneralUtil),
		typeof(Util.MathUtil),
		typeof(Util.ReflectionUtil),
		typeof(Util.FsUtil),
		typeof(Util.NetUtil),
		typeof(Util.TimeUtil),
		typeof(Util.RtUtil),
		typeof(Util.GraphicsUtil),
		typeof(Util.PhysicsUtil),
		typeof(Util.AnimUtil),
		typeof(Util.VfxUtil),
		typeof(Util.AudioUtil),
		typeof(Util.VideoUtil),
		typeof(Util.UIUtil),
		typeof(Util.PoolUtil),
		typeof(Util.CtrlUtil),
		typeof(Util.StatisticsUtil),
		typeof(Util.AssetUtil),

		// ChatSDK
		typeof(FPChatSdk),
		typeof(ChatSdkWrapper),
		typeof(IMessageReceiver),
		typeof(SdkConfig),
		typeof(FPMessage),
		typeof(FPSession),
		typeof(MessageType),
		typeof(UserInfo),
		typeof(GameUser),
		typeof(ChatFile),
		typeof(PushInfo),
		typeof(List<FPMessage>),
		typeof(ChatMessageReceiver),
		typeof(FunLang),
		typeof(ChatErrorCode),
		typeof(SessionType),
		typeof(GroupType),
		typeof(MessageStatus),
		typeof(TranslateConfig),
		typeof(FPTranslatedInfo),
		typeof(FunResult<FPTranslatedInfo>),
		typeof(SdkAttrs),

		// Map
		typeof(Grid.LuaTileView),
		typeof(Grid.LuaKingdomView),
		typeof(Grid.LuaTileViewFactory),
		typeof(Grid.LuaKingdomViewFactory),
		typeof(Grid.LuaRequestService),
		typeof(Grid.MapSystem),
		typeof(Grid.StaticMapData),
		typeof(Grid.DecorationInstance),
		typeof(Grid.Decoration),
		typeof(Grid.MapUtils),
		typeof(Grid.DecorationTileView),
		typeof(Lod.SceneCameraUtils),
		typeof(KingdomGridMeshManager),
		typeof(MapBuildingHighlight),
		typeof(MapBuildingColor),
		typeof(TileHighlightColor),
		typeof(TerritorySystem),
		typeof(MapTerritorySettings),
		typeof(TroopLineManager),
		typeof(TroopLine),
		typeof(KingdomUnitMaterialPool),
		typeof(TransformNoGC),
		typeof(MapCreepMask),
		typeof(MapCameraSettings),
		typeof(MapCreepSettings),
		typeof(MapFogSettings),
		typeof(MapFogSystem),
		typeof(MapSettings),
		typeof(KingdomGridMeshSettings),
		typeof(MapHUDSettings),
		typeof(MapRoadSettings),
		typeof(MapHUDManager),
		typeof(MapHUDCreate),
		typeof(MapHUDRefresh),
		typeof(VoronoiMeshRequest),
		typeof(List<MapHUDCreate>),
		typeof(List<Material>),
		typeof(U2DWidgetMaterialSetter),
		typeof(DragonReborn.SLG.Troop.TroopViewManager),
		typeof(DragonReborn.SLG.Troop.TroopData),
		typeof(DragonReborn.SLG.Troop.TroopViewManager.TroopSkillFloatingTextParam),
		typeof(DragonReborn.SLG.Troop.TroopViewManager.TroopSkillBuffInfo),
		typeof(DragonReborn.SLG.Troop.TroopViewManager.TroopSkillTargetInfo),
		typeof(DragonReborn.SLG.Troop.TroopViewManager.TroopSkillMovementInfo),
		typeof(DragonReborn.SLG.Troop.TroopViewManager.TroopSkillData),
		typeof(DragonReborn.SLG.Troop.TroopViewManager.TroopRoundData),
		typeof(DragonReborn.SLG.Troop.TroopViewVfxUtilities),
		typeof(TerritoryCacheExt),
		typeof(NewMapSystem.MapGrid<NewMapSystem.HexMapSystem.HexCellId, NewMapSystem.HexMapSystem.HexUnitId>),
		typeof(NewMapSystem.HexMapSystem.HexMapGrid<NewMapSystem.HexMapSystem.HexUnitId, NewMapSystem.HexMapSystem.HexChunkId>),
		typeof(NewMapSystem.HexMapSystem.HexMapGridDerived),
		typeof(NewMapSystem.HexMapSystem.HexMapUtil),

		typeof(DragonReborn.SLG.Troop.LuaTroopViewHelper),
		typeof(DragonReborn.SLG.FloatingText.FloatingTextUtility),
		typeof(Troop.TroopSkillManager),
		typeof(BasicCameraSettings),
		typeof(FullScreenUIFeature),
		typeof(FullScreenFeature),

        // others
		typeof(System.Object),
		typeof(System.IO.Path),
		typeof(NLogger),
		typeof(LogSeverity),
		typeof(UnityEngine.LogType),
		typeof(DragonReborn.Utilities.EnumHelper),
		typeof(GridMapView),
		typeof(DragonReborn.City.CityMapGridNavMesh),
		typeof(DragonReborn.City.CityMapGridNavMesh.BlockType),
		typeof(DragonReborn.City.CityMapGridNavMesh.ZoneDefine),
		typeof(DragonReborn.City.CityZoneSliceDataProvider),
		typeof(DragonReborn.City.ICityZoneSliceDataProviderUsage),
		typeof(DragonReborn.City.ISafeAreaEdgeDataUsage),
		typeof(CityGroundNavMarker),
		typeof(CityGroundMeshNavMarker),
		typeof(CityGroundVolumeNavMarker),
		typeof(Unity.Collections.NativeArray<Vector3>),
		typeof(Unity.Collections.Allocator),
		typeof(UnityEngine.Gradient),
		typeof(AnimationCurve),
		typeof(DragonReborn.City.CityLightGradientConfig),
		typeof(DragonReborn.City.CityLightGradientConfig.LightConfigData),
		typeof(SendMessageOptions),
		typeof(CityFogController),
		typeof(ZoneConfigPair),
		typeof(DragonReborn.City.CitySafeAreaWallController),
		typeof(System.DateTime),
		typeof(System.DateTimeKind),
		typeof(System.DateTimeOffset),
		typeof(System.DayOfWeek),
		typeof(System.TimeSpan),
		typeof(System.Array),
		typeof(ColorUtility),
		typeof(DragonReborn.Projectile.ProjectileManager),
		typeof(System.Action<UnityEngine.AsyncOperation>),
		typeof(System.Action<UnityEngine.Networking.UnityWebRequestAsyncOperation>),
		typeof(U2DFontUpdateTracker),
		typeof(zFrame.UI.Joystick),

		typeof(VideoPlayer),
		typeof(VideoClip),
		typeof(RawImage),
		typeof(Texture),
		typeof(RenderTexture),
		typeof(RTHandle),
		typeof(RTHandles),
		typeof(Texture2D),
		typeof(FilterMode),
		typeof(VideoPlayerMediator),
		typeof(UnityEngine.Video.VideoAspectRatio),
		typeof(ShaderVariantCollection),
		typeof(DragonReborn.Utilities.UnityWebRequestExt),
		typeof(DragonReborn.Utilities.ExternalImageCache),
		typeof(DragonReborn.Utilities.RuntimeSpriteCache),
		typeof(DragonReborn.RangeEventMgr),

		typeof(System.Guid),
		typeof(UnityEngine.Object),
		typeof(Vector2),
		typeof(Vector2?),
		typeof(Vector3),
		typeof(Vector3?),
		typeof(Vector4),
		typeof(Vector4?),
		typeof(Vector2Short),
		typeof(Vector3Short),
		typeof(Vector2Long),
		typeof(Vector2Int),
		typeof(Vector2Int?),
		typeof(Matrix4x4),
		typeof(Quaternion),
		typeof(Color),
		typeof(Ray),
		typeof(Bounds),
		typeof(Ray2D),
		typeof(Time),
		typeof(Input),
		typeof(GameObject),
		typeof(Component),
		typeof(Behaviour),
		typeof(Transform),
		typeof(Resources),
		typeof(TextAsset),
		typeof(Keyframe),
		typeof(AnimationCurve),
		typeof(AnimationClip),
		typeof(AnimationState),
		typeof(MonoBehaviour),
		typeof(SkinnedMeshRenderer),
		typeof(Renderer),
		typeof(LineRenderer),
		typeof(LineAlignment),
		typeof(VerticalLayoutGroup),
		typeof(HorizontalLayoutGroup),
		typeof(HorizontalOrVerticalLayoutGroup),
		typeof(GridLayoutGroup),
		typeof(LayoutElement),
		typeof(ContentSizeFitterEx),
		typeof(List<short>),
		typeof(List<int>),
		typeof(List<long>),
		typeof(List<float>),
		typeof(List<double>),
		typeof(List<bool>),
		typeof(List<byte>),
		typeof(List<string>),
		typeof(List<object>),
		typeof(List<LuaBehaviour>),
		typeof(List<LuaBehaviour>.Enumerator),
		typeof(List<Grid.TileView>),
		typeof(List<Component>),
		typeof(Dictionary<string, string>),
		typeof(Dictionary<string, float>),
		typeof(System.ValueTuple<ushort, ushort, ushort>),
		typeof(System.Collections.Generic.IReadOnlyDictionary<byte, System.ValueTuple<ushort, ushort, ushort>[]>),
		typeof(System.Collections.Generic.Dictionary<ushort,System.ValueTuple<ushort,ushort,ushort>[]>),
		typeof(System.Collections.Generic.Dictionary<ushort,System.ValueTuple<ushort,ushort,ushort>[]>.Enumerator),
		typeof(System.Collections.Generic.KeyValuePair<ushort, System.ValueTuple<ushort, ushort, ushort>[]>),
		typeof(System.Collections.Generic.IReadOnlyDictionary<ushort, System.ValueTuple<ushort, ushort, ushort>[]>),
		typeof(System.Collections.Generic.IEnumerable<string>),
		typeof(System.Collections.Generic.IReadOnlyCollection<string>),
		typeof(System.Collections.Generic.IReadOnlyList<string>),

		//UI
		typeof(UnityEngine.UI.Image),
		typeof(UnityEngine.UI.Button),
		typeof(UnityEngine.UI.InputField),
		typeof(UnityEngine.UI.Toggle),
		typeof(UnityEngine.UI.Slider),
		typeof(UnityEngine.UI.MaskableGraphic),
		typeof(UnityEngine.UI.Text),
		typeof(UnityEngine.TextGenerator),
		typeof(UnityEngine.UI.RawImage),
		typeof(UnityEngine.UI.ScrollRect),
		typeof(RectTransform),
		typeof(TableViewPro),
		typeof(TableViewProCell),
		typeof(TableViewProState),
		typeof(TableViewProLayout),
		typeof(IScrollRect),
		typeof(IScrollRectContent),
		typeof(UGUIScrollRect),
		typeof(UGUILayoutRect),
		typeof(List<TableViewProCell>),
		typeof(List<LuaTableViewProCell>),
		typeof(List<LuaTableViewProExpandCell>),
		typeof(DragonReborn.UI.LuaBaseComponent),
		typeof(StatusRecordParent),
		typeof(StatusRecordChild),
		typeof(UIStatusRecord),
		typeof(Empty4Raycast),
		typeof(RectTransformUtility),
		typeof(UIMediatorType),
		typeof(FpAnimation.CommonTriggerType),
		typeof(FpAnimation.FpAnimationCommonTrigger),
		typeof(FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger_FpAnim),
		typeof(FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger_UnityAnim),
		typeof(FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger_FxObject),
		typeof(FpAnimation.FpAnimationCommonTrigger.FxUIDepthType),
		typeof(FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger),
		typeof(FpAnimation.FpAnimatorTotalCommander),
		typeof(TouchPan),
		typeof(PageViewController),
		typeof(ItemRewardCurve),
		typeof(DragonReborn.UI.TextStyleConfig),
		typeof(DragonReborn.UI.TextFontConfig),
		typeof(ICanvasRaycastFilter),
		typeof(LuaCanvasRaycastFilter),
		typeof(TextPic),
		typeof(Coffee.UIExtensions.UIParticle),
		typeof(Physics2D),
		typeof(BoxCollider2D),
		typeof(PolygonCollider2D),
		typeof(CircleCollider2D),
		typeof(ColorBlock),
		typeof(Spine.Unity.SkeletonGraphic),
		typeof(TurntableAnimCurve),
		typeof(U2DComponent),
		typeof(CanvasScaler),
		typeof(AutoLoader),
		typeof(UIImageAutoGenerator),
		typeof(UIImageMaterialVfxAutoGenerator),
		typeof(UIVfxAutoGenerator),
		// typeof(DragonReborn.ToggleButtonList),

		typeof(FrameworkInterfaceManager),
		typeof(IFrameworkInterface),
		typeof(IFrameworkLogger),
		typeof(IFrameworkSoundManager),
		typeof(DragonReborn.Sound.SimulateSoundDistanceAttenuation),

		typeof(SoundPlayingHandle),
		typeof(SpriteManager),
		typeof(MaterialManager),
		typeof(VideoClipManager),
		typeof(DragonReborn.Singleton<DragonReborn.AssetTool.VideoClipManager>),
		typeof(TaskManager),
		
		//Gesture
		typeof(GestureManager),
		typeof(GesturePhase),
		typeof(TapGesture),
		typeof(DragGesture),
		typeof(PinchGesture),
		typeof(UITapGesture),
		typeof(LuaGestureListener),
		typeof(UIEvent.PreEventSystemUpdate),

		typeof(UnityEngine.EventSystems.PointerEventData),
		typeof(Action<GameObject, UnityEngine.EventSystems.PointerEventData>),
		
		//DOTween
		typeof(AutoPlay),
		typeof(AxisConstraint),
		typeof(Ease),
		typeof(LogBehaviour),
		typeof(LoopType),
		typeof(PathMode),
		typeof(PathType),
		typeof(RotateMode),
		typeof(ScrambleMode),
		typeof(TweenType),
		typeof(UpdateType),

		typeof(DOTween),
		typeof(DOVirtual),
		typeof(EaseFactory),
		typeof(Tweener),
		typeof(Tween),
		typeof(Sequence),
		typeof(TweenParams),
		typeof(ABSSequentiable),

		typeof(TweenerCore<Vector3, Vector3, VectorOptions>),
		typeof(TweenerCore<float, float, FloatOptions>),
		typeof(TweenerCore<Quaternion, Vector3, QuaternionOptions>),

		typeof(TweenExtensions),
		typeof(TweenSettingsExtensions),
		typeof(ShortcutExtensions),
		typeof(DOTweenModuleUI),
       
		//DoTween pro
		typeof(DOTweenPath),
		typeof(DOTweenVisualManager),
		
		//Custom DOTween
		typeof(DOTweenExt),
		typeof(U2DDOTweenExt),
		typeof(DG.Tweening.Core.TweenerCore<UnityEngine.Vector2, UnityEngine.Vector2, DG.Tweening.Plugins.Options.VectorOptions>),
		typeof(DG.Tweening.Core.TweenerCore<UnityEngine.Vector3, UnityEngine.Vector3, DG.Tweening.Plugins.Options.VectorOptions>),
		
		//sdk
		typeof(SdkWrapper),
		typeof(SdkModel),
		typeof(SdkModelWrapper),
		typeof(SdkFirebase),
		typeof(SdkCrashlytics),
		typeof(SdkProblemDingTalkReport),
		typeof(SdkStreamMedia),
		typeof(SdkStreamMedia.PlayResult),

		//timeline
		typeof(UnityEngine.Playables.PlayableDirector),
		typeof(CG.Plot.PlotReference),
		typeof(GameEventTrack),
		typeof(GameEventClip),
		typeof(GameEventBehaviour),

		// Playable
		typeof(PlayableGraph),
		typeof(AnimationPlayableOutput),
		typeof(AnimationLayerMixerPlayable),
		typeof(AnimatorControllerPlayable),
		typeof(PlayableOutputExtensions),
		
		//JOB ECS
		typeof(Unity.Jobs.LowLevel.Unsafe.JobsUtility),
		typeof(ECSHelper),
		
#if UNITY_DEBUG
		typeof(IFrameworkInGameConsole),
#endif
		typeof(Cinemachine.CinemachineBlendDefinition),
		typeof(Cinemachine.CinemachineBlendDefinition.Style),
		typeof(Cinemachine.CinemachineBrain),
		typeof(Cinemachine.CinemachineBasicMultiChannelPerlin),
		typeof(Cinemachine.CinemachineTransposer),
		typeof(Cinemachine.CinemachineVirtualCameraBase),
		typeof(Cinemachine.CinemachineVirtualCameraBase.StandbyUpdateMode),
		typeof(Cinemachine.CinemachineVirtualCameraBase.BlendHint),
		typeof(Cinemachine.CinemachineVirtualCameraBase.TransitionParams),
		typeof(Cinemachine.CinemachineVirtualCamera),
		typeof(Cinemachine.LensSettings),
		typeof(Cinemachine.LensSettings.OverrideModes),
		typeof(Cinemachine.CinemachineFramingTransposer),
		typeof(Cinemachine.CameraState),
		typeof(Cinemachine.LensSettings),
		typeof(DragonReborn.SLG.Troop.TroopViewProxy),
		typeof(DG.Tweening.DOTweenAnimation),
		typeof(DG.Tweening.Ease),
		typeof(DOTweenExt),
		typeof(DragonReborn.Alert),
		typeof(DragonReborn.Alert.Shape),
		typeof(DragonReborn.AssetTool.AssetManager),
		typeof(DragonReborn.AssetTool.GameObjectCreateHelper),
		typeof(DragonReborn.AssetTool.PooledGameObjectCreateHelper),
		typeof(DragonReborn.AssetTool.PooledGameObjectHandle),
		typeof(DragonReborn.AssetTool.SpriteManager),
		typeof(DragonReborn.AssetTool.ShaderWarmupUtils),
		typeof(DragonReborn.DragGesture),
		typeof(DragonReborn.FrameworkInterfaceManager),
		
		typeof(DragonReborn.GestureManager),
		typeof(DragonReborn.GesturePhase),
		typeof(DragonReborn.IFrameworkInGameConsole),
		typeof(DragonReborn.IOUtils),
		typeof(DragonReborn.LogSeverity),
		typeof(DragonReborn.LuaBehaviour),
		typeof(DragonReborn.UI.LuaUIMediator),
		typeof(DragonReborn.NLogger),
		typeof(DragonReborn.PinchGesture),
		typeof(DragonReborn.Sound.SoundManager),
		typeof(DragonReborn.Utilities.PowerManager),
		typeof(DragonReborn.NativePowerThermalStatus),
		typeof(DragonReborn.TapGesture),
		typeof(DragonReborn.UI.BaseComponent),
		typeof(DragonReborn.UI.BaseComponentEx),
		typeof(DragonReborn.UI.LuaBaseComponent),
		typeof(DragonReborn.UI.LuaUIUtility),
		typeof(DragonReborn.UI.UIHelper),
		typeof(DragonReborn.UI.UIHelper.CallbackHolder),
		typeof(DragonReborn.UI.UIManager),
		typeof(DragonReborn.Utils),
		typeof(DragonReborn.Utilities.FindSmoothAStarPathHelper),
		typeof(DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle),
		typeof(Grid.LuaKingdomViewFactory),
		typeof(Grid.LuaRequestService),
		typeof(Grid.LuaTileView),
		typeof(Grid.LuaTileViewFactory),
		typeof(Grid.MapSystem),
		typeof(Grid.StaticMapData),
		typeof(LangValidation.LangValidationHelper),
		typeof(LangValidation.LangValidationManager),
		typeof(LogicRepoUtils),
		typeof(LuaGestureListener),
		typeof(LuaScriptLoader),
		typeof(RaycastHelper),
		typeof(SEAlertRange),
		typeof(SECircleAreaSelector),
		typeof(SECircleSelect),
		typeof(SEComponents),
		typeof(SEComponents.SEMineActionComponentBase),
		typeof(SEComponents.SENavMeshObstacleControlBase),
		typeof(SEFloatingTextManager),
		typeof(SEFloatingText),
		typeof(SEHpBar),
		typeof(SEMapInfo),
		typeof(SEForCityMapInfo),
		typeof(LockWorldRotation),
		typeof(SEMineInteractiveControl),
		typeof(SEPlayerOpenLightTrigger),
		typeof(SESearchWaveMap),
		typeof(SESkillRangeCircle),
		typeof(SESkillRangeFan),
		typeof(SESkillRangeRect),
		typeof(SESplashTrigger),
		typeof(SEUnitDataComp),
		typeof(SEUnitDialog),
		typeof(SEUnitHud),
		typeof(SEUnitReceiver),
		typeof(SEWeatherSystem),
		typeof(SEEffectManager),
		typeof(SEAdditionalMaterial),
		typeof(SEUnitCorpseDisslove),
		// typeof(CharacterSEPropAdjuster),
		typeof(UI3DBubbleWorld),
		typeof(UI3DBubbleWorldECS),
		typeof(U2DFacingCameraECS),
		typeof(CustomMouseListener),
		typeof(CustomData),
		typeof(UIHorizentalSwingComponent),
		typeof(MaterialBank),
		typeof(MaterialAppender),
		typeof(RendererRefer),
		typeof(ScriptEngine),
		typeof(StatusRecordParent),
		typeof(System.Array),
		typeof(System.Collections.Generic.Dictionary<,>),
		typeof(System.Collections.Generic.List<>),
		typeof(TimeSpanConverter),
		typeof(TroopLineManager),
		typeof(U2DFacingCamera),
		typeof(U2DFacingCameraECS),
		typeof(U2DTextMesh),
		typeof(U2DWidgetMesh),
		typeof(U2DSlider),
		typeof(U2DSpriteMesh),
		typeof(U2DStretch),
		typeof(U2DAnchor),
		typeof(U2D.U2DGrid),
		typeof(U2DHorizontalLayoutGroup),
		typeof(U2DLayoutElement),
		typeof(UIPointerClickListener),
		typeof(UIPointerDownListener),
		typeof(UIPointerUpListener),
		typeof(UIDropListener),
		typeof(UnityEngine.AI.NavMesh),
		typeof(UnityEngine.AI.NavMeshAgent),
		typeof(UnityEngine.AI.NavMeshHit),
		typeof(UnityEngine.AI.NavMeshPath),
		typeof(UnityEngine.AI.NavMeshPathStatus),
		typeof(UnityEngine.AI.NavMeshBuildSettings),
		typeof(UnityEngine.AI.ObstacleAvoidanceType),
		typeof(UnityEngine.AnimationCurve),
		typeof(UnityEngine.Animator),
		typeof(UnityEngine.AnimatorStateInfo),
		typeof(UnityEngine.Application),
		typeof(UnityEngine.Application),
		typeof(UnityEngine.BoxCollider),
		typeof(UnityEngine.Camera),
		typeof(UnityEngine.CanvasGroup),
		typeof(UnityEngine.CapsuleCollider),
		typeof(UnityEngine.Collider),
		typeof(SphereCollider),
		typeof(UnityEngine.Color32),
		typeof(UnityEngine.Debug),
		typeof(UnityEngine.DynamicGI),
		typeof(UnityEngine.GameObject),
		typeof(UnityEngine.Input),
		typeof(UnityEngine.KeyCode),
		typeof(UnityEngine.Keyframe),
		typeof(UnityEngine.LayerMask),
		typeof(UnityEngine.Light),
		typeof(UnityEngine.LightShadows),
		typeof(UnityEngine.LightType),
		typeof(UnityEngine.MaterialPropertyBlock),
		typeof(UnityEngine.Mathf),
		typeof(UnityEngine.Networking.DownloadHandler),
		typeof(UnityEngine.Object),
		typeof(UnityEngine.Plane),
		typeof(UnityEngine.PlayerPrefs),
		typeof(UnityEngine.QualitySettings),
		typeof(UnityEngine.Quaternion),
		typeof(UnityEngine.Random),
		typeof(UnityEngine.Ray),
		typeof(UnityEngine.Renderer),
		typeof(UnityEngine.Rendering.Volume),
		typeof(UnityEngine.Rigidbody),
		typeof(UnityEngine.RuntimePlatform),
		typeof(UnityEngine.SceneManagement.LoadSceneMode),
		typeof(UnityEngine.SceneManagement.SceneManager),
		typeof(UnityEngine.SceneManagement.Scene),
		typeof(UnityEngine.Screen),
		typeof(UnityEngine.Shader),
		typeof(UnityEngine.TextAnchor),
		typeof(UnityEngine.Time),
		typeof(UnityEngine.TrailRenderer),
		typeof(UnityEngine.Transform),
		typeof(UnityEngine.UI.Button),
		typeof(UnityEngine.UI.Image),
		typeof(UnityEngine.UI.InputField),
		typeof(UnityEngine.UI.MaskableGraphic),
		typeof(UnityEngine.UI.Slider),
		typeof(UnityEngine.UI.Text),
		typeof(UnityEngine.UI.Toggle),
		typeof(UnityEngine.UI.ToggleGroup),
		typeof(UnityEngine.Vector2),
		typeof(UnityEngine.Vector4),
		typeof(UnityEngine.JsonUtility),
		typeof(PlayableDirectorListenerWrapper),
		typeof(AlertRange),
		typeof(UnityEngine.ParticleSystem),
		typeof(UnityEngine.ParticleSystemRenderer),
		
		typeof(DragonReborn.MonoSingleton<DragonReborn.GestureManager>),
		typeof(DragonReborn.Singleton<DragonReborn.AssetTool.AssetManager>),
		typeof(DragonReborn.Singleton<DragonReborn.AssetTool.MaterialManager>),
		typeof(DragonReborn.Singleton<DragonReborn.AssetTool.SpriteManager>),
		typeof(DragonReborn.Singleton<DragonReborn.Sound.SoundManager>),
		typeof(DragonReborn.Singleton<DragonReborn.UI.UIManager>),
		typeof(Singleton<FileSystemManager>),
		typeof(Singleton<DownloadManager>),
		typeof(Singleton<SimpleHttpManager>),
		typeof(Singleton<GameObjectPoolManager>),
		typeof(Singleton<EntityPoolManager>),
		typeof(Singleton<GameObjectManager>),
		typeof(Singleton<VisualEffectManager>),
		typeof(Singleton<TaskManager>),
		typeof(Singleton<PerformanceLevelManager>),
		typeof(GCManualControl),
		typeof(Singleton<ProjectileManager>),
		typeof(Singleton<ScriptEngine>),
		typeof(JobsUtility.JobScheduleParameters),
		typeof(PerformanceSetting),
		typeof(CellSizeComponent),
		typeof(DragonReborn.UI.LuaTableViewProCell),
		typeof(DragonReborn.UI.ShrinkText),
		typeof(DragonReborn.UI.LinkText),
		typeof(DragonReborn.UI.UIMediatorProperty),
		typeof(DragonReborn.UI.UIMediatorProperty.UIMediatorAttribute),
		typeof(System.Collections.Generic.Dictionary<System.Type, DragonReborn.IFrameworkInterface>),
		typeof(System.Collections.Generic.HashSet<int>.Enumerator),
		typeof(System.Collections.Generic.HashSet<int>),
		typeof(System.Collections.Generic.HashSet<long>),
		typeof(System.Collections.Generic.HashSet<string>),
		typeof(System.Collections.Generic.List<DragonReborn.UI.UIMediatorProperty>.Enumerator),
		typeof(System.Collections.Generic.List<UnityEngine.Vector3>.Enumerator),
		typeof(System.Collections.Generic.List<DragonReborn.UI.UIMediatorProperty>),
		typeof(System.Collections.Generic.List<UnityEngine.Vector3>),
		typeof(System.Enum),
		typeof(System.ValueType),
		typeof(System.Version),
		typeof(UIRoot),
		typeof(UnityEngine.AsyncOperation),
		typeof(UnityEngine.EventSystems.UIBehaviour),
		typeof(UnityEngine.Events.UnityEvent),
		typeof(UnityEngine.Events.UnityEvent<bool>),
		typeof(UnityEngine.Events.UnityEvent<string>),
		typeof(UnityEngine.Events.UnityEvent<float>),
		typeof(UnityEngine.Events.UnityEvent<Vector2>),
		typeof(UnityEngine.Events.UnityEventBase),
		typeof(UnityEngine.Networking.UnityWebRequest),
		typeof(UnityEngine.Networking.UnityWebRequest.Result),
		typeof(UnityEngine.Networking.UnityWebRequestAsyncOperation),
		typeof(UnityEngine.RectOffset),
		typeof(UnityEngine.Rendering.CopyTextureSupport),
		typeof(UnityEngine.Rendering.ScriptableRenderContext),
		typeof(UnityEngine.UI.Graphic),
		typeof(UnityEngine.UI.Selectable),
		typeof(UnityEngine.UI.Selectable.Transition),
		typeof(UnityEngine.WWWForm),
		typeof(TimeUtils),
		typeof(GuideUtil),
		typeof(Range2Int),
		typeof(RotationUtils),
		typeof(UnityEngine.FindObjectsInactive),
		typeof(UnityEngine.FindObjectsSortMode),
		typeof(zFrame.UI.Joystick.JoystickEvent),
		
		//City 寻找足够大的区域
		typeof(EmptyGraph),
		//City 菌毯数据反序列化工具
		typeof(CityCreepBinaryDeserializer),
		typeof(ByteBufferConvertTextureHelper),
		typeof(LuaStackTraceException),
		typeof(CityCreepController),
		typeof(CityCreepController.BlitMode),
		typeof(CityCreepInstancingController),
		typeof(CityCreepView),
		typeof(CityCreepDecorationController),
		typeof(CityCreepDecorationController.DataWrap),
		typeof(CityCreepVfxInstancingDrawer),
		typeof(InstancingBrushInfo),
		typeof(CommonInstancingBaker),
		//City 选中抬起建筑和家具时闪烁物体
		typeof(CityConstructionFlashMatController),
		//City 房间地板绘制
		typeof(CityRoomFloorController),
		//City 房间内墙和门绘制
		typeof(CityRoomWallAndDoorController),
		//City 菌毯建筑溶解淡入淡出控制
		typeof(CityMatTransitionController),
		typeof(CityHideableWall),
		typeof(CameraRenderFeaturesUtilsForLua),
		typeof(ScriptableRendererFeature),
		typeof(PostEffectRenderFeature),
		typeof(RenderObjects),
		typeof(RenderObjects.RenderObjectsSettings),
		typeof(ScriptableRenderer),
		typeof(RenderingData),
		typeof(RenderPassEvent),
		//City 内城SLG战斗表现层控制器, 播动画和控制关键骨骼旋转
		typeof(CitySLGBattleUnitController),
		typeof(RenderExtension.RenderUtil),
		
		typeof(DragonReborn.HttpResponseData),
		typeof(DragonReborn.Singleton<DragonReborn.SLG.Troop.TroopViewManager>),
		typeof(DragonReborn.UI.UIButton),
		typeof(DragonReborn.UI.UIButton.ExTransitionWrapper),
		typeof(FunPlusChat.Models.FPGroupInfo),
		typeof(FunPlusChat.Models.FPSessionConfig),
		typeof(System.Collections.Generic.Dictionary<int, int>),
		typeof(System.Collections.Generic.Dictionary<int, UnityEngine.Color>),
		typeof(System.Collections.Generic.List<FunPlusChat.Models.FPMessage>.Enumerator),
		typeof(System.Collections.Generic.List<FunPlusChat.Models.FPSession>.Enumerator),
		typeof(System.Collections.Generic.List<FunPlusChat.Models.FPSession>),
		typeof(System.Collections.Generic.List<UnityEngine.ParticleSystem>),
		typeof(System.Collections.Generic.List<UnityEngine.Vector2>),
		typeof(UIBaseListener),
		typeof(UnityEngine.Rendering.GraphicsDeviceType),
		typeof(UnityEngine.ScriptableObject),
		typeof(UnityEngine.Sprite),
		typeof(Sirenix.OdinInspector.SerializedMonoBehaviour),
		typeof(System.Collections.Generic.List<FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger>),
		typeof(UIOtherAnchor),
		typeof(UnityEngine.Networking.DownloadHandlerBuffer),
		typeof(UnityEngine.TerrainData),
		typeof(Cinemachine.CinemachineTransposer.AngularDampingMode),
		typeof(Cinemachine.CinemachineTransposer.BindingMode),
		typeof(DragonReborn.UI.UIToggle),
		typeof(DragonReborn.VisualEffect.SimpleVisualEffect),
		typeof(DragonReborn.VisualEffect.VisualEffectBase),
		typeof(System.Collections.Generic.HashSet<Notification.NotificationDynamicNode>),
		typeof(UnityEngine.AnimatorControllerParameter),
		typeof(FXAttachPointHolder),
		typeof(Defer),
		typeof(AssetPath),
		
		typeof(UICopyScreenFeature),

		IronSourceTypeHelper.GetIronSourceType(),
		typeof(SdkAdapter.SdkModels.SdkIronSource),
		typeof(Lod0CharacterInfo),
		//typeof(MultiAimConstraint),
		
		typeof(LuaTextPicImageProvider),
		typeof(ITextPicImageProvider),
		typeof(UnityEngine.Rendering.OnDemandRendering),
		
		typeof(PrefabCustomInfoHolder),
		typeof(ShaderConst),
		typeof(AutoCellSizeCalculator),

		typeof(UnityEngine.Rendering.Universal.AntialiasingMode),

		typeof(CityMaterialDissolveController),
		typeof(CityMaterialDissolveShareController),
		typeof(CityTransformTweenScaleController),
		typeof(PosSyncController),
		//native loading overlay
		typeof(DragonReborn.INativeLoadingOverlay),
		
		typeof(AnimationCurveHolder),
		typeof(AnimationCurveHolder.AnimationCurveData),
		
		typeof(QualityLevelLoader),
		typeof(BytePtrHelper),
		typeof(RendererSortingOrderModifier),
		typeof(RendererSortingOrderRecursiveModifier),
		typeof(RendererSortingLayerModifier),
		typeof(RendererSortingLayerRecursiveModifier),
	};

	[GenerateLuaHintIgnoreGetter] public static List<MemberInfo> GenerateLuaHintBlacklist = new List<MemberInfo>()
	{
		typeof(UnityEngine.GUI),
		typeof(UnityEngine.GUILayout),
		typeof(UnityEngine.GUILayoutUtility),
		typeof(UnityEngine.GUILayoutOption),
		typeof(UnityEngine.GUIStyle),
		typeof(UnityEngine.GUIUtility),
		typeof(KeyCode),
	};

	//C#静态调用Lua的配置（包括事件的原型），仅可以配delegate，interface
	[CSharpCallLua]
    public static List<Type> CSharpCallLua = new List<Type>
	{
		// dragon reborn framework
		typeof(Action),
		typeof(Action<bool, AssetHandle>),
		typeof(Action<GameObject>),
		typeof(Action<GameObject, object>),
		typeof(Action<uint>),
		typeof(Action<bool, HttpResponseData>),
		typeof(Action<bool, string>),
		typeof(Action<List<Vector3>>),
		typeof(Action<Vector3>),
		typeof(Action<Vector2>),
		typeof(Action<Vector2Int>),
		typeof(Action<bool, object, VisualEffectHandle>),
		typeof(Action<int, int>),
		typeof(Action<int, int, int>),
		typeof(Action<int, UnityEngine.UI.Text>),
		typeof(Action<bool, int>),
		typeof(Action<int, List<FPMessage>>),
		typeof(Action<FPMessage>),
		typeof(Action<FPSession>),
		typeof(Action<int, UserInfo>),
		typeof(Action<int, List<UserInfo>>),
		typeof(Action<GameObject, UnityEngine.EventSystems.PointerEventData>),
		typeof(Action<UnityEngine.Playables.PlayableDirector>),
		typeof(Action<ulong>),
		typeof(Action<ulong, ulong>),
		typeof(Action<string, ulong>),
		typeof(Action<string, ulong, ulong>),
		typeof(Action<LuaTable, bool, string>),
		typeof(Action<IntPtr, int>),
		typeof(System.Func<object, object, bool>),

        // map
        typeof(Func<LuaTable, long, Grid.TileView>),
        typeof(Func<LuaTable, string, Grid.KingdomView>),
        typeof(Action<LuaTable, Vector2Short, Vector2Short, int>),
        typeof(HeightProvider.HeightMapLoaded),
	    typeof(HeightProvider.HeightMapUnloaded),
	    typeof(Action<bool, int, int>),
		typeof(Action<GameObject, bool>),
        
        //UI
        typeof(IUIMediatorProcessor),
        typeof(LuaTextPicImageProvider.LuaTextPicImageProviderFunc),
        typeof(ITextPicImageProvider),

		// others
		typeof(UnityAction),
		typeof(UnityAction<bool>),
		typeof(UnityAction<float>),
		typeof(UnityAction<int>),
		typeof(UnityAction<string>),
		typeof(UnityAction<object>),
		typeof(System.Func<int, int, bool>),
		typeof(Func<Transform, bool>),
		typeof(Action<VersionControl.Result,string>),
		typeof(IGestureListener),
		typeof(Func<int, int[]>),
		typeof(NewMapSystem.HexMapSystem.HexMapGridDerived.GetMistDataDelegate),
		
		// DOTween
		typeof(DOSetter<float>),
		typeof(DOGetter<float>),
		typeof(TweenCallback),

		// PooledGameObjectCreateHelper
		typeof(GameObjectRequestCallback),
		
		//
		typeof(DragonReborn.AssetTool.ECS.EntityRequestCallback),
		
		//Pathfinding
		typeof(Action<LuaTable>),
		typeof(PlotDirector.CGLuaCallback),
		
		typeof(System.Action<UnityEngine.AsyncOperation>),
		typeof(System.Action<UnityEngine.Networking.UnityWebRequestAsyncOperation>),
		typeof(DragonReborn.LuaCellSizeProvider.SizeGetter),
		typeof(SdkStreamMedia.PlayCallback),
		typeof(DragonReborn.IFrameLuaExecutorReceiver.LuaExecutor),
		
		//Funplus Chat SDK
		typeof(Action<FunResult<FPTranslatedInfo>>),
		typeof(Func<LuaTable, Vector3, Vector3>),
	};

	// 需要在Lua中使用的纯struct类型（指不包含引用类型字段的struct）
	[GenerateLuaHint]
	[GCOptimize] public static List<Type> GCOptimize = new List<Type>()
	{
		typeof(Grid.DecorationInstance),
		typeof(DragonReborn.AABB),
		typeof(Rect),
		typeof(RectInt),
		typeof(Plane),
		typeof(LayerMask),
		typeof(RaycastHit),
		typeof(RaycastHit2D),
		typeof(RefreshRate),
		typeof(Resolution),
	};

	// GCOptimize的扩展配置，当某些struct的private field是常用值，你并不希望通过property来访问时，可以配置此列表
	[AdditionalProperties] public static Dictionary<Type, List<string>> AdditionalProperties =
	new Dictionary<Type, List<string>>()
	{
		{
			typeof(UnityEngine.Rect), new List<string>()
			{
				nameof(Rect.x),
				nameof(Rect.y),
				nameof(Rect.width),
				nameof(Rect.height),
				nameof(Rect.position),
				nameof(Rect.center),
				nameof(Rect.max),
				nameof(Rect.min),
				nameof(Rect.size),
				nameof(Rect.zero),
				nameof(Rect.xMin),
				nameof(Rect.xMax),
				nameof(Rect.yMin),
				nameof(Rect.yMax),
				nameof(Rect.zero),
			}
		}
	};


	[GenerateLuaHint]
	[XLuaDynamicBindingChecker.SkipInCollectListAttribute]
	[ReflectionUse] public static IEnumerable<Type> ReflectionUseTypes = new[]
	{
		typeof(UnityEngine.RenderSettings),
		typeof(UnityEngine.GUI),
		typeof(UnityEngine.GUILayout),
		typeof(UnityEngine.GUILayoutUtility),
		typeof(UnityEngine.GUILayoutOption),
		typeof(UnityEngine.GUIStyle),
		typeof(UnityEngine.GUIUtility),
		typeof(UnityEngine.Diagnostics.Utils),
		typeof(UnityEngine.Diagnostics.ForcedCrashCategory),
		typeof(IOAccessRecorder),
	};

	
	//黑名单
	[BlackList]
	public static List<List<string>> BlackList = new List<List<string>>()  {
		new List<string>(){"System.IO.DirectoryInfo", "Create", "System.Security.AccessControl.DirectorySecurity"},
		new List<string>(){"System.IO.DirectoryInfo", "CreateSubdirectory", "System.String", "System.Security.AccessControl.DirectorySecurity"},
		new List<string>(){"System.IO.DirectoryInfo", "GetAccessControl", "System.Security.AccessControl.AccessControlSections"},
		new List<string>(){"System.IO.DirectoryInfo", "SetAccessControl", "System.Security.AccessControl.DirectorySecurity"},
		new List<string>(){"System.IO.File", "Create", "System.String", "System.Int32", "System.IO.FileOptions", "System.Security.AccessControl.FileSecurity"},
		new List<string>(){"System.IO.File", "GetAccessControl", "System.String", "System.Security.AccessControl.AccessControlSections"},
		new List<string>(){"System.IO.File", "GetAccessControl", "System.String"},
		new List<string>(){"System.IO.File", "SetAccessControl", "System.String", "System.Security.AccessControl.FileSecurity"},
		new List<string>(){"System.IO.FileInfo", "GetAccessControl", "System.Security.AccessControl.AccessControlSections"},
		new List<string>(){"System.IO.FileInfo", "SetAccessControl", "System.Security.AccessControl.FileSecurity"},
		new List<string>(){"System.IO.Path", "GetDirectoryName", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "GetExtension", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "GetFileName", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "GetFileNameWithoutExtension", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "GetPathRoot", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "HasExtension", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "IsPathFullyQualified", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "IsPathRooted", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "Join", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "Join", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "JoinInternal", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "JoinInternal", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "JoinInternal", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]"},
		new List<string>(){"System.IO.Path", "TryJoin", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.Span`1[System.Char]", "System.Int32&"},
		new List<string>(){"System.IO.Path", "TryJoin", "System.ReadOnlySpan`1[System.Char]", "System.ReadOnlySpan`1[System.Char]", "System.Span`1[System.Char]", "System.Int32&"},
		new List<string>(){"System.Type", "MakeGenericSignatureType", "System.Type", "System.Type[]"},
		new List<string>(){"System.Type", "IsCollectible"},
		new List<string>(){"UnityEngine.Device.Screen", "MoveMainWindowTo", "UnityEngine.DisplayInfo&", "UnityEngine.Vector2Int"},
		new List<string>(){"UnityEngine.Screen", "MoveMainWindowTo", "UnityEngine.DisplayInfo&", "UnityEngine.Vector2Int"},
		new List<string>(){"UnityEngine.CanvasRenderer", "onRequestRebuild"},
		new List<string>(){"System.Guid", ".ctor", "System.ReadOnlySpan`1[System.Byte]"},
		new List<string>(){"UnityEngine.Input", "location"},
		new List<string>(){ "DragonReborn.SLG.Troop.TroopViewManager", "GetTroopEntity","System.Int64"},
		new List<string>(){ "DragonReborn.UI.LuaBaseComponent", "LuaScriptFullPath"},
		new List<string>(){ "DragonReborn.UI.LuaBaseComponent", "SetLuaScriptFullPath", "System.String"},
		new List<string>(){ "DragonReborn.UI.LuaTableViewProCell", "LuaScriptFullPath"},
		new List<string>(){ "DragonReborn.UI.LuaTableViewProCell", "SetLuaScriptFullPath", "System.String"},
		new List<string>(){ "DragonReborn.UI.LuaUIMediator", "LuaScriptFullPath"},
		new List<string>(){ "DragonReborn.UI.LuaUIMediator", "SetLuaScriptFullPath", "System.String"},
	};

	[ParameterRefLikeTypes] 
	[ParameterRefLikeTypesForHint]
	public static List<Type> ParameterRefLikeTypes = new List<Type>()
	{
		typeof(LuaTableRefReadOnly),
		typeof(ReadOnlySpan<byte>),
		typeof(LuaArrayTableRef),
	};

	[AdditionalLinkXmlTypes]
	public static List<Type> AdditionalLinkXmlTypes = new List<Type>()
	{
		typeof(MethodInfo),
		Type.GetType("System.Reflection.RuntimeMethodInfo"),
		typeof(UnityEngine.Debug).Assembly.GetType("UnityEngine.DebugLogHandler")
	};

	private static Dictionary<Type, List<string>> _tempDoNotGenDic;

	[DoNotGen]
	public static Dictionary<Type, List<string>> DoNotGenGetter
	{
        get
        {
			InitTempDoNotGenDicOnce();
			return _tempDoNotGenDic;
		}
	}

	[XLuaDynamicBindingChecker.SkipInCollectListAttribute]
	public static IEnumerable<Type> AutoBindGenSkipTypes = new []
	{
		typeof(UnityEngine.Handheld),
#if UWA_ENABLED_IN_PROJECT && (UNITY_IPHONE || UNITY_ANDROID || UNITY_STANDALONE_WIN)
		typeof(UWAEngine),
		typeof(UWAEngine.Mode),
		typeof(UWAEngine.DumpType),
#endif
	};

	private static void InitTempDoNotGenDicOnce()
    {
		if (null != _tempDoNotGenDic) return;
		var _toWrite = new ConcurrentDictionary<Type, List<string>>();
		var allTypes = XLua.Utils.GetAllTypes(false);
		var t = typeof(DoNotGenCollectAttribute);
		var findFlag = BindingFlags.Public 
			| BindingFlags.Instance 
			| BindingFlags.Static 
			| BindingFlags.GetField 
			| BindingFlags.SetField 
			| BindingFlags.GetProperty 
			| BindingFlags.SetProperty;
		Parallel.ForEach(allTypes, type =>
		{
			if (type.IsNested && type.DeclaringType is { IsPublic: false }) return;
			if (type.IsDefined(t))
            {
				_toWrite.TryAdd(type, type.GetMembers(findFlag).Select(m => m.Name).Distinct().ToList());
			}
            else
            {
	            var tags = type.GetMembers(findFlag).Where(m => m.IsDefined(t)).Select(m => m.Name);
	            if (tags.Any()) {
		            _toWrite.TryAdd(type, tags.Distinct().ToList());
	            }
            }
		});
		var l = _toWrite.GetOrAdd(typeof(UnityEngine.Rendering.ScriptableRenderContext), t =>new List<string>());
		l.Add("EmitWorldGeometryForSceneView");
		l = _toWrite.GetOrAdd(typeof(UnityEngine.UI.Graphic), t => new List<string>());
		l.Add("OnRebuildRequested");
		_tempDoNotGenDic = new Dictionary<Type, List<string>>(_toWrite);
	}
}


#endif
