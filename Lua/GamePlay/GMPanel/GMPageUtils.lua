local Enum = CS.System.Enum
local XmlDocument = CS.System.Xml.XmlDocument
local Utils = require("Utils")

---@class GMPageUtils
local GMPageUtils = {}

function GMPageUtils.PrintEnum(type, value)
    return Enum.GetName(typeof(type), value)
end

function GMPageUtils.PrintBool(b)
    if b then
        return "✔︎"
    end
    return "✖︎"
end

function GMPageUtils.DrawReddot(position, radius)
    local color = CS.UnityEngine.Color.red
    local oldColor = CS.UnityEngine.GUI.color
    CS.UnityEngine.GUI.color = color
    CS.UnityEngine.GUI.DrawTexture(CS.UnityEngine.Rect(position.x - radius, position.y - radius, radius * 2, radius * 2), CS.UnityEngine.Texture2D.whiteTexture)
    CS.UnityEngine.GUI.color = oldColor
end

function GMPageUtils.GetXmlColorAndContent(xmlContent)
    if not string.StartWith(xmlContent, "<color") then
        return nil, xmlContent
    end
    local doc = XmlDocument()
    doc:LoadXml(xmlContent)
    local root = doc.DocumentElement
    if root then
        for i = 0, doc.ChildNodes.Count - 1 do
            local node = doc.ChildNodes[i]
            if node.Name == "color" then
                local colorStr = node:GetAttribute("color")
                local _, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorStr)
                return color, node.InnerText
            end
        end
    end
    return nil, xmlContent
end

return GMPageUtils