-- 给C#的ObjectTranslator.OutputDelegateBridge调用
function LogOutDelegateBridges(...)
    local registry = debug.getregistry()
    local bridges = {...}
    for i, v in ipairs(bridges) do
        if registry[v] then
            local info = debug.getinfo(registry[v]);
            if info.short_src:match("Delegate") and info.linedefined == 73 then
                local funcName, func = debug.getupvalue(info.func, 1)
                local instName, inst = debug.getupvalue(info.func, 2)
                local funcInfo = debug.getinfo(func);
                g_Logger.Error(string.format("%s:%d", funcInfo.short_src, funcInfo.linedefined));
            elseif info.short_src:match("BaseUIComponent") and (info.linedefined == 271 or info.linedefined == 278) then
                local instName, inst = debug.getupvalue(info.func, 1)
                local button, buttonName = debug.getupvalue(info.func, 2)
                local clsName = inst.__class.__cname;
                if info.linedefined == 271 then
                    g_Logger.Error(string.format("%s文件的%s按钮未释放PointerDown", clsName, buttonName));
                else
                    g_Logger.Error(string.format("%s文件的%s按钮未释放onClick", clsName, buttonName));
                end
            else
                g_Logger.Error(string.format("%s:%d", info.short_src, info.linedefined));
            end
        end
    end
end