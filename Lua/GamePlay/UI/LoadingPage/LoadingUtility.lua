local ConfigRefer = require('ConfigRefer')
local LoadingType = require('LoadingType')
local ArtResourceUtils = require('ArtResourceUtils')
local ArtResourceUIConsts = require('ArtResourceUIConsts')
local LoadingUtility = class("LoadingUtility")
local CityUtils = require('CityUtils')

---@return number
function LoadingUtility.GetLevel()
    return CityUtils.GetBaseLevel()
end

---@return number[]
function LoadingUtility.GetBackGroundImageIds(lvl,type)
    local imgs = {}
    for _, value in ConfigRefer.LoadingBackGrounds:ipairs() do
        local cfgType = value:Type()
        if cfgType ~= LoadingType.All and cfgType ~= type then
            goto continue
        end
        if value:MinLevel() <= lvl and value:MaxLevel() > lvl then
            table.insert(imgs,value:Background())
        end
        ::continue::
    end
    return imgs
end

---@return string
function LoadingUtility.GetBackGroundImage(lvl,type)
    local imgIds = LoadingUtility.GetBackGroundImageIds(lvl,type)
    local bgName = nil
    if imgIds and #imgIds > 0 then
        local index = math.random(1,#imgIds)
        local imgId = imgIds[index]
        local imgName = ArtResourceUtils.GetUIItem(imgId)
        if g_Game.AssetManager:CanLoadSync(imgName) then
            bgName = imgName
        end
    end
    if not bgName then
        bgName = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.loading_background1)
    end
    return bgName
end

function LoadingUtility.GetTips(lvl,type)
    local tips = {}
    for _, value in ConfigRefer.LoadingTips:ipairs() do
        local cfgType = value:Type()
        if cfgType ~= LoadingType.All and cfgType ~= type then
            goto continue
        end
        if value:MinLevel() <= lvl and value:MaxLevel() > lvl then
            table.insert(tips,{
                tip = value:TipsText(),
                duration = value:TipsDuration(),
            }
        )
        end
        ::continue::
    end
    if #tips > 3 then
        --sort random
        local count = #tips
        local time = math.floor( count / 2 )
        for i = 1, time do
            local swapIndex = math.random(i,count)
            if swapIndex ~= i then
                local tmp = tips[i]
                tips[i] = tips[swapIndex]
                tips[swapIndex] = tmp
            end
        end
    end
    return tips
end

return LoadingUtility