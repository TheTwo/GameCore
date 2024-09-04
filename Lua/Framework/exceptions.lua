-- try回调函数和catch回调函数可以返回一个bool值，来通知try_catch的外部调用者是否需要break或者return
--[[
    local should_caller_break, ... = try_catch(function()
        -- 这里写可能会触发异常的逻辑
    end,
    function(error)
        -- 这里写异常处理逻辑，error是pcall输出的错误
    end
    )

    if should_caller_break then
        -- 根据try和catch的返回值进行相应的处理，例如：退出当前函数的执行，或者跳出循环等等
    end
]]

local function print_error(...)
    if g_Logger then
        g_Logger.Error(debug.traceback(...));
    else
        print(debug.traceback(...))
    end
end

local function post_protected_call(catch, flag, ...)
    if flag then
        return false, ...
    else
        local msg = ...
        if catch then
            return true, catch(msg)
        end
    end
    return false
end

local function do_try_catch(try, catch, msg, ...)
    if not try then
        return false
    end

    if msg then
        return post_protected_call(catch, xpcall(try, msg, ...))
    else
        return post_protected_call(catch, pcall(try, ...))
    end
end

function try_catch(try, catch)
    return do_try_catch(try, catch)
end

---@param try fun()
---@param catch fun(error)
function try_catch_traceback(try, catch)
    return do_try_catch(try, catch, print_error)
end

function try_catch_vararg(try, catch, ...)
    return do_try_catch(try, catch, nil, ...)
end

---@param try fun()
---@param catch fun(error)
---@vararg any
function try_catch_traceback_with_vararg(try, catch, ...)
    return do_try_catch(try, catch, print_error, ...)
end

