local GUILayout = {}
GUILayout.cs = CS.UnityEngine.GUILayout
GUILayout.gui_cs = CS.UnityEngine.GUI
GUILayout.utility_cs = CS.UnityEngine.GUILayoutUtility

GUILayout.expandWidth = GUILayout.cs.ExpandWidth(true)
GUILayout.expandHeight = GUILayout.cs.ExpandHeight(true)
GUILayout.shrinkWidth = GUILayout.cs.ExpandWidth(false)
GUILayout.shrinkHeight = GUILayout.cs.ExpandHeight(false)
GUILayout._cs_ToggleFix = nil

local function GetBoxLeftSkin()
    if not GUILayout.boxLeftSkin then
        GUILayout.boxLeftSkin = CS.UnityEngine.GUIStyle(GUILayout.gui_cs.skin.box)
        GUILayout.boxLeftSkin.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
    end
    return GUILayout.boxLeftSkin
end

local function GetBoxLineSkin()
    if not GUILayout.boxLineSkin then
        GUILayout.boxLineSkin = CS.UnityEngine.GUIStyle(GUILayout.gui_cs.skin.box)
        GUILayout.boxLineSkin.border = CS.UnityEngine.RectOffset(0,0,0,0)
        GUILayout.boxLineSkin.margin = CS.UnityEngine.RectOffset(0,0,0,0)
        GUILayout.boxLineSkin.overflow = CS.UnityEngine.RectOffset(0,0,0,0)
        GUILayout.boxLineSkin.padding = CS.UnityEngine.RectOffset(0,0,0,0)
        GUILayout.boxLineSkin.contentOffset = CS.UnityEngine.RectOffset(0,0,0,0)
    end
    return GUILayout.boxLineSkin
end

local function GetButtonLeftSkin(shrinkWidth, shrinkHeight)
    if not GUILayout.buttonLeftSkin then
        GUILayout.buttonLeftSkin = CS.UnityEngine.GUIStyle(GUILayout.gui_cs.skin.button)
        GUILayout.buttonLeftSkin.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
        GUILayout.buttonLeftSkin.stretchWidth = shrinkWidth and true or false
        GUILayout.buttonLeftSkin.stretchHeight = shrinkHeight and true or false
    end
    return GUILayout.buttonLeftSkin
end

local function MakeArrayType(csClass)
    local genericBuilder = xlua.get_generic_method(CS.System.Array, 'Empty')
    local emptyArray = genericBuilder(csClass)
    if emptyArray then
        local retInstance = emptyArray()
        if retInstance then
            return retInstance:GetType()
        end
    end
    return nil
end

function GUILayout.GetUnitySkin(skinItemName)
    return GUILayout.gui_cs.skin[skinItemName]
end

---@return CS.UnityEngine.GUIStyle
function GUILayout.GetButtonLeftSkin(shrinkWidth, shrinkHeight)
    return GetButtonLeftSkin(shrinkWidth, shrinkHeight)
end

function GUILayout.Label(text, ...)
    GUILayout.cs.Label(text, ...)
end

function GUILayout.Box(text, ...)
    GUILayout.cs.Box(text, ...)
end

function GUILayout.BoxLeftAlignment(text, ...)
    GUILayout.cs.Box(text, GetBoxLeftSkin(), ...)
end

function GUILayout.BoxLine(...)
    GUILayout.cs.Box('', GetBoxLineSkin(), ...)
end

function GUILayout.Button(text, ...)
    return GUILayout.cs.Button(text, ...)
end

function GUILayout.ColoredButton(text, color, ...)
    local oldColor = GUILayout.gui_cs.backgroundColor
    GUILayout.gui_cs.backgroundColor = color
    local ret = GUILayout.cs.Button(text, ...)
    GUILayout.gui_cs.backgroundColor = oldColor
    return ret
end

function GUILayout.RepeatButton(text, ...)
    return GUILayout.cs.RepeatButton(text, ...)
end

function GUILayout.TextField(text, ...)
    return GUILayout.cs.TextField(text, ...)
end

function GUILayout.PasswordField(password, maskChar, ...)
    return GUILayout.cs.PasswordField(password, maskChar, ...)
end

function GUILayout.TextArea(text, ...)
    return GUILayout.cs.TextArea(text, ...)
end

function GUILayout.Toggle(value, text, ...)
    if not GUILayout._cs_ToggleFix then
        local m = typeof(GUILayout.cs):GetMethod('Toggle',{typeof(CS.System.Boolean),typeof(CS.System.String), MakeArrayType(CS.UnityEngine.GUILayoutOption)})
        if m then
            GUILayout._cs_ToggleFix = xlua.tofunction(m)
        end 
    end
    if GUILayout._cs_ToggleFix then
        return GUILayout._cs_ToggleFix(value, text, ...)
    end
    return value
end

function GUILayout.Toolbar(selected, texts, ...)
    return GUILayout.cs.Toolbar(selected, texts, ...)
end

function GUILayout.SelectionGrid(selected, texts, xCount, ...)
    return GUILayout.cs.SelectionGrid(selected, texts, xCount, ...)
end

function GUILayout.SelectionGridLeftAlignment(selected, texts, xCount, ...)
    return GUILayout.cs.SelectionGrid(selected, texts, xCount, GetButtonLeftSkin(), ...)
end

function GUILayout.HorizontalSlider(value, leftValue, rightValue, ...)
    return GUILayout.cs.HorizontalSlider(value, leftValue, rightValue, ...)
end

function GUILayout.VerticalSlider(value, leftValue, rightValue, ...)
    return GUILayout.cs.VerticalSlider(value, leftValue, rightValue, ...)
end

function GUILayout.HorizontalScrollbar(value, size, leftValue, rightValue, ...)
    return GUILayout.cs.HorizontalScrollbar(value, size, leftValue, rightValue, ...)
end

function GUILayout.VerticalScrollbar(value, size, topValue, bottomValue, ...)
    return GUILayout.cs.VerticalScrollbar(value, size, topValue, bottomValue, ...)
end

function GUILayout.Space(pixels)
    GUILayout.cs.Space(pixels)
end

function GUILayout.FlexibleSpace()
    GUILayout.cs.FlexibleSpace()
end

function GUILayout.BeginHorizontal(...)
    GUILayout.cs.BeginHorizontal(...)
end

function GUILayout.EndHorizontal()
    GUILayout.cs.EndHorizontal()
end

function GUILayout.BeginVertical(...)
    GUILayout.cs.BeginVertical(...)
end

function GUILayout.EndVertical()
    GUILayout.cs.EndVertical()
end

function GUILayout.BeginArea(screenRect)
    GUILayout.cs.BeginArea(screenRect)
end

function GUILayout.EndArea()
    GUILayout.cs.EndArea()
end

function GUILayout.BeginScrollView(scrollPosition, ...)
    return GUILayout.cs.BeginScrollView(scrollPosition, ...)
end

function GUILayout.BeginScrollViewWithVerticalBar(scrollPosition, ...)
    return GUILayout.cs.BeginScrollView(scrollPosition, false, true, ...)
end

function GUILayout.EndScrollView()
    GUILayout.cs.EndScrollView()
end

function GUILayout.Width(width)
    return GUILayout.cs.Width(width)
end

function GUILayout.MinWidth(minWidth)
    return GUILayout.cs.MinWidth(minWidth)
end

function GUILayout.MaxWidth(maxWidth)
    return GUILayout.cs.MaxWidth(maxWidth)
end

function GUILayout.Height(height)
    return GUILayout.cs.Height(height)
end

function GUILayout.MinHeight(minHeight)
    return GUILayout.cs.MinHeight(minHeight)
end

function GUILayout.MaxHeight(maxHeight)
    return GUILayout.cs.MaxHeight(maxHeight)
end

function GUILayout.ExpandWidth(expand)
    return GUILayout.cs.ExpandWidth(expand)
end

function GUILayout.ExpandHeight(expand)
    return GUILayout.cs.ExpandHeight(expand)
end

function GUILayout.GetRect(...)
    return GUILayout.utility_cs.GetRect(...)
end

function GUILayout.GetLastRect()
    return GUILayout.utility_cs.GetLastRect()
end

---@param id number | "int"
---@param clientRect "Rect"
---@param func "GUI.WindowFunction"
---@param title string
---@return "Rect"
function GUILayout.Window(id, clientRect, func, title, ...)
    return GUILayout.cs.Window(id, clientRect, func, title, ...)
end

return GUILayout