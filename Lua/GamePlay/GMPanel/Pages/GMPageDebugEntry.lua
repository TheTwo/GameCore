local GUILayout = require("GUILayout")
local UIMediatorNames = require("UIMediatorNames")
local Vector2 = CS.UnityEngine.Vector2
local ModuleRefer = require("ModuleRefer")

local GMPage = require("GMPage")

---@class GMPageDebugEntry:GMPage
---@field new fun():GMPageDebugEntry
---@field super GMPage
local GMPageDebugEntry = class('GMPageDebugEntry', GMPage)

function GMPageDebugEntry:Init(panel)
    self.super.Init(self, panel)
    self._scrollPosition = Vector2.zero
    self._streamUrl = string.Empty
    self._allowSkip = false
    self._imgUrl = "https://pic.616pic.com/ys_bnew_img/00/13/44/S1u5Y2obmQ.jpg"
    self._loadTypeStr = '2'
end

function GMPageDebugEntry:OnGUI()
    self._scrollPosition = GUILayout.BeginScrollView(self._scrollPosition)
    if GUILayout.Button("Troop Skill ECS Scene") then
        g_Game.GamePause = true
        g_Game:ShutDown()
        CS.UnityEngine.SceneManagement.SceneManager.LoadScene("scene_test_troop_skill")
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("Url", GUILayout.shrinkWidth)
    self._streamUrl = GUILayout.TextField(self._streamUrl, GUILayout.expandWidth)
    GUILayout.EndHorizontal()
    self._allowSkip = GUILayout.Toggle(self._allowSkip, "allowClose")
    if GUILayout.Button("stream media") then
        ModuleRefer.StreamingVideoModule:Play(self._streamUrl, self._allowSkip, function(handle)
            g_Logger.Log("%s play end", self._streamUrl)
        end)
    end
    if GUILayout.Button("UIBattleSignalPopupMediator") then
        g_Game.UIManager:Open(UIMediatorNames.UIBattleSignalPopupMediator)
    end
    if GUILayout.Button("AllianceMarkMainMediator") then
        g_Game.UIManager:Open(UIMediatorNames.AllianceMarkMainMediator)
    end
    if GUILayout.Button("新手任务") then
        g_Game.UIManager:Open(UIMediatorNames.NoviceTaskMediator)
    end
    if GUILayout.Button("签到拍脸") then
        g_Game.UIManager:Open(UIMediatorNames.UISignInMediator)
    end
    if GUILayout.Button("地球重生新闻拍脸") then
        g_Game.UIManager:Open(UIMediatorNames.EarthRevivalPopupMediator)
    end
    if GUILayout.Button("七日拍脸") then
        g_Game.UIManager:Open(UIMediatorNames.NoviceTaskPopupMediator)
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("英雄id", GUILayout.shrinkWidth)
    self._heroId = GUILayout.TextField(self._heroId, GUILayout.expandWidth)
    if GUILayout.Button("英雄获得拍脸") then
        g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = tonumber(self._heroId) or 101})
        self.panel:PanelShow(false)
    end
    GUILayout.EndHorizontal()
    if GUILayout.Button("tips富文本小图标测试") then
        ModuleRefer.ToastModule:AddSimpleToast("[006][006]测[071]试[071]富[071]文[071]本[071]小[071]图[071]标[039][039]")
    end
    if GUILayout.Button("联盟推荐toast显示测试") then
        ---@type wrpc.AllianceBriefInfo
        local fakeBriefData = {}
        fakeBriefData.ID = 1
        fakeBriefData.Name = "fake alliance"
        fakeBriefData.JoinSetting = 1
        fakeBriefData.Language = 1
        fakeBriefData.MemberCount = 1
        fakeBriefData.MemberMax = 1
        fakeBriefData.Power = 1
        fakeBriefData.Abbr = "FAKE"
        ---@type wrpc.AllianceFlag
        local fakeFlag = {}
        fakeFlag.BadgeAppearance = 1
        fakeFlag.BadgePattern = 1
        fakeBriefData.Flag = fakeFlag
        ModuleRefer.AllianceModule._cachedAllianceRecruitTopInfos = { fakeBriefData }
        local EventConst = require("EventConst")
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_FIND_NEXT_RECRUIT_TOP_INFO, 1)
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("ImageUrl", GUILayout.shrinkWidth)
    self._imgUrl = GUILayout.TextField(self._imgUrl, GUILayout.expandWidth)
    if GUILayout.Button("模拟上传头像") then
        ModuleRefer.PlayerModule:UploadCustomAvatar(nil, self._imgUrl)
    end
    GUILayout.EndHorizontal()

    GUILayout.Label("测试Loading", GUILayout.shrinkWidth)
    if GUILayout.Button("测试登录下载资源界面") then
        self:TestGameLaunchUI()
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("测试Loading界面类型（0所有界面,1资源加载界面,2通用加载,3PvP加载）", GUILayout.shrinkWidth)
    self._loadTypeStr = GUILayout.TextField(self._loadTypeStr, GUILayout.shrinkWidth)
    GUILayout.EndHorizontal()
    if GUILayout.Button("测试Loading界面") then
        self:TestLoadingUI()
    end
    if GUILayout.Button("关闭Loading窗口") then
        self:CloseAllLoadingUI()
    end
    if GUILayout.Button("道具获得动效测试") then
        local dummyData = wrpc.PushRewardRequest.New(nil, wds.enum.ItemProfitType.ItemAddByOpenBox, require("ItemPopType").PopTypeLightReward, nil)
        dummyData.ItemID:Add(2)
        dummyData.ItemID:Add(6)
        dummyData.ItemID:Add(61001)
        dummyData.ItemCount:Add(100)
        dummyData.ItemCount:Add(10)
        dummyData.ItemCount:Add(1000)
        ModuleRefer.RewardModule:ShowLightReward(dummyData)
        self.panel:PanelShow(false)
    end

    GUILayout.EndScrollView()
end

function GMPageDebugEntry:TestGameLaunchUI()
    g_Game.UIManager:Open("UIGameLaunchMediator")
    require('TimerUtility').DelayExecute(function()
        g_Game.EventManager:TriggerEvent(require('EventConst').LANGUAGE_AND_CONFIGS_READY)
    end, 0.3)
end
function GMPageDebugEntry:TestLoadingUI()
    local loadingType = tonumber(self._loadTypeStr)
    loadingType = loadingType or 0
    g_Game.UIManager:Open("LoadingPageMediator",{loadingType = loadingType})
end

function GMPageDebugEntry:CloseAllLoadingUI()
    g_Game.UIManager:CloseByName("UIGameLaunchMediator")
    g_Game.UIManager:CloseByName("LoadingPageMediator")
end

return GMPageDebugEntry