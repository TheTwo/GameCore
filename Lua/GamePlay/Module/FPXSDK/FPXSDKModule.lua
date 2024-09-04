--- API文档：https://tp.funplus.com.cn/documents/lmq54z/vxooub/diani8
--- 所有接口调用，都要提前判断USE_FPXSDK

local Delegate = require('Delegate')
local rapidJson = require("rapidjson")
local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local TimeFormatter = require('TimeFormatter')
local SdkCrashlytics = require("SdkCrashlytics")
local I18N = require("I18N")

---@class FPXSDKModule
local FPXSDKModule = class('FPXSDKModule', BaseModule)

-- FPX.cs
local FPX = CS.FunPlus.SDK.FPX.FPX

-- FPXConstant.cs
local FPXModule = CS.FunPlus.SDK.FPX.FPXModule
local FPXFunc = CS.FunPlus.SDK.FPX.FPXFunc
local FPXKey = CS.FunPlus.SDK.FPX.FPXKey
local FPXCode = CS.FunPlus.SDK.FPX.FPXCode

local FPX_SDK_UPLOAD_IMAGE_WIDTH = 200
local FPX_SDK_UPLOAD_IMAGE_HEIGHT = 200

--- 注册SDK的回调方法
function FPXSDKModule:RegisterSDKCallback()
    self.sdkCallbackTable =
    {
        [FPXModule.PLATFORM] =
        {
            [FPXFunc.INIT] = Delegate.GetOrCreate(self, self.OnInitCallback),
            [FPXFunc.LOGIN] =  Delegate.GetOrCreate(self, self.OnLoginCallback),
            [FPXFunc.LOGOUT] =  Delegate.GetOrCreate(self, self.OnLogoutCallback),
            --- Payment ---
            [FPXFunc.GET_PRODUCTS_INFO] = Delegate.GetOrCreate(self, self.OnGetProductsInfoCallback),
            [FPXFunc.PAY] = Delegate.GetOrCreate(self, self.OnPayCallback),
        },
        [FPXModule.PUSH] =
        {
            [FPXFunc.REGISTER_DEVICE_TOKEN] = Delegate.GetOrCreate(self, self.OnInitPushModuleCallback),
            [FPXFunc.IS_NOTIFICATION_ENABLED] = Delegate.GetOrCreate(self, self.OnQueryNotificationEnableCallback),
        },
        [FPXModule.TOOLS] = {
            ["uploadCheckPic"] = Delegate.GetOrCreate(self, self.OnUploadCustomHeadIconCallback),
        },
    }
end

---@param module string
---@param func string
---@param result string
function FPXSDKModule:SDKCallbackCenter(module, func, result)
    g_Logger.Log('SDKCallbackCenter %s %s %s', module, func, result)

    if not self.sdkCallbackTable then
        g_Logger.Error('收到SDKCallbackCenter时机不对, FPXSDKModule还没有初始化')
        return
    end

    local functionTable = self.sdkCallbackTable[module]
    if functionTable then
        local onCallbackFunc = functionTable[func]
        if onCallbackFunc then
            onCallbackFunc(result)
        else
            g_Logger.Log('Func %s not register in Module %s', func, module)
        end
    else
        g_Logger.Log('Module %s not register', module)
    end
end

function FPXSDKModule:CheckSDKStatus()
    if self.sdkInit then
        return true
    end

    g_Logger.Error('FPXSDK not init')
    return false
end

--- 初始化SDK
--- 有回调: OnInitCallback
function FPXSDKModule:InitSDK(callback)
    if USE_FPXSDK then
        if not self.initProcessing then
            g_Logger.Log('FPXSDK init')
            self.initProcessing = true
            self.initCallback = callback
            self:RegisterSDKCallback()
            FPX.Init(Delegate.GetOrCreate(self, self.SDKCallbackCenter))
        else
            g_Logger.Error('FPX.Init is processing, ignoring this invoke')
        end
    end
end

---@param response string
function FPXSDKModule:OnInitCallback(response)
    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        self.sdkInit = true
        if self.initCallback then
            self.initCallback(true)
            SdkCrashlytics.RecordCrashlyticsLog("FPXSDKModule:OnInitCallback:SUCCESS")
        end
    else
        self.sdkInit = false
        if self.initCallback then
            self.initCallback(false)
        end

        local msg = result['msg']
        g_Logger.Error('OnInitCallback Error, code:%s, msg:%s', code, msg)
        SdkCrashlytics.RecordCrashlyticsLog(("FPXSDKModule:OnInitCallback:FAILURE code:%s msg:%s"):format(code, msg))
    end

    self.initProcessing = false
    self.initCallback = nil
end

function FPXSDKModule:OnRegister()
    self.sdkInit = false
    self.hasAccountLoggin = false
    self.sdkCallbackTable = nil
end

function FPXSDKModule:OnRemove()
    self.sdkInit = false
    self.hasAccountLoggin = false
    self.sdkCallbackTable = nil
end

function FPXSDKModule:OnLoggedIn()
    self.hasAccountLoggin = true
end

--- SDK登录
--- 有回调: OnLoginCallback
function FPXSDKModule:Login(callback)
    if USE_FPXSDK and self:CheckSDKStatus() then
        if not self.loginProcessing then
            self.loginProcessing = true
            self.loginCallback = callback
            FPX.Call(FPXModule.PLATFORM, FPXFunc.LOGIN, nil)
            g_Logger.Log('FPX.Login')
            SdkCrashlytics.RecordCrashlyticsLog("FPXSDKModule:Login")
        else
            g_Logger.Error('FPX.Login is processing, ignoring this invoke')
        end
    end
end

---@param response string
function FPXSDKModule:OnLoginCallback(response)
    g_Logger.Log('OnLoginCallback %s', response)

    if not self.loginCallback then
        g_Logger.Error('loginCallback没有设置, 忽略此次OnLoginCallback')
        return
    end

    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        local data = result['data']
        local channel_uid = data['channel_uid']
        local account_id = data['account_id']
        local is_new = data['is_new']
        local ticket = data['ticket']
        self.loginCallback(true, channel_uid, account_id, is_new, ticket)
        SdkCrashlytics.RecordCrashlyticsLog("FPXSDKModule:OnLoginCallback:SUCCESS")
    else
        local msg = result['msg']
        g_Logger.Error('OnLoginCallback Error, %s %s', code, msg)
        SdkCrashlytics.RecordCrashlyticsLog(("FPXSDKModule:OnLoginCallback:FAILURE code:%s msg:%s"):format(code, msg))
        self.loginCallback(false)
    end

    self.loginProcessing = false
    self.loginCallback = nil
end

--- SDK注销的回调
---@param response string
function FPXSDKModule:OnLogoutCallback(response)
    g_Logger.Log('OnLogoutCallback %s', response)

    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        g_Game:RestartGame()
    else
        local msg = result['msg']
        g_Logger.Error('OnStartNewGameCallback Error, %s %s', code, msg)
    end
end

--- SDK新账号登录
--- 无回调，但是会触发SDK注销逻辑
function FPXSDKModule:StartNewGame()
    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.PLATFORM, FPXFunc.START_NEW_GAME, nil)
        g_Logger.Log('FPX.LoginStartNewGame')
    end
end

--- 创建角色
--- 无回调
function FPXSDKModule:CreateRole()
    if USE_FPXSDK and self:CheckSDKStatus()  then
        ---@type wds.Player
        local player = ModuleRefer.PlayerModule:GetPlayer()
        if not player then
            g_Logger.Error('CreateRole error, cannot get Player Entity')
            return
        end

        local addr, port, svrName, svrId = g_Game.ServiceManager:GetSavedConnectParam()
        local params =
        {
            [FPXKey.ROLE_ID] = playerId, -- 必传，游戏创建的角色ID（game_uid）
            [FPXKey.ROLE_NAME] = player.Basics.Name, -- 必传，角色名称
            [FPXKey.ROLE_LEVEL] = 1, -- 必传，角色等级，必须为整形数字
            [FPXKey.VIP_GRADE] = 1, -- 必传，角色vip，必须为数字，如VIP1，则传1
            [FPXKey.SERVER_ID] = svrId, -- 必传，服务器ID
            [FPXKey.SERVER_NAME] = svrName, -- 必传，服务器名称
            [FPXKey.CREATE_ROLE_TIME] = math.floor(player.Basics.KingdomJoinTime.Millisecond), -- 必传，角色创建时间（单位：ms）
        };
        FPX.Call(FPXModule.PLATFORM, FPXFunc.CREATE_ROLE, params)
        g_Logger.Log('FPX.CreateRole: %s', rapidJson.encode(params))
        SdkCrashlytics.RecordCrashlyticsLog("FPXSDKModule:CreateRole")
    end
end

--- 进入游戏.
--- 无回调
function FPXSDKModule:EnterGame()
    if USE_FPXSDK and self:CheckSDKStatus() then
        local player = ModuleRefer.PlayerModule:GetPlayer()
        local allianceId = ModuleRefer.AllianceModule:GetAllianceId()
        local addr, port, svrName, svrId = g_Game.ServiceManager:GetSavedConnectParam()
        local params =
        {
            [FPXKey.ROLE_ID] = player.ID, -- 必传，游戏创建的角色ID（game_uid）
            [FPXKey.ROLE_NAME] = player.Basics.Name, -- 必传，角色名称
            [FPXKey.ROLE_LEVEL] = player.Basics.Level, -- 必传，角色等级，必须为整形数字
            [FPXKey.VIP_GRADE] = 1, -- 必传，角色vip，必须为数字，如VIP1，则传1
            [FPXKey.SERVER_ID] = svrId, -- 必传，服务器ID
            [FPXKey.SERVER_NAME] = svrName, -- 必传，服务器名称
            [FPXKey.AID] = allianceId, -- 必传，联盟id
            [FPXKey.CREATE_ROLE_TIME] = math.floor(player.Basics.KingdomJoinTime.Millisecond), -- 必传，角色创建时间（单位：ms）
        };
        FPX.Call(FPXModule.PLATFORM, FPXFunc.ENTER_GAME, params)
        g_Logger.Log('FPX.EnterGame: %s', rapidJson.encode(params))
        SdkCrashlytics.RecordCrashlyticsLog("FPXSDKModule:EnterGame")
    end
end

--- SDK打点，设置打点参数
--- 无回调
--- "game_version" 游戏版本号
--- "area_id" 游戏场景id，当发生变化时传输
function FPXSDKModule:SetTrackingInfo(paramDict)
    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.SET_GAME_INFO, nil, rapidJson.encode(paramDict))
    end
end

--- SDK打点，覆盖打点参数
--- 无回调
function FPXSDKModule:OverrideDeviceLevel(device_level)
    if USE_FPXSDK and self:CheckSDKStatus() then
        local paramDict = {}
        paramDict['device_level'] = device_level
        FPX.Call(FPXModule.TRACKING, FPXFunc.OVERRIDE_PROPERTIES, nil, rapidJson.encode(paramDict))
        g_Logger.Log('FPX.OverrideDeviceLevel: module %s, func %s, params %s', FPXModule.TRACKING, FPXFunc.OVERRIDE_PROPERTIES, rapidJson.encode(paramDict))
    end
end

--- SDK打点，获取Track参数，同步给服务器使用
--- 无回调
function FPXSDKModule:SyncTrackingInfo()
    if USE_FPXSDK and self:CheckSDKStatus() then
        local syncInfo = FPX.CallString(FPXModule.TRACKING, FPXFunc.GET_TRACKING_INFO, nil)
        g_Logger.Log("SyncTrackInfo: %s", syncInfo)

        local SyncDeviceInfoParameter = require("SyncDeviceInfoParameter")
        local syncReq = SyncDeviceInfoParameter.new()
        syncReq.args.Info = syncInfo
        syncReq:Send()
    end
end

--- SDK打点，获取Track参数，同步给服务器使用
---@return string
function FPXSDKModule:GetTrackingInfo()
    if USE_FPXSDK and self:CheckSDKStatus() then
        local syncInfo = FPX.CallString(FPXModule.TRACKING, FPXFunc.GET_TRACKING_INFO, nil)
        g_Logger.Log("GetTrackingInfo: %s", syncInfo)

        return syncInfo
    end

    return string.Empty
end

--- SDK打点: 加载
--- 无回调
--- loading_id 步骤id, 需要提供配置, 见附录
--- loading_name 步骤名, 需要提供配置, 见附录
--- duration 步骤耗时，秒
---@param loading_id string
---@param loading_name string
---@param duration number
function FPXSDKModule:TrackLoading(loading_id, loading_name, duration)
    local paramDict = {}
    paramDict['event_name'] = 'loading'
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['loading_id'] = loading_id
    extraDict['loading_name'] = loading_name
    extraDict['duration'] = duration

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackLoading, %s', rapidJson.encode(paramDict))
end

--- SDK打点: 新手引导
--- 无回调
--- "tutorial_id":"xxx", //步骤id，需要提供配置，见附录
--- "tutorial_name":"xxx", //步骤名，需要提供配置，见附录
--- "duration":1, //步骤耗时，秒
---@param tutorial_id string
---@param tutorial_name string
---@param timestemp number
function FPXSDKModule:TrackTutorial(tutorial_id)
    local paramDict = {}
    paramDict['event_name'] = 'tutorial'
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['tutorial_id'] = tutorial_id
    extraDict['tutorial_name'] = tutorial_id
    -- extraDict['timestemp'] = timestemp

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackTutorial, %s', rapidJson.encode(paramDict))
end

--- SDK打点: 新手引导结束
--- 无回调
---@param tutorial_id string
---@param tutorial_name string
---@param timestemp number
function FPXSDKModule:TrackTutorialComplete(tutorial_id)
    local paramDict = {}
    paramDict['event_name'] = 'tutorial_complete'
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报

    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['tutorial_id'] = tutorial_id
    extraDict['tutorial_name'] = tutorial_id
    -- extraDict['timestemp'] = timestemp

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackTutorialComplete, %s', rapidJson.encode(paramDict))
end

--- SDK打点: UI弹窗打开
--- 无回调
---@param window_id string
function FPXSDKModule:TrackUIWindowOpen(window_id)
    local paramDict = {}
    paramDict['event_name'] = 'ui_window'
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['window_id'] = window_id
    extraDict['action_type'] = 'open'

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackUIWindowOpen, %s', rapidJson.encode(paramDict))
end

--- SDK打点: UI弹窗关闭
--- 无回调
---@param window_id string
function FPXSDKModule:TrackUIWindowClose(window_id)
    local paramDict = {}
    paramDict['event_name'] = 'ui_window'
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['window_id'] = window_id
    extraDict['action_type'] = 'close'

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackUIWindowClose, %s', rapidJson.encode(paramDict))
end

--- SDK打点: 点击按钮
--- 无回调
---@param window_id string
---@param button_id string
---@param action_result string
function FPXSDKModule:TrackUIButtonClick(window_id, component_id, button_id)
    local paramDict = {}
    paramDict['event_name'] = 'ui_button'
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['window_id'] = window_id
    extraDict['component_id'] = component_id
    extraDict['button_id'] = button_id

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackUIButtonClick, %s', rapidJson.encode(paramDict))
end

--- SDK打点: 通用业务打点
--- 无回调
---@param event_name string
---@param extraDict table
function FPXSDKModule:TrackCustomBILog(event_name, extraDict)
    local paramDict = {}
    paramDict['event_name'] = event_name
    paramDict['type'] = 1 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    paramDict['extra'] = extraDict

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackCustomBILog, %s', rapidJson.encode(paramDict))
end

--- SDK打点：支付成功
---@param event_name string
---@param productData ProductData
function FPXSDKModule:TrackPaymentSuccess(event_name, productData)
    local paramDict = {}
    paramDict['event_name'] = event_name
    paramDict['type'] = 2 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    paramDict['extra'] = productData

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    g_Logger.Log('TrackPaymentSuccess, %s', rapidJson.encode(paramDict))
end

--- SDK打点: 自定义打点, xperf
---@param dataDict table
--- 无回调
function FPXSDKModule:TrackXperf(dataDict)
    local paramDict = {}
    paramDict['event_tag'] = 'apm'  --xperf专用
    paramDict['data'] = dataDict

    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK_CUSTOM, nil, rapidJson.encode(paramDict))
    end
    
    g_Logger.Log('TrackXperf, %s', rapidJson.encode(paramDict))
end

--- SDK打点: rum打点
---@param service_name string
---@param url string
---@param http_status number
---@param request_ts number
---@param duration number
--- 无回调
function FPXSDKModule:TrackRum(service_name, url, http_status, request_ts, duration)
    local paramDict = {}
    paramDict['event_name'] = 'rum'  --rum
    paramDict['type'] = 3 -- 0：为BI+AD通道，1：为只报BI通道，2：为只报AD通道，3：为RUM数据上报
    local extraDict = {}
    paramDict['extra'] = extraDict

    extraDict['service_name'] = service_name
    extraDict['protocol'] = 'http'
    extraDict['http_url'] = url
    extraDict['http_status'] = http_status
    extraDict['http_latency'] = duration
    extraDict['request_ts'] = request_ts
    extraDict['response_ts'] = request_ts + duration
    extraDict['request_size'] = 0
    extraDict['response_size'] = 0

    if USE_FPXSDK and self:CheckSDKStatus() then
        g_Logger.Log('call TrackRum %s', rapidJson.encode(paramDict))
        FPX.Call(FPXModule.TRACKING, FPXFunc.TRACK, nil, rapidJson.encode(paramDict))
    end
    
    g_Logger.Log('TrackRum, %s', rapidJson.encode(paramDict))
end

--- SDK推送服务
--- 有回调: OnInitPushModuleCallback
function FPXSDKModule:InitPushModule()
    if USE_FPXSDK and self:CheckSDKStatus() then
        if not self.initPushProcessing then
            self.initPushProcessing = true
            FPX.Call(FPXModule.PUSH, FPXFunc.REGISTER_DEVICE_TOKEN, nil)
        else
            g_Logger.Error('FPX.InitPushModule is processing, ignoring this invoke')
        end
    end
end

--- SDK推送回调
---@param response any
function FPXSDKModule:OnInitPushModuleCallback(response)
    g_Logger.Log('OnInitPushModuleCallback %s', response)

    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        local data = result['data']
        local pushToken = data['pushToken']

        local SyncPushDeviceTokenParameter = require('SyncPushDeviceTokenParameter')
        local req = SyncPushDeviceTokenParameter.new()
        req.args.Account = ModuleRefer.PlayerModule:GetAccountId()
        req.args.DeviceToken = pushToken
        req.args.BundleId = FPX.CallString(FPXModule.TOOLS, 'getPackageName', nil)
        req:Send()

        g_Logger.Log('SyncPushDeviceToken %s', pushToken)
    else
        local msg = result['msg']
        g_Logger.Error('OnInitPushModuleCallback Error, %s %s', code, msg)
    end

    self.initPushProcessing = false
end

--- SDK设置本地推送
--- 无回调
---@param id number
---@param title string
---@param subtitle string
---@param content string
---@param delay number
---@param userData string
function FPXSDKModule:SetLocalNotification(id, title, subtitle, content, delay, userData, isLoop, loopSeconds)
    if USE_FPXSDK and self:CheckSDKStatus() then
        if delay then
            delay = math.floor(delay)
        end
        
        if loopSeconds then
            loopSeconds = math.floor(loopSeconds)
        end

        local param = {}
        param[FPXKey.NOTIFICATION_ID] = id --必传，此条推送的 ID（int类型）
        param[FPXKey.NOTIFICATION_TITLE] = title -- 必传，标题
        param[FPXKey.NOTIFICATION_SUB_TITLE] = subtitle-- 非必传，副标题 (iOS 10 以上系统)
        param[FPXKey.NOTIFICATION_MESSAGE] = content -- 必传，显示内容
        param[FPXKey.NOTIFICATION_DATA] = userData -- 必传（JSONObject），透传内容, 当玩家点击通知栏的通知后，SDK会将此信息返回给游戏
        param[FPXKey.NOTIFICATION_DELAY_SECOND] = delay-- 必传，推送延迟 (单位: 秒, 非循环推送会使用此参数)
        param[FPXKey.NOTIFICATION_IS_REPEAT] = isLoop and 1 or 0 -- 非必传，是否循环推送  0-不开启 1-开启
        param[FPXKey.NOTIFICATION_INTERVAL_SECOND] = loopSeconds or TimeFormatter.OneDaySeconds -- 非必传，循环推送间隔 (单位: 秒, iOS 10 以下会就近匹配为分, 时, 日, 周, 月, 年)

        FPX.Call(FPXModule.PUSH, FPXFunc.SEND_LOCAL_NOTIFICATION, param)
        g_Logger.Log('SetLocalNotification %s %s %s %s %s', id, title, subtitle, content, delay)
    end
end

--- SDK取消本地推送
--- 无回调
---@param id number
function FPXSDKModule:CancelLocalNotification(id)
    if USE_FPXSDK and self:CheckSDKStatus() then
        local param = {}
        param[FPXKey.NOTIFICATION_ID] = id --必传，此条推送的 ID（int类型）

        FPX.Call(FPXModule.PUSH, FPXFunc.CANCEL_LOCAL_NOTIFICATION, param)
    end
end

--- 设置本地推送
function FPXSDKModule:SetLocalNotifications()
    if USE_FPXSDK and self:CheckSDKStatus() then
        if not self.hasAccountLoggin then
            return
        end

        --- 所有建筑的设置
        local myCity = ModuleRefer.CityModule.myCity
        if myCity then
            if myCity.furnitureManager and myCity.furnitureManager:IsDataReady() then
                myCity.furnitureManager:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
            end
        end

        ModuleRefer.PetModule:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))

        -- if myCity and myCity.buildingManager then
        --     myCity.buildingManager:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
        -- end
        -- --- 资源生产
        -- if myCity then
        --     if myCity.cityWorkManager then
        --         myCity.cityWorkManager:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
        --     end
        -- end
        --- 科研
        -- ModuleRefer.ScienceModule:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
        --- 造兵
        -- ModuleRefer.TrainingSoldierModule:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
        --日常任务
        ModuleRefer.QuestModule:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
        --- ...
        -- 联盟/巨兽
        ModuleRefer.AllianceModule:OnSetLocalNotification(Delegate.GetOrCreate(self, self.SetLocalNotification))
    end
end

--- SDK取消所有本地推送
--- 无回调
function FPXSDKModule:ClearAllNotification()
    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.PUSH, FPXFunc.CLEAR_ALL_NOTIFICATION, nil)
    end
end

--- SDK查询是否开启推送设置
--- 有回调: OnQueryNotificationCallback
function FPXSDKModule:QueryNotificationEnable(callback)
    if USE_FPXSDK and self:CheckSDKStatus() then
        if not self.queryProcessing then
            self.queryProcessing = true
            self.queryCallback = callback
            FPX.Call(FPXModule.PLATFORM, FPXFunc.IS_NOTIFICATION_ENABLED, nil)
            g_Logger.Log('FPX.QueryNotificationEnable')
        else
            g_Logger.Error('FPX.QueryNotificationEnable is processing, ignoring this invoke')
        end
    end
end

--- SDK查询是否开启推送回调
---@param response any
function FPXSDKModule:OnQueryNotificationEnableCallback(response)
    g_Logger.Log('OnQueryNotificationEnableCallback %s', response)

    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        local data = result['data']
        local isEnable = data['isEnable'] -- 0关闭，1开启
        self.queryCallback(true, isEnable)
    else
        local msg = result['msg']
        g_Logger.Error('OnQueryNotificationEnableCallback Error, %s %s', code, msg)
        self.queryCallback(false)
    end

    self.queryProcessing = false
    self.queryCallback = nil
end

--- SDK前往系统推送设置页面
--- 无回调
function FPXSDKModule:OpenNotificationSetting()
    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.PLATFORM, FPXFunc.OPEN_NOTIFICATION_SETTING, nil)
    end
end

--- SDK支付: 获取商品信息
--- 有回调
function FPXSDKModule:GetProductsInfo(callback)
    if USE_FPXSDK and self:CheckSDKStatus() then
        if not self.getProductsInfoProcessing then
            self.getProductsInfoProcessing = true
            self.getProductsInfoCallback = callback
            FPX.Call(FPXModule.PLATFORM, FPXFunc.GET_PRODUCTS_INFO, nil)
            g_Logger.Log('FPX.GetProductsInfo')
        else
            g_Logger.Error('FPX.GetProductsInfo is processing, ignoring this invoke')
        end
    end
end

--- 获取商品信息回调
---@param response any
function FPXSDKModule:OnGetProductsInfoCallback(response)
    g_Logger.Log('OnGetProductsInfoCallback %s', response)

    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        local data = result['data']
        local productList = data['products']
        self.getProductsInfoCallback(true, productList)
    else
        local msg = result['msg']
        g_Logger.Error('OnGetProductsInfoCallback Error, %s %s', code, msg)
        self.getProductsInfoCallback(false)
    end

    self.getProductsInfoProcessing = false
    self.getProductsInfoCallback = nil
end

--- SDK支付: 发起支付
function FPXSDKModule:Pay(paymentInfo, callback)
    if USE_FPXSDK and self:CheckSDKStatus() then
        if not self.payProcessing then
            self.payProcessing = true
            self.payCallback = callback
            FPX.Call(FPXModule.PLATFORM, FPXFunc.PAY, paymentInfo)
            g_Logger.Log('FPX.Pay: %s', rapidJson.encode(paymentInfo))
        else
            g_Logger.Error('FPX.Pay is processing, ignoring this invoke')
        end
    end
end

--- 支付回调
---@param response any
function FPXSDKModule:OnPayCallback(response)
    g_Logger.Log('OnPayCallback %s', response)

    local result = rapidJson.decode(response)
    local code = result['code']
    if code == FPXCode.SUCCESS then
        if self.payCallback then
            self.payCallback(true)
        end
    else
        local msg = result['msg']
        g_Logger.Error('OnPayCallback Error, %s %s', code, msg)
        if self.payCallback then
            self.payCallback(false)
        end
    end

    self.payProcessing = false
    self.payCallback = nil
end

--- SDK, 判断是否有用户中心
--- 无回调
function FPXSDKModule:HasUserCenter()
    if USE_FPXSDK and self:CheckSDKStatus() then
        return FPX.CallBool(FPXModule.PLATFORM, FPXFunc.HAS_USER_CENTER, nil)
    end

    return false
end

--- SDK打开用户中心
--- 无回调
function FPXSDKModule:OpenUserCenter()
    if USE_FPXSDK and self:CheckSDKStatus() then
        FPX.Call(FPXModule.PLATFORM, FPXFunc.OPEN_USER_CENTER, nil)
    end
end

---@class FPXNetworkProbeData
---@field ip string 域名最好不要带http://,https:// 头
---@field port number 端口号

-- 添加网络探针地址
---@param param FPXNetworkProbeData[]
function FPXSDKModule:NetProbeAddIPAddrs(param)
    if USE_FPXSDK and self:CheckSDKStatus() then
        local netProbeAddIPAddrsConfig = {}
        netProbeAddIPAddrsConfig['data'] = rapidJson.encode(param)
        g_Logger.Log('call netProbeAddIPAddrs %s', rapidJson.encode(netProbeAddIPAddrsConfig))
        FPX.Call(FPXModule.TRACKING, "netProbeAddIPAddrs", netProbeAddIPAddrsConfig)
    end
end

-- 开启网络探针
function FPXSDKModule:NetProbeStart(interval)
    if USE_FPXSDK and self:CheckSDKStatus() then
        local netProbeStartConfig = {}
        -- interval 代表网路探针的间隔时间，为可选参数，如果不设置默认为60s，间隔时间必须大于60s
        netProbeStartConfig['interval'] = interval or 60
        g_Logger.Log('call netProbeStart %s', rapidJson.encode(netProbeStartConfig))
        FPX.Call(FPXModule.TRACKING, "netProbeStart", netProbeStartConfig)
    end
end

-- 清除网络探针
function FPXSDKModule:NetProbeClear()
    if USE_FPXSDK and self:CheckSDKStatus() then
        g_Logger.Log('call netProbeClear')
        FPX.Call(FPXModule.TRACKING, "netProbeClear", nil)
    end
end

function FPXSDKModule:ChooseUploadCustomHeadIcon(type)
    g_Logger.Error('=====ChooseUploadCustomHeadIcon=====:%s====USE_FPXSDK:%s====sdkStatus：%s', type, tostring(USE_FPXSDK), tostring(self:CheckSDKStatus()))
    if USE_FPXSDK and self:CheckSDKStatus() then
        g_Logger.Log('call uploadCheckPic')
        type = type or 0
        local param = {}
        param["type"] = tostring(type)
        param["width"] = tostring(FPX_SDK_UPLOAD_IMAGE_WIDTH)
        param["height"] = tostring(FPX_SDK_UPLOAD_IMAGE_HEIGHT)
        param["role_id"] = ModuleRefer.PlayerModule:GetPlayerId()
        local payload = {}
        payload["upload_avatar_cnt"] = ModuleRefer.PlayerModule:GetPlayerUploadAvatarCount() + 1
        param["payload"] = rapidJson.encode(payload)
        local ret = FPX.CallString(FPXModule.TOOLS, "uploadCheckPic", nil, rapidJson.encode(param))
        g_Logger.Log('call uploadCheckPic ret:%s', ret)
    end
end

--- SDK查询是否开启推送回调
---@param response any
function FPXSDKModule:OnUploadCustomHeadIconCallback(response)
    g_Logger.Log('OnUploadCustomHeadIconCallback %s', response)
    local result = rapidJson.decode(response)
    local code = result["code"]     -- 1:上传成功 -1:上传失败 -2:取消操作
    if code == FPXCode.SUCCESS then
        ModuleRefer.PlayerModule:UploadCustomAvatar(nil, nil, function(cmd, isSuccess, rsp)
            if not isSuccess then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_avatar_upload_cd_toast"))
            end
            local UIMediatorNames = require("UIMediatorNames")
            local portraitSelectMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIPlayerPortraitSelectMediator)
            if portraitSelectMediator then
                portraitSelectMediator:RefreshUI()
            end
	    end)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_avatar_upload_success_desc"))
    else
        local msg = result['msg']
        if not string.IsNullOrEmpty(msg) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("skincollection_avatar_upload_fail_desc"))
        end
        g_Logger.Error('OnUploadCustomHeadIconCallback Error, %s %s', code, msg)
    end
end

--- SDK 打开公告面板
---@param channelId string  必传 1:登录前公告 2:进入游戏后公告
---@param forceopen boolean 非必传 0:默认非强制 1:强制打开公告
function FPXSDKModule:OpenNotice(channelId, forceopen)
	if USE_FPXSDK and self:CheckSDKStatus() then
		local paramDict = {}
		paramDict['channel_id'] = channelId
		paramDict['is_forrce_open'] = forceopen 
		
		FPX.Call(FPXModule.NOTICE, FPXFunc.OPEN_NOTICE, paramDict)
	end
end

--- SDK 关闭公告面板
function FPXSDKModule:CloseNotice()
	if USE_FPXSDK and self:CheckSDKStatus() then
		FPX.Call(FPXModule.NOTICE, FPXFunc.CLOSE_NOTICE, nil)
	end
end

return FPXSDKModule
