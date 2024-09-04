local GMPage = require("GMPage")
local GUILayout = require("GUILayout")
local Delegate = require("Delegate")

---@class GMPageProfiler:GMPage
local GMPageProfiler = class('GMPageProfiler', GMPage)
local debug = debug;
local os = os;
local table = table;

local Blacklist = {
    "GUI",
    "Gui",
    "GM",
}

function GMPageProfiler:ctor()
    self.enableHook = false;
    self.pause = false;
    self.singleFrameRecord = {}
    self.curFrame = {}
    self.historyFrames = {}
    self.capacity = 256;
    self.funcTimeStack = {}
    self.lastFrame = -1;
    self.selectionScrollPos = CS.UnityEngine.Vector2();
    self.guiStyle = self:CustomFont();
end

function GMPageProfiler:CustomFont()
    local myStyle = CS.UnityEngine.GUIStyle();
    myStyle.fontSize = 11;
    return myStyle;
end

function GMPageProfiler:OnGUI()
    GUILayout.BeginHorizontal()
    GUILayout.Label("Profiling:")
    if not self.enableHook and GUILayout.Button("Sample") then
        self:Hook();
    end
    if self.enableHook and not self.pause and GUILayout.Button("Pause") then
        self:PauseAndSample()
    end
    if self.enableHook and self.pause and GUILayout.Button("Continue") then
        self:ContinueSample();
    end
    if self.enableHook and GUILayout.Button("Stop") then
        self:ReleaseHook();
        self.singleFrameRecord = {}
        self.historyFrames = {}
        self.funcTimeStack = {}
    end
    GUILayout.EndHorizontal();

    GUILayout.BeginHorizontal();
    GUILayout.Label("Snapshot:")
    
    GUILayout.EndHorizontal()
    if self.lastFrame ~= g_Game.Time.frameCount then
        self:SliceRecord();
        self.lastFrame = g_Game.Time.frameCount;
    end

    if self.enableHook and not self.pause then
        self:DrawAverageCostOfFrame();
    elseif self.enableHook and self.pause then
        self:DrawSingleFrame();
    end
end

function GMPageProfiler:Hook()
    if self.enableHook then
        return
    end
    local hook = debug.gethook()
    if hook then
        g_Logger.Error("debug hook 已经被占用")
        return
    end
    debug.sethook(Delegate.GetOrCreate(self, self.HookFuncInvoke), "cr");
    self.enableHook = true;
end

function GMPageProfiler:ReleaseHook()
    if not self.enableHook then
        return
    end
    debug.sethook();
    self.enableHook = false;
end

function GMPageProfiler:HookFuncInvoke(evt)
    local info = debug.getinfo(2);
    for k, v in pairs(Blacklist) do
        if info.short_src:match(v) then
            return;
        end

        if info.name ~= nil and info.name:match(v) then
            return;
        end
    end

    if evt == "call" then
        if info.short_src ~= "[C]" and info.name ~= nil and info.name ~= "__index" and info.name ~= "__newindex" then
            local src = info.short_src:match("ssr%-logic/Lua/.*")
            local func = info.func;
            if src ~= nil then
                if src:match("Delegate") and info.linedefined == 73 then
                    local name, f = debug.getupvalue(info.func, 1);
                    func = f;
                end
                if not self.funcTimeStack[func] then
                    self.funcTimeStack[func] = {}
                end
                table.insert(self.funcTimeStack[func], os.clock());
            end
        end
    elseif evt == "return" then
        if info.short_src ~= "[C]" and info.name ~= nil and info.name ~= "__index" and info.name ~= "__newindex" then
            local src = info.short_src:match("ssr%-logic/Lua/.*")
            if src ~= nil then
                if src:match("Delegate") and info.linedefined == 73 then
                    local name, func = debug.getupvalue(info.func, 1);
                    if self.funcTimeStack[func] then
                        if #self.funcTimeStack[func] == 1 then
                            self:Save(func, os.clock() - self.funcTimeStack[func][1]);
                        end
                        table.remove(self.funcTimeStack[func]);
                    end
                else
                    local func = info.func;
                    if self.funcTimeStack[func] then
                        if #self.funcTimeStack[func] == 1 then
                            self:Save(func, os.clock() - self.funcTimeStack[func][1], info.name);
                        end
                        table.remove(self.funcTimeStack[func]);
                    end
                end
            end
        end
    end
end

function GMPageProfiler:PauseAndSample()
    self.pause = true;
end

function GMPageProfiler:ContinueSample()
    self.pause = false;
end

function GMPageProfiler:DrawAverageCostOfFrame()
    self.curFrame = self.historyFrames[#self.historyFrames];
    if self.curFrame == nil then
        return;
    end

    self:DrawFrame(self.curFrame);
end

function GMPageProfiler:DrawSingleFrame()
    if self.curFrame == nil then
        return;
    end

    self:DrawFrame(self.curFrame);
end

function GMPageProfiler:DrawFrame(frame)
    self.selectionScrollPos = GUILayout.BeginScrollViewWithVerticalBar(self.selectionScrollPos, GUILayout.shrinkWidth)
    GUILayout.BeginHorizontal();
    GUILayout.BeginVertical();

    GUILayout.BeginHorizontal();
    GUILayout.Label("Function Name", self.guiStyle, GUILayout.shrinkWidth);
    GUILayout.FlexibleSpace();
    GUILayout.Label("Cost Time", self.guiStyle, GUILayout.shrinkWidth);
    GUILayout.EndHorizontal();

    for _, v in ipairs(frame) do
        GUILayout.BeginHorizontal();
        GUILayout.Label(v.name, self.guiStyle, GUILayout.shrinkWidth);
        GUILayout.FlexibleSpace();
        GUILayout.Label(("%.4f"):format(v.time), self.guiStyle, GUILayout.shrinkWidth);
        GUILayout.EndHorizontal();
    end

    GUILayout.EndVertical();
    GUILayout.EndHorizontal();
    GUILayout.EndScrollView();
end

function GMPageProfiler:SliceFromSingleFrame()
    local array = {}
    for k, v in pairs(self.singleFrameRecord) do
        table.insert(array, {name = k, time = v});
    end
    table.sort(array, function(a, b) return a.time > b.time end)
    self.singleFrameRecord = {}
    return array;
end

function GMPageProfiler:SliceRecord()
    local array = self:SliceFromSingleFrame();
    if #self.historyFrames == self.capacity then
        table.remove(self.historyFrames, 1);
    end

    table.insert(self.historyFrames, array);
end

function GMPageProfiler:Save(func, costTime, name)
    local funcName = self:GetName(func, name);
    if not self.singleFrameRecord[funcName] then
        self.singleFrameRecord[funcName] = costTime;
    else
        self.singleFrameRecord[funcName] = self.singleFrameRecord[funcName] + costTime;
    end
end

function GMPageProfiler:GetName(func, name)
    local info = debug.getinfo(func);
    local src = info.short_src:match("ssr%-logic/Lua/.*")
    if name == nil then
        return ("%s at line:%d"):format(src, info.linedefined)
    else
        return ("%s.%s at line:%d"):format(src:gsub("%.lua", ""), name, info.linedefined)
    end
end

function GMPageProfiler:Release()
    self:ReleaseHook();
    self.pause = false;
end

return GMPageProfiler