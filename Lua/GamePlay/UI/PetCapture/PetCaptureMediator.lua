local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ProtocolId = require("ProtocolId")
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local BaseUIMediator = require("BaseUIMediator")
local Utils = require("Utils")
local TimerUtility = require("TimerUtility")
local ArtResourceUtils = require("ArtResourceUtils")
local UIMediatorNames = require("UIMediatorNames")
local GuideConst = require("GuideConst")
local ManualResourceConst = require("ManualResourceConst")

local PetWildCatchUseItemByUIParameter = require("PetWildCatchUseItemByUIParameter")
local PetWildCatchUseItemByUIInCastleParameter = require("PetWildCatchUseItemByUIInCastleParameter")

local CIRCLE_SCALE_MAX = 1
local CIRCLE_SHRINKING_TIME = 2
local CIRCLE_SCALE_MIN = 0.01
local CIRCLE_SHRINKING_SPEED = (CIRCLE_SCALE_MAX - CIRCLE_SCALE_MIN) / CIRCLE_SHRINKING_TIME
local JUDGE_GOOD_PCT = 0.6667
local JUDGE_PERFECT_PCT = 0.1667
local VECTOR3_ONE = CS.UnityEngine.Vector3.one
local VECTOR3_ZERO = CS.UnityEngine.Vector3.zero
local VFX_OFFSET = CS.UnityEngine.Vector3.zero
local VECTOR3_UP = CS.UnityEngine.Vector3.up
local QUATERNION_IDENTITY = CS.UnityEngine.Quaternion.identity
local RANGE_MIDDLE_MIN = 0.4
local RANGE_MIDDLE_MAX = 0.6

local SHOWCASE_TIME_MIN = 10
local SHOWCASE_TIME_MAX = 30

local ANIM_LAND = "land"
local ANIM_SHOWCASE = "catchshow"
local ANIM_IDLE = "idle"
local LAYER_BASE = 0

local SHADER_PARAM_POLLUTION = "_POLLUTION"
local SHADER_KEYWORD_POLLUTION_NONE = "_POLLUTION_NONE"
local SHADER_KEYWORD_POLLUTION_ADD = "_POLLUTION_ADD"

local KEY_SKIP_PET_CAPTURE_ANIM = 'skip_pet_capture_anim'

---@class PetCaptureMediatorParameter
---@field isCity boolean
---@field petWildCfgId number
---@field npcServiceCfgId number
---@field elementId number
---@field petCompId number
---@field villageId number
---@field landCfgId number

---@class PetCaptureMediator:BaseUIMediator
---@field new fun():PetCaptureMediator
---@field super BaseUIMediator
local PetCaptureMediator = class('PetCaptureMediator', BaseUIMediator)

function PetCaptureMediator:ctor()
    self.currentScale = CIRCLE_SCALE_MAX
	self.currentPct = 0
	self.isCircleScaleFrozen = false
    ---@type CS.UnityEngine.Rect
    self.cancelArea = nil
    self.cancelling = false
    self.directorTimelineMap = {}
    self.remainItemList = nil
    self.usingItemId = 0
    self.showcaseStartTime = 0
end

function PetCaptureMediator:InitConsts()
    CIRCLE_SHRINKING_TIME = ConfigRefer.PetConsts.CatchCircleTime and ConfigRefer.PetConsts:CatchCircleTime() or CIRCLE_SHRINKING_TIME
	CIRCLE_SHRINKING_SPEED = (CIRCLE_SCALE_MAX - CIRCLE_SCALE_MIN) / CIRCLE_SHRINKING_TIME
    JUDGE_PERFECT_PCT = ConfigRefer.PetConsts.CatchPetCirclePerfect and ConfigRefer.PetConsts:CatchPetCirclePerfect() or JUDGE_PERFECT_PCT
	JUDGE_GOOD_PCT = ConfigRefer.PetConsts.CatchPetCircleGood and ConfigRefer.PetConsts:CatchPetCircleGood() or JUDGE_GOOD_PCT

    if (ConfigRefer.PetConsts:TimelineCatchpetVFXOffsetLength() > 2) then
		VFX_OFFSET = CS.UnityEngine.Vector3(
			ConfigRefer.PetConsts:TimelineCatchpetVFXOffset(1),
			ConfigRefer.PetConsts:TimelineCatchpetVFXOffset(2),
			ConfigRefer.PetConsts:TimelineCatchpetVFXOffset(3)
		)
	end
end

---@param param PetCaptureMediatorParameter
function PetCaptureMediator:OnCreate(param)
	self.param = param
	--参数检查
	if self.param.isCity then
		if self.param.npcServiceCfgId == nil or self.param.npcServiceCfgId == 0 then
			g_Logger.Error('City抓宠, npcServiceCfgId %s', self.param.npcServiceCfgId)
		end

		if self.param.elementId == nil or self.param.elementId == 0 then
			g_Logger.Error('City抓宠, elementId %s', self.param.elementId)
		end
	else
		if self.param.petCompId == nil or self.param.petCompId == 0 then
			g_Logger.Error('野外抓宠, petCompId %s', self.param.petCompId)
		end

		if self.param.landCfgId == nil or self.param.landCfgId == 0 then
			g_Logger.Error('抓宠需要传入LandCfgId')
		end
	end

    self:InitConsts()

    self.txtSkip = self:Text('p_text_skip', "pet_capture_anime_skip_name")
    ---@type CS.StatusRecordParent
	self.toggleSkip = self:BindComponent("p_toggle_set", typeof(CS.StatusRecordParent))
    self.btnSkip = self:Button("p_toggle_set", Delegate.GetOrCreate(self, self.OnSkipButtonClick))

    -- 取消操作区域
    self.cancelNode = self:GameObject("p_cancel_capture")
	---@type CS.StatusRecordParent
	self.cancelController = self:BindComponent("p_cancel_capture", typeof(CS.StatusRecordParent))
	self.cancelImage = self:Image("p_btn_cancel_cap")

    -- 抓宠判断光圈
    self.judgeGroup = self:GameObject("p_group_capture_light")
	self.judgeCircle = self:GameObject("p_vx_control")
	self.judgeCircleVx = self:BindComponent("vx_circle", typeof(CS.UnityEngine.CanvasGroup))
    self.judgeTrans = self.judgeCircle.transform

    -- 抓宠操作按钮
	self:DragEvent("p_btn_capture",
        Delegate.GetOrCreate(self, self.OnCaptureDragStart),
        Delegate.GetOrCreate(self, self.OnCaptureDrag),
        Delegate.GetOrCreate(self, self.OnCaptureDragEnd),
        false)
    self:DragCancelEvent("p_btn_capture", Delegate.GetOrCreate(self, self.OnCaptureDragCancel))

    -- 底板
	self.goUIGroup = self:GameObject("p_group")

    -- 切换抓宠道具
    self.buttonChangeItem = self:Button("p_btn_change", Delegate.GetOrCreate(self, self.OnChangeItemButtonClick))
    self.imgCurrentCaptureItem = self:Image("p_icon_item_capture")
    self.imageCurrentItem = self:Image("p_icon_cap")
	self.txtCurrentItemAmount = self:Text("p_text_quantity")

    -- 所有的抓宠道具展示
    self.goCaptureItems = self:GameObject("p_group_item_capture")
    self.goCaptureItems:SetVisible(false)
    self.textItemGroup = self:Text("p_text_capture", "pet_memo8")
	self.tableCaptureItems = self:TableViewPro("p_table_capture")
	
    -- 抓宠结果反馈
    self.judgePerfect = self:GameObject("p_img_perfect")
	self.textPerfect = self:Text("p_text_perfect", "PERFECT")
	self.judgeGood = self:GameObject("p_img_good")
	self.textGood = self:Text("p_text_good", "GOOD")
	self.judgeAlmost = self:GameObject("p_img_almost")
	self.textAlmost = self:Text("p_text_status_almost", "ALMOST")

	self:PreloadUI3DView()
end

function PetCaptureMediator:GetEnvPath(landCfgId)
	local landCfgCell = ConfigRefer.Land:Find(landCfgId)
	if landCfgCell then
		local petCatchClientResCfgCell = ConfigRefer.PetCaptureClientRes:Find(landCfgCell:PetCaptureScene())
		if petCatchClientResCfgCell then
			return ArtResourceUtils.GetItem(petCatchClientResCfgCell:Background())
		end
	end

	return ManualResourceConst.ui3d_model_coastalForest
end

function PetCaptureMediator:PreloadUI3DView()
	local petWildCfg = ConfigRefer.PetWild:Find(self.param.petWildCfgId)
	local petCfg = ConfigRefer.Pet:Find(petWildCfg:PetId())
    local seNpcCfg = ConfigRefer.SeNpc:Find(petCfg:SeNpcId())
    local runtimeId = self:GetRuntimeId()
    local modelPath = ArtResourceUtils.GetItem(seNpcCfg:Model())
    
	local envPath = self:GetEnvPath(self.param.landCfgId)
	self:SetAsyncLoadFlag()
    -- g_Game.UIManager:SetupUI3DModelView(runtimeId, modelPath, envPath, nil, 
	---@type UI3DViewerParam
	local viewParam = {}
	viewParam.shadowDistance = 48
	viewParam.shadowCascades = 1
	viewParam.modelPath = modelPath
	viewParam.envPath = envPath       
	viewParam.preCallback = function(view)
		view:InitVirtualCameraSetting(self:Get3DCameraSettings())
	end
	viewParam.callback = function(view) 
		if not view then
			return
		end
		self:RemoveAsyncLoadFlag()
		self:SetupUI3DView(view)
    end

	g_Game.UIManager:SetupUI3DView(runtimeId,require('UI3DViewConst').ViewType.ModelViewer,viewParam)

end

---@param param PetCaptureMediatorParameter
function PetCaptureMediator:OnOpened(param)
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))

    g_Game.ServiceManager:AddResponseCallback(PetWildCatchUseItemByUIParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetWildCatchUseItemResponse))
	g_Game.ServiceManager:AddResponseCallback(PetWildCatchUseItemByUIInCastleParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetWildCatchUseItemResponse))
	g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncPetWildCatchFail, Delegate.GetOrCreate(self, self.OnPushPetCatchFailed))
	g_Game.ServiceManager:AddResponseCallback(ProtocolId.SyncGetPet, Delegate.GetOrCreate(self,self.SyncGetPet))

    local isSkip = self:IsSkipAnimation()
    self:SetSkipAnimation(isSkip)

    self.petWildCfg = ConfigRefer.PetWild:Find(self.param.petWildCfgId)
    self.petCfg = ConfigRefer.Pet:Find(self.petWildCfg:PetId())
    self.petTypeCfg = ConfigRefer.PetType:Find(self.petCfg:Type())
    self.upHeight = self.petTypeCfg:CGCfg(1)
	self.upTime = self.petTypeCfg:CGCfg(2)
	self.upDelay = self.petTypeCfg:CGCfg(3)
	self.downDelay = self.petTypeCfg:CGCfg(4)
end

---@param param PetCaptureMediatorParameter
function PetCaptureMediator:OnClose(param)
	self:CleanTimelines()
	
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))

    g_Game.ServiceManager:RemoveResponseCallback(PetWildCatchUseItemByUIParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetWildCatchUseItemResponse))
	g_Game.ServiceManager:RemoveResponseCallback(PetWildCatchUseItemByUIInCastleParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetWildCatchUseItemResponse))
	g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncPetWildCatchFail, Delegate.GetOrCreate(self, self.OnPushPetCatchFailed))
	g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.SyncGetPet, Delegate.GetOrCreate(self,self.SyncGetPet))

    g_Game.UIManager:CloseUI3DView(self:GetRuntimeId())
	g_Game.UIManager:ResetUI3DRoot()
	-- 野外抓宠，在退出页面的时候，解锁宠物
	if not self.param.isCity then
		ModuleRefer.PetCaptureModule:UnlockWildPet(self.param.petCompId, self.param.villageId)
	end

	-- 抓宠成功触发引导
	if self.petResultParam and self.petResultParam.win then
		ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.PetCaptureFinish)
	end
end

---@param param PetCaptureMediatorParameter
function PetCaptureMediator:OnShow(param)
end

---@param param PetCaptureMediatorParameter
function PetCaptureMediator:OnHide(param)
end

---@param viewer UI3DModelView
function PetCaptureMediator:SetupUI3DView(viewer)
    ---@type UI3DModelView
	self.ui3dModelView = viewer

    -- 初始化
    self.ui3dModelView:SetModelAngles(CS.UnityEngine.Vector3.zero)
    self.ui3dModelView:SetModelPosition(CS.UnityEngine.Vector3.zero)   

    -- 宠物相关
    self.petModelGo = viewer:GetModelGo()
	
    self.petTrans = self.petModelGo.transform
	self.petFbxTrans = self.petTrans:GetChild(0).transform
	self.petFbxOrgPos = VECTOR3_ZERO
    ---@type CS.UnityEngine.Animator
    self.petAnimator = self.petModelGo:GetComponentInChildren(typeof(CS.UnityEngine.Animator))

    self:ResetPct()
	self:SetBottomObjectsVisible(true)
	self:UnfreezeCircleScale()
    self:SetPollutionState(true)
    self:Show(true)
	require('CloudUtils').Uncover()
end

---等待timeline，模型加载完成后，再显示
---@param reset boolean @是否重置到初始状态
function PetCaptureMediator:Show(reset)
	if (ModuleRefer.PetCaptureModule:IsPetTimelineLoadComplete()) then
		self:DoShow(reset)
		-- 触发抓宠引导
		ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.PetCaptureStart)
		return
	end

	self.waitingForShow = true
	self.waitingForShowReset = reset
end

---@param reset boolean @是否重置到初始状态
function PetCaptureMediator:DoShow(reset)
	if (reset) then
		self:Reset()

		self.petAnimator:Play(ANIM_SHOWCASE)
		self:RestartShowcase()
	end
end

function PetCaptureMediator:RestartShowcase()
	self.showcaseIntervalTime = math.random(SHOWCASE_TIME_MIN, SHOWCASE_TIME_MAX)
	self.showcaseStartTime = g_Game.Time.time
end

---@return boolean
function PetCaptureMediator:TryAutoSelectUsingItem()
	if self.remainItemList == nil then
		return
	end

	-- 当前道具还有剩余
	local data = self.remainItemList[self.usingItemId]
	if (data and data.count > 0) then
		return true
	end

	-- 换其他的道具
	for itemId, itemData in pairs(self.remainItemList) do
		if (itemData.count > 0) then
			self:SelectUsingItem(itemId)
			return true
		end
	end

	-- 没有可用道具了(后端会触发失败推送)
	return false
end

---@param itemCell ItemConfigCell
function PetCaptureMediator:OnItemClick(itemCell)
	local itemId = itemCell:Id()
	self:SelectUsingItem(itemId)
	self.goCaptureItems:SetVisible(false)
end

---@param itemId number
function PetCaptureMediator:SelectUsingItem(itemId)
	if (itemId ~= self.usingItemId and self.remainItemList ~= nil and self.remainItemList[itemId].count > 0) then
		-- 处理上一个选择的道具
		local selectedItem = self.remainItemList[self.usingItemId]
		if (selectedItem) then
			selectedItem.data.showSelect = false
		end

		-- 处理新选择的道具
		self.usingItemId = itemId
		selectedItem = self.remainItemList[self.usingItemId]
		selectedItem.data.showSelect = true
		self.usingItemCfg = selectedItem.data.configCell
		self:RefreshUsingItem()
	else
		g_Logger.Error('SelectUsingItem尝试选择的道具: 1, 没有变化 or 2, 数量为0')
	end
end

function PetCaptureMediator:RefreshUsingItem()
	if (not self.usingItemCfg or not self.remainItemList) then 
        return 
    end

	g_Game.SpriteManager:LoadSprite(self.usingItemCfg:Icon(), self.imgCurrentCaptureItem)
    g_Game.SpriteManager:LoadSprite(self.usingItemCfg:Icon(), self.imageCurrentItem)
	self.txtCurrentItemAmount.text = string.format("x%s", self.remainItemList[self.usingItemId].count)
end

function PetCaptureMediator:Reset()
	SHOWCASE_TIME_MIN = ConfigRefer.PetConsts.CatchshowMinTime and ConfigRefer.PetConsts:CatchshowMinTime() or SHOWCASE_TIME_MIN
	SHOWCASE_TIME_MAX = ConfigRefer.PetConsts.CatchshowMaxTime and ConfigRefer.PetConsts:CatchshowMaxTime() or SHOWCASE_TIME_MAX

	self.remainItemList = {}
    -- 抓宠道具
	self.petCatchItemList = ModuleRefer.PetModule:GetPetCatchItemCfgList()
	for _, itemCell in pairs(self.petCatchItemList) do
		local itemId = itemCell:ItemCfg()
		local itemCfg = ConfigRefer.Item:Find(itemId)
        local count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
		local itemData = {
			count = count,
			data = {
				configCell = itemCfg,
				count = count,
				useNoneMask = count <= 0,
				onClick = Delegate.GetOrCreate(self, self.OnItemClick),
			},
		}
		self.remainItemList[itemId] = itemData
	end

	self:TryAutoSelectUsingItem()

	self.tableCaptureItems:Clear()
    for _, item in pairs(self.remainItemList) do
        self.tableCaptureItems:AppendData(item.data)
    end
    self.tableCaptureItems:RefreshAllShownItem()

    self:RefreshUsingItem()
end

---设置宠物的污染状态
---@param enable boolean
function PetCaptureMediator:SetPollutionState(enable)
	-- local value = 0
	-- if (enable) then
	-- 	value = 1
	-- 	self.petModelGo:SetKeywordEnabledForAllMaterials(SHADER_KEYWORD_POLLUTION_ADD, true)
	-- 	self.petModelGo:SetKeywordEnabledForAllMaterials(SHADER_KEYWORD_POLLUTION_NONE, false)
	-- else
	-- 	self.petModelGo:SetKeywordEnabledForAllMaterials(SHADER_KEYWORD_POLLUTION_NONE, true)
	-- 	self.petModelGo:SetKeywordEnabledForAllMaterials(SHADER_KEYWORD_POLLUTION_ADD, false)
	-- end
	-- self.petModelGo:SetFloatForAllMaterials(SHADER_PARAM_POLLUTION, value)
end

--- 获取3D相机参数
---@param self UIPetMediator
function PetCaptureMediator:Get3DCameraSettings()
    local cameraSetting = {}
    for i = 1, 2 do
        local setting = {}
        setting.fov = 40
        setting.nearCp = 0.1
        setting.farCp = 5000
		setting.localPos = CS.UnityEngine.Vector3(0, 0.9000244, 6.500001)
        setting.rotation = CS.UnityEngine.Vector3(0, 180, 0)
        cameraSetting[i] = setting
    end
    return cameraSetting
end

function PetCaptureMediator:Enable3DCamera()
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera.enabled = true
end

function PetCaptureMediator:Disable3DCamera()
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    camera.enabled = false
end

function PetCaptureMediator:Get3DCameraTransform()
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    return camera.transform
end

---@param delta number @seconds
function PetCaptureMediator:OnTick(delta)
	if (not self.isCircleScaleFrozen) then 
        self.currentScale = self.currentScale - delta * CIRCLE_SHRINKING_SPEED
        if (self.currentScale <= CIRCLE_SCALE_MIN) then
            self.currentScale = CIRCLE_SCALE_MAX
        end

        self.currentPct = 1 - (CIRCLE_SCALE_MAX - self.currentScale) / (CIRCLE_SCALE_MAX - CIRCLE_SCALE_MIN)
        self.judgeTrans.localScale = VECTOR3_ONE * self.currentPct * (CIRCLE_SCALE_MAX - CIRCLE_SCALE_MIN)
        local vpct = 1 - self.currentPct

        self.judgeCircleVx.alpha = self:GetVisualPct(vpct)
    end

    if (self.waitingForShow) then
		if (ModuleRefer.PetCaptureModule:IsPetTimelineLoadComplete()) then
			self:DoShow(self.waitingForShowReset)
			self.waitingForShow = false
		end
	end

    self:TickAnimation(delta)
end

function PetCaptureMediator:TickAnimation(delta)
    if Utils.IsNull(self.petAnimator) then return end
    
	-- showcase和land播完后，播idle
    local inTransition, loop, normalizedTime = CS.AnimatorHelper.GetCurrentAnimatorState(self.petAnimator, LAYER_BASE)
    if (not inTransition) then
        if not loop and normalizedTime >= 1 then
			self.petAnimator:Play(ANIM_IDLE)
			self:RestartShowcase()
		end
    end

	if (self.showcaseStartTime > 0) then
		local showcaseTimer = g_Game.Time.time - self.showcaseStartTime
		if (showcaseTimer > self.showcaseIntervalTime) then
			self.petAnimator:Play(ANIM_SHOWCASE)
			self:RestartShowcase()
		end
	end
end

function PetCaptureMediator:OnCaptureDragStart(go, eventData)
    self:UpdateUsingItemPos(eventData.position)
	self.cancelNode:SetActive(true)
	self.cancelController:ApplyStatusRecord(0)
	self.cancelArea = self.cancelImage.transform:GetScreenRect(g_Game.UIManager:GetUICamera())
end

function PetCaptureMediator:OnCaptureDrag(go, eventData)
    self:UpdateUsingItemPos(eventData.position)
	local inRect = self.cancelArea:Contains(CS.UnityEngine.Vector2(eventData.position.x, CS.UnityEngine.Screen.height - eventData.position.y))
	if inRect then
		self.cancelController:ApplyStatusRecord(1)
		self.cancelling = true
	else
		self.cancelController:ApplyStatusRecord(0)
		self.cancelling = false
	end
end

function PetCaptureMediator:OnCaptureDragEnd(go, eventData)
    self:ResetUsingItemPos()
	self.cancelNode:SetActive(false)
	if (not self.cancelling) then
		self:TryCapture(eventData.position)
	end
end

function PetCaptureMediator:OnCaptureDragCancel(go)
    self:ResetUsingItemPos()
end

function PetCaptureMediator:ResetUsingItemPos()
	self.imgCurrentCaptureItem.transform.localPosition = CS.UnityEngine.Vector3.zero
end

function PetCaptureMediator:UpdateUsingItemPos(screenPos)
	self.imgCurrentCaptureItem.transform.position = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x, screenPos.y, 0))
end

function PetCaptureMediator:TryCapture(screenPos)
	self:FreezeCircleScale()
	self:SetBottomObjectsVisible(false)
	if (not self:CheckItem(true)) then 
        return
    end

	self.throwPos = screenPos.x / CS.UnityEngine.Screen.width
	local pct = self:GetCurrentPct()
	self:Capture(pct)
end

function PetCaptureMediator:Capture(pct)
	local _, good, perfect = self:GetJudgement(pct)
	if (perfect) then
		self.judgePerfect:SetActive(true)
	elseif (good) then
		self.judgeGood:SetActive(true)
	else
		self.judgeAlmost:SetActive(true)
	end
	self:DoCapture(pct)
end

function PetCaptureMediator:DoCapture(pct)
	if (not self:CheckItem()) then 
        return 
    end

	if self.param.isCity then
		-- 城内抓宠
		local msg = PetWildCatchUseItemByUIInCastleParameter.new()
		msg.args.CityElementTid = self.param.elementId
		msg.args.NpcServiceCfgId = self.param.npcServiceCfgId
		msg.args.ItemId = self.usingItemId
		msg.args.Ratio = pct
		msg:Send()
	else
		-- 城外抓宠
		local msg = PetWildCatchUseItemByUIParameter.new()
		msg.args.VillageEid = self.param.villageId
		msg.args.PetWildCompId = self.param.petCompId
		msg.args.ItemId = self.usingItemId
		msg.args.Ratio = pct
		msg:Send()
	end
end

---@param isSuccess boolean
---@param reply wrpc.PetWildCatchUseItemByUIReply | wrpc.PetWildCatchUseItemByUIInCastleReply
---@param req wrpc.PetWildCatchUseItemByUIRequest | wrpc.PetWildCatchUseItemByUIInCastleRequest
function PetCaptureMediator:OnPetWildCatchUseItemResponse(isSuccess, reply, req)
    if not isSuccess then return end

	self.petResultParam = nil
	-- 刷新道具数量
	if (reply.Result == true) then
		self.petResultParam = {
			win = true,
			lose = false
		}
	else
		-- 失败
		if (not self:TryAutoSelectUsingItem()) then
			self.petResultParam = {
				win = false,
				lose = true,
				loseReason = I18N.Get("pet_drone_no_item_des")
			}
		end

        -- 刷新道具数量
		self:RefreshUsingItem()
	end

    -- 拿到结果后，开始播放动画表现
	if self:IsSkipAnimation() then
		-- 直接播最后一段
    	self:OnTimelineShakeComplete()
	else
		-- 播所有的
		self:ShowThorwingTimeline()
	end
end

---超时或道具没有了，触发失败结算
---@param isSuccess boolean
---@param data wrpc.CatchPetFailReason
function PetCaptureMediator:OnPushPetCatchFailed(isSuccess, data)
	if data == wrpc.CatchPetFailReason.CatchPetFailReason_TimeOut then
		self.petResultParam = {
			win = false,
			lose = true,
			loseReason = I18N.Get("***超时")
		}
		self:ShowResult()
	end
end

---通过抓宠行为获得宠物
---@param isSuccess boolean
---@param data wrpc.SyncGetPetRequest
function PetCaptureMediator:SyncGetPet(isSuccess, data)
    if isSuccess then
		local petView = data.PetView
		local reason = data.Reason
		if reason == wrpc.GetPetReason.GetPetReason_CatchPet then
			-- 存起来，用于抓宠成功后，播放结算页面
			self.caughtPetCompId = petView.CompId
		end
    end
end

---@param timeline CS.UnityEngine.GameObject
---@param director CS.UnityEngine.Playables.PlayableDirector
---@param listener fun(CS.UnityEngine.Playables.PlayableDirector)
---@param wrapper CS.PlayableDirectorListenerWrapper
function PetCaptureMediator:ShowTimeline(timeline, director, listener, wrapper)
	if (timeline and director and wrapper) then
		self.directorTimelineMap[director] = timeline
		wrapper.stoppedCallback = listener
		wrapper:AddStoppedListener()
		timeline.transform.position = self.petTrans.position
		timeline.transform.forward = self.petTrans.forward
		timeline:SetActive(true)
	end
end

---@param direcotr CS.UnityEngine.Playables.PlayableDirector
---@param listener fun(CS.UnityEngine.Playables.PlayableDirector)
function PetCaptureMediator:HideTimeline(director, listener)
	local wrapper = director.gameObject:GetComponent(typeof(CS.PlayableDirectorListenerWrapper))
	wrapper.stoppedCallback = nil
	wrapper:RemoveStoppedListener()
	local timeline = self.directorTimelineMap[director]
	if (Utils.IsNotNull(timeline)) then
		TimerUtility.DelayExecuteInFrame(function()
			timeline:SetActive(false)
		end, 1, false)
	end
end

function PetCaptureMediator:CleanTimelines()
	if self.directorTimelineMap then
		for director, timeline in pairs(self.directorTimelineMap) do
			self:HideTimeline(director)
			director:Stop()
		end
		table.clear(self.directorTimelineMap)
	end
end

function PetCaptureMediator:ShowThorwingTimeline()
	self.showcaseStartTime = 0

	---@type CS.UnityEngine.GameObject
	local timeline
	---@type CS.UnityEngine.Playables.PlayableDirector
	local director
	---@type CS.PlayableDirectorListenerWrapper
	local wrapper

	if (self.throwPos < RANGE_MIDDLE_MIN) then
		-- 左旋
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineThrowLeft()
	elseif (self.throwPos > RANGE_MIDDLE_MAX) then
		-- 右旋
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineThrowRight()
	else
		-- 中间
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineThrowMiddle()
	end

	self:ShowTimeline(timeline, director, Delegate.GetOrCreate(self, self.OnTimelineThrowComplete), wrapper)
end

---@param oldDirector CS.UnityEngine.Playables.PlayableDirector
function PetCaptureMediator:OnTimelineThrowComplete(oldDirector)
	---@type CS.UnityEngine.GameObject
	local timeline
	---@type CS.UnityEngine.Playables.PlayableDirector
	local director
	---@type CS.PlayableDirectorListenerWrapper
	local wrapper

    -- 关闭相机，用timeline的相机
    self:Disable3DCamera()

	timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineCapture()
	self:ShowTimeline(timeline, director, Delegate.GetOrCreate(self, self.OnTimelineCaptureComplete), wrapper)

	self:HideTimeline(oldDirector, Delegate.GetOrCreate(self, self.OnTimelineThrowComplete))

	self.judgeAlmost:SetActive(false)
    self.judgePerfect:SetActive(false)
    self.judgeGood:SetActive(false)

	-- 升起
	self.petFbxTrans:DOKill()
	self.petFbxTrans:DOLocalMove(self.petFbxOrgPos, self.upDelay):OnComplete(function()
		-- 模型消失
		self.petModelGo:SetVisible(false)
		self.petFbxTrans:DOLocalMove(self.petFbxOrgPos + VECTOR3_UP * self.upHeight, self.upTime)
	end)
end

---@param oldDirector CS.UnityEngine.Playables.PlayableDirector
function PetCaptureMediator:OnTimelineCaptureComplete(oldDirector)
	---@type CS.UnityEngine.GameObject
	local timeline
	---@type CS.UnityEngine.Playables.PlayableDirector
	local director
	---@type CS.PlayableDirectorListenerWrapper
	local wrapper

	-- 摇几下改成纯随机
	self.shakeCount = math.random(1, 3)

	-- 成功必定摇3下
	if (self.petResultParam and self.petResultParam.win) then
		self.shakeCount = 3
	end

	if (self.shakeCount == 1) then
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineShake1()
	elseif (self.shakeCount == 2) then
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineShake2()
	else
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineShake3()
	end
	
	self:ShowTimeline(timeline, director, Delegate.GetOrCreate(self, self.OnTimelineShakeComplete), wrapper)
	
	self:HideTimeline(oldDirector, Delegate.GetOrCreate(self, self.OnTimelineCaptureComplete))
end

---@param oldDirector CS.UnityEngine.Playables.PlayableDirector
function PetCaptureMediator:OnTimelineShakeComplete(oldDirector)
	---@type CS.UnityEngine.GameObject
	local timeline
	---@type CS.UnityEngine.Playables.PlayableDirector
	local director
	---@type CS.UnityEngine.GameObject
	local vfx
	---@type CS.PlayableDirectorListenerWrapper
	local wrapper

	if (not self.petResultParam or not self.petResultParam.win) then
		-- 失败
		if (self.shakeCount == 2) then
			timeline, director, vfx, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineFail2()
		elseif (self.shakeCount == 3) then
			timeline, director, vfx, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineFail3()
		else
			timeline, director, vfx, wrapper = ModuleRefer.PetCaptureModule:GetPetTimelineFail1()
		end

		-- 挂接特效
		if Utils.IsNotNull(vfx) then
			local cameraTrans = self:Get3DCameraTransform()
			vfx:SetVisible(false)
			vfx.transform:SetParent(cameraTrans)
			vfx.transform.localPosition = VFX_OFFSET
			vfx.transform.localRotation = QUATERNION_IDENTITY
			vfx:SetVisible(true)
		end

		-- 落地
		self.petModelGo:SetVisible(true)
		self.petFbxTrans:DOKill()
		self.petFbxTrans.localPosition = self.petFbxOrgPos
		self.petFbxTrans:SetVisible(false)
		self.petFbxTrans:DOLocalMove(self.petFbxOrgPos, self.downDelay):OnComplete(function()
			self.petFbxTrans:SetVisible(true)
			self.petAnimator:Play(ANIM_LAND)
			self:RestartShowcase()
		end)

	else
		-- 成功
		self.petModelGo:SetVisible(false)
		timeline, director, wrapper = ModuleRefer.PetCaptureModule:GetPettimelineSuccess()

		-- 取消污染状态
		self:SetPollutionState(false)
	end

	self:ShowTimeline(timeline, director, Delegate.GetOrCreate(self, self.OnTimelineResultComplete), wrapper)

	if (oldDirector) then
		self:HideTimeline(oldDirector, Delegate.GetOrCreate(self, self.OnTimelineShakeComplete))
	end
end

---@param oldDirector CS.UnityEngine.Playables.PlayableDirector
function PetCaptureMediator:OnTimelineResultComplete(oldDirector)
    self:Enable3DCamera()

	if (self.petResultParam) then
		self:ShowResult()
	else
		-- 继续扔球
		self:RestartShowcase()
		self:SetBottomObjectsVisible(true)
		self:UnfreezeCircleScale()
	end

	self:HideTimeline(oldDirector, Delegate.GetOrCreate(self, self.OnTimelineResultComplete))
end

---打开结算页面
function PetCaptureMediator:ShowResult()
	---@type SEPetSettlementParam
	local settlementParam = {}
	settlementParam.petCompId = self.caughtPetCompId
	settlementParam.lose = self.petResultParam.lose
	settlementParam.loseReason = self.petResultParam.loseReason
	settlementParam.autoClose = true
	settlementParam.closeCallback = Delegate.GetOrCreate(self, self.OnSettlementClose)
	g_Game.UIManager:Open(UIMediatorNames.SEPetSettlementMediator, settlementParam)
end

function PetCaptureMediator:OnSettlementClose()
	self:CloseSelf()
end

---@param pct number
---@return boolean, boolean, boolean @almost, good, perfect
function PetCaptureMediator:GetJudgement(pct)
	if (not pct or pct < 0 or pct > 1) then
		return true, false, false
	end

	if (pct <= JUDGE_PERFECT_PCT) then
		return false, false, true
	elseif (pct <= JUDGE_GOOD_PCT) then
		return false, true, false
	else
		return true, false, false
	end
end

---@param noReduce boolean
---@return boolean
function PetCaptureMediator:CheckItem(noReduce)
	if self.remainItemList == nil then
		return
	end

	local itemData = self.remainItemList[self.usingItemId]
	if (not itemData or itemData.count <= 0) then
		g_Logger:ErrorChannel("Pet", "当前使用抓捕道具数据为空或数量为0, 不应出现该情况, 请检查原因!")
		return false
	end

	if (not noReduce) then
		itemData.count = itemData.count - 1
		itemData.data.count = itemData.data.count - 1
		itemData.data.useNoneMask = itemData.data.count <= 0
	end

	return true
end

function PetCaptureMediator:OnChangeItemButtonClick()
	self.goCaptureItems:SetVisible(not self.goCaptureItems.activeSelf)
	self.tableCaptureItems:RefreshAllShownItem()
end

function PetCaptureMediator:OnSkipButtonClick()
    local value = not self:IsSkipAnimation()
    self:SetSkipAnimation(value)
end

function PetCaptureMediator:IsSkipAnimation()
    local value = g_Game.PlayerPrefsEx:GetIntByUid(KEY_SKIP_PET_CAPTURE_ANIM, 0)
    return value == 1
end

---@param skip boolean
function PetCaptureMediator:SetSkipAnimation(skip)
    local value = skip and 1 or 0
    g_Game.PlayerPrefsEx:SetIntByUid(KEY_SKIP_PET_CAPTURE_ANIM, value)

    -- 1是勾选，0是不勾选
    self.toggleSkip:ApplyStatusRecord(value)
end

function PetCaptureMediator:ResetPct()
	self.currentPct = 1
	self.currentScale = CIRCLE_SCALE_MAX
	self.judgeTrans.localScale = VECTOR3_ONE * self.currentScale
end

function PetCaptureMediator:GetCurrentPct()
	return self.currentPct
end

function PetCaptureMediator:GetVisualPct(pct)
	local x = pct / 0.83
	return math.clamp01(x * x * x * x, 1)
end

function PetCaptureMediator:FreezeCircleScale()
	self.isCircleScaleFrozen = true
end

function PetCaptureMediator:UnfreezeCircleScale()
	self.isCircleScaleFrozen = false
end

function PetCaptureMediator:SetBottomObjectsVisible(visible)
	self.goUIGroup:SetVisible(visible)
end

return PetCaptureMediator
