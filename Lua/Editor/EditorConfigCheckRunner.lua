require("functions")
require("exceptions")
require("ClassCore")

--for IDE type annotation, no side effect
---@type Game
g_Game = {}
g_Game.RealTime = {}
g_Game.RealTime.time = 0

local EditorConfigCheckRunner = class('EditorConfigCheckRunner')
local rapidJson = require("rapidjson")


function EditorConfigCheckRunner.RunArtResourceCheck()
    local configManager = require('ConfigManager').new()
    local artResourceConfig = configManager:RetrieveConfig('ArtResource')
    local result = {}
    for _, cell in artResourceConfig:ipairs() do
        ---@type ArtResourceConfigCell
        local artResourceConfigCell = cell
        result['id ' .. artResourceConfigCell:Id()] = artResourceConfigCell:Path()
    end

    return tostring(rapidJson.encode(result))
end

function EditorConfigCheckRunner.ExportManualResourceConst()
    local ManualResourceConst = require('ManualResourceConst')
    local result = {}
    for k, v in pairs(ManualResourceConst) do
        result[k] = v
    end
    local UIResourceType = require('UIResourceType')
    local configManager = require('ConfigManager').new()
    ---@type StoryDialogConfig
    local storyDialog = configManager:RetrieveConfig('StoryDialog')
    ---@type ArtResourceUIConfig
    local artResoureceUiConfig = configManager:RetrieveConfig('ArtResourceUI')
    ---@type table<number, boolean>
    local processedConfigIdSet = {}
    for _, value in storyDialog:ipairs() do
        local characterImage = value:CharacterImage()
        local CharacterImageRight = value:CharacterImageRight()
        if characterImage ~= 0 and not processedConfigIdSet[characterImage] then
            processedConfigIdSet[characterImage] = true
            local sp = artResoureceUiConfig:Find(characterImage)
            if sp and sp:Type() == UIResourceType.Spine then
                local path = sp:Path()
                if not string.IsNullOrEmpty(path) then
                    result[path] = path
                end
            end
        end
        if CharacterImageRight ~= 0 and not processedConfigIdSet[characterImage] then
            processedConfigIdSet[characterImage] = true
            local sp = artResoureceUiConfig:Find(CharacterImageRight)
            if sp and sp:Type() == UIResourceType.Spine then
                local path = sp:Path()
                if not string.IsNullOrEmpty(path) then
                    result[path] = path
                end
            end
        end
    end

    return tostring(rapidJson.encode(result))
end

return EditorConfigCheckRunner