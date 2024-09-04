local ConfigUtils = {}
local ConfigPathConst = "GameAssets/Configs/%s.bin";
local EditorPath = CS.UnityEngine.Application.dataPath.."/../Configs/%s.bin";
local VCSPath = CS.UnityEngine.Application.dataPath.."/../Configs/%s.bin";

function ConfigUtils.GetCfgLuaName(name)
    return ("%sConfig"):format(name);
end

function ConfigUtils.LoadConfigBinary(name)
    --- 编辑器环境下读ssr-logic目录下的内容
    local flag, msg = pcall(function()
        if USE_PRIVATE_SERVER_LOCAL_CONFIG then
            return io.readfile(EditorPath:format(name), true)
        else
            return CS.LogicRepoUtils.ReadConfigsFromPack(name)
        end
    end)
    if not flag then
        error(("无法找到配置%s的二进制文件, error msg : %s"):format(name, msg));
    end
    return msg;
end

function ConfigUtils.LoadConfigSvnVersion()
    local flag, content = pcall(function()
        return CS.DragonReborn.IOUtils.ReadGameAssetAsText("GameConfigs/config_vcs.bin")
    end)
    if not flag then
        g_Logger.ErrorChannel("配置文件版本号读取失败", content)
        return "unknown", 0
    end
    local version, time = string.match(content, "BranchName=([%w_%.]+),Revision=(%d+)")
    return version, tonumber(time)
end

return ConfigUtils;