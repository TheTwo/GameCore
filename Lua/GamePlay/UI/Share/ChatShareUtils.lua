local ChatShareType = require("ChatShareType")
local ConfigRefer = require("ConfigRefer")
local DBEntityType = require("DBEntityType")


local ChatShareUtils = {}


function ChatShareUtils.GetConfigIDByType(type)
    -- local shareType = ChatShareUtils.TypeTrans(type)
    for k, v in ConfigRefer.ChatShare:ipairs() do
        if v:Type() == type then
            return v:Id()
        end
    end
end


---@param type number   DBEntityType
---@return number  ChatShareType
function ChatShareUtils.TypeTrans(type)
    if type == DBEntityType.Expedition then
        return ChatShareType.WorldEvent
    elseif type == DBEntityType.ResourceField then
        return ChatShareType.ResourceField
    elseif type == DBEntityType.MapMob then
        return ChatShareType.SlgMonster
    elseif type == DBEntityType.Village or type == DBEntityType.Pass then
        return ChatShareType.SlgBuilding
    else
        return ChatShareType.Position
    end
end

return ChatShareUtils
