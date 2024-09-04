local GUILayout = require("GUILayout")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local GMPage = require("GMPage")
local GuideConditionProcesser = require('GuideConditionProcesser')
local GuideUtils = require('GuideUtils')
local QueuedTask = require('QueuedTask')

---@class GMPageGuide:GMPage
local GMPageGuide = class('GMPageGuide', GMPage)

function GMPageGuide:OnShow()
    self.testId = g_Game.PlayerPrefsEx:GetString('GMPageGuide::testId','101')
    self.conditionCmd = ''
    self.conditionResult = ''
    self._scrollPosL = CS.UnityEngine.Vector2.zero
    self._scrollPosR = CS.UnityEngine.Vector2.zero
    self._mainScrollPos = CS.UnityEngine.Vector2.zero
    self.showConditionTestTool = false
    self._customDataKey = ""
end

function GMPageGuide:OnGUI()
    self._mainScrollPos = GUILayout.BeginScrollView(self._mainScrollPos)

    local skipNewbie = GUILayout.Toggle(self:GetSkipNewbie(), "是否跳过新手引导")
    if skipNewbie ~= self:GetSkipNewbie() then
        self:SetSkipNewbie(skipNewbie)
    end

    local debugMode = GUILayout.Toggle(ModuleRefer.GuideModule.debugMode,'Debug模式')
    local blockState = GUILayout.Toggle(ModuleRefer.GuideModule.blockGuide >= 1,'屏蔽引导')
    local blockAll = GUILayout.Toggle(ModuleRefer.GuideModule.blockGuide >= 2,'直接进入主城(城内流程会卡住,需要手动添加工人)')

    if debugMode ~= ModuleRefer.GuideModule.debugMode then
        ModuleRefer.GuideModule.debugMode = debugMode
        g_Game.PlayerPrefsEx:SetInt(require('GuideModule').PlayerPrefsKeys_Debug,debugMode and 1 or 0)
    end

    if blockState and ModuleRefer.GuideModule.blockGuide < 1 then
        ModuleRefer.GuideModule.blockGuide = 1
        g_Game.PlayerPrefsEx:SetInt(require('GuideModule').PlayerPrefsKeys,1)
    elseif not blockState and ModuleRefer.GuideModule.blockGuide > 0 then
        ModuleRefer.GuideModule.blockGuide = 0
        g_Game.PlayerPrefsEx:SetInt(require('GuideModule').PlayerPrefsKeys,0)
        blockAll = false
    end

    if blockAll and ModuleRefer.GuideModule.blockGuide < 2 then
        ModuleRefer.GuideModule.blockGuide = 2
        g_Game.PlayerPrefsEx:SetInt(require('GuideModule').PlayerPrefsKeys,2)
    elseif not blockAll and ModuleRefer.GuideModule.blockGuide > 1 then
        ModuleRefer.GuideModule.blockGuide = 1
        g_Game.PlayerPrefsEx:SetInt(require('GuideModule').PlayerPrefsKeys,1)
    end

    GUILayout.Label("Test ID:", GUILayout.shrinkWidth)
    self.testId = GUILayout.TextField(self.testId)

    if GUILayout.Button('Test Guide Call') then
        local callId = self.testId and tonumber(self.testId) or 0
        if callId > 0 then
            g_Game.PlayerPrefsEx:SetString('GMPageGuide::testId',self.testId)
            GuideUtils.GotoByGuide(callId)
        end
    end

    if GUILayout.Button('Test Guide Group') then
        local guideCfg = ConfigRefer.GuideGroup:Find(tonumber(self.testId))
        g_Game.PlayerPrefsEx:SetString('GMPageGuide::testId',self.testId)
        if guideCfg then
            ModuleRefer.GuideModule:ExeGuideGroup(guideCfg)
        end
    end

    if GUILayout.Button('Test Guide Step') then
        local stepCfg = ConfigRefer.Guide:Find(tonumber(self.testId))
        g_Game.PlayerPrefsEx:SetString('GMPageGuide::testId',self.testId)
        if stepCfg then
            ModuleRefer.GuideModule:ExecuteGuideStepDirectly(tonumber(self.testId))
        end
    end

    -- if GUILayout.Button('Test Goto') then
    --     g_Game.PlayerPrefsEx:SetString('GMPageGuide::testId',self.testId)
    --     if not string.IsNullOrEmpty(string.match(self.testId,',')) then
    --         local idStrs = string.split(self.testId,',')
    --         for i = 1, #idStrs do
    --             -- body
    --             require('Utilities.Timer.TimerUtility').DelayExecuteInFrame(
    --                 function()
    --                     require('GotoUtils').GotoByGuide(tonumber(idStrs[i]),true)
    --                 end,
    --                 i + i*2
    --             )
    --         end
    --     else
    --         local guideCfg = ConfigRefer.GuideGroup:Find(tonumber(self.testId))
    --         ModuleRefer.GuideModule:ExeGuideGroup(guideCfg)
    --     end
    -- end

    -- if GUILayout.Button('Test Save') then
    --     ModuleRefer.GuideModule:SaveFinishedGroup(tonumber(self.testId))
    -- end

    -- if GUILayout.Button('Test Load') then
    --     ModuleRefer.GuideModule:ReadFinishedGroup()
    -- end

    local buttonText = self.showConditionTestTool and 'Hide Condition Test Tool' or 'Show Condition Test Tool'

    if GUILayout.Button(buttonText) then
        self.showConditionTestTool = not self.showConditionTestTool
    end

    if self.showConditionTestTool then
        self:TriggerConditionTest()
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("Clear Custome Data:", GUILayout.shrinkWidth)
    self._customDataKey = GUILayout.TextField(self._customDataKey)
    GUILayout.EndHorizontal()
    if GUILayout.Button("Clear") then
        ModuleRefer.ClientDataModule:RemoveData(self._customDataKey)
    end


    GUILayout.EndScrollView()

end

function GMPageGuide:TriggerConditionTest()
    GUILayout.Label('触发条件测试')
    GUILayout.BeginHorizontal()

    GUILayout.BeginVertical(GUILayout.Width(180))
    GUILayout.Label('现在支持的逻辑运算')
    self._scrollPosL = GUILayout.BeginScrollView(self._scrollPosL,GUILayout.Height(100))
    GUILayout.TextField('{ConditionAnd,{},{}}')
    GUILayout.TextField('{ConditionOr,{},{}}')
    GUILayout.TextField('{ConditionNot,{}}')
    GUILayout.EndScrollView()
    GUILayout.EndVertical()

    GUILayout.BeginVertical()
    GUILayout.Label('现在支持的查询条件')
    self._scrollPosR = GUILayout.BeginScrollView(self._scrollPosR,GUILayout.Height(100))
    if not self.allCmdsKeys then
        self.allCmdsKeys = table.keys(GuideConditionProcesser.Commands)
        table.sort(self.allCmdsKeys)
    end
    for index, key in ipairs(self.allCmdsKeys) do
        if not string.IsNullOrEmpty(key)
            and not string.StartWith(key,'Condition')
            and GuideConditionProcesser.Commands[key]
        then
            GUILayout.TextField(GuideConditionProcesser.Commands[key].desc)
        end
    end
    GUILayout.EndScrollView()
    GUILayout.EndVertical()

    GUILayout.EndHorizontal()
    GUILayout.Label('条件语句')
    self.conditionCmd = GUILayout.TextField(self.conditionCmd)
    if GUILayout.Button('执行条件语句') then
        local res = ModuleRefer.GuideModule:ExeConditionCmd(self.conditionCmd)
        self.conditionResult = tostring(res)

    end
    GUILayout.Label('执行结果')
    self.conditionResult = GUILayout.TextField(self.conditionResult)
    -- GUILayout.TextField(tostring(self.conditionRes1))
    -- GUILayout.TextField(tostring(self.conditionRes2))
    -- GUILayout.TextField(tostring(self.conditionRes3))
    -- GUILayout.TextField(tostring(self.conditionRes4))
     local conditionProcesser = require('GuideConditionProcesser').new()
     if GUILayout.Button('测试GuideGroup中全部条件语句') then
        for key, value in ConfigRefer.GuideGroup:ipairs() do
            local cmd = value:TriggerCmd()
            if not string.IsNullOrEmpty(cmd) then
                local res = conditionProcesser:ExeConditionCmd(cmd)
                g_Logger.LogChannel('Guide Condition','Cmd:[%s] -- Res:[%s]',cmd,tostring(res))
            end
        end
     end
end

function GMPageGuide:GetSkipNewbie()
    return g_Game.PlayerPrefsEx:GetInt("GMSkipNewbie") == 1
end

function GMPageGuide:SetSkipNewbie(value)
    g_Game.PlayerPrefsEx:SetInt("GMSkipNewbie", value and 1 or 0)
end

return GMPageGuide