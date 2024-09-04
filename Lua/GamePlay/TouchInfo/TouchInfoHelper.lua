local TouchInfoCompDatum = require("TouchInfoCompDatum")
local TouchInfoTemplate = require("TouchInfoTemplate")

---@class TouchInfoHelper
local TouchInfoHelper = {}

---@param name string
---@param level number|nil
---@param detailsFunc function|nil
---@param position string|nil
---@return TouchInfoNameCompDatum
function TouchInfoHelper.GenerateNameCompData(name, level, position, detailsFunc)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_NAME, { name = name, level = level, position = position, detailsFunc = detailsFunc})
end

---@param func fun(param):boolean 返回true时点击完不关闭环形菜单
---@param param any
---@param icon string
---@param text string
---@param background string
---@param enableFunc fun(param):boolean | nil
---@param style string|nil
---@param disableStyle string|nil
---@param disableFunc fun(param):boolean 返回true时点击完不关闭环形菜单
---@param disableTipFunc fun(param):string disable时在按钮下面显示的红色提示文字
---@return TouchInfoButtonCompDatum
function TouchInfoHelper.GenerateButtonCompData(func, param, icon, text, background, enableFunc, textStyle, disableTextStyle, disableFunc, disableTipFunc)
    return TouchInfoCompDatum.new(TouchInfoTemplate.BUTTON, { 
        func = func, param = param, icon = icon, text = text, background = background, 
        enableFunc = enableFunc, textStyle = textStyle, disableTextStyle = disableTextStyle, disableFunc = disableFunc, disableTipFunc = disableTipFunc})
end

---@param front string
---@param background string
---@return TouchInfoImageCompDatum
function TouchInfoHelper.GenerateImageCompData(front, background)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_IMAGE, { front = front, background = background})
end

---@param rewards ItemIconData[]
---@param title string|nil
---@return TouchInfoRewardCompDatum
function TouchInfoHelper.GenerateRewardCompData(rewards, title, showTip)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_REWARD, { rewards = rewards, title = title, showTip = showTip})
end

---@param content string|fun():string
---@param needTick boolean|nil
---@return TouchInfoTextCompDatum
function TouchInfoHelper.GenerateTextCompData(content, needTick)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_TEXT, {content = content, needTick = needTick or false})
end

---@param icon string
---@param name string
---@param content string|fun():string
---@param needTick boolean|nil
---@return TouchInfoPairCompDatum
---backState默认受当前子window是否有背景图和是否邻居兄弟节点有PairComp影响, 其值在TouchInfoMediator:PreFeedData函数中受到校正
function TouchInfoHelper.GeneratePairCompData(icon, name, content, needTick)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_PAIR, { icon = icon, name = name, content = content, needTick = needTick or false, backState = 1})
end

---@param icon string
---@param name string
---@param content string|fun():string
---@param progress number|fun():number
---@param needTick boolean|nil
---@return TouchInfoProgressCompDatum
function TouchInfoHelper.GenerateProgressCompData(icon, name, content, progress, needTick)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_PROGRESS, { icon = icon, name = name, content = content, progress = progress, needTick = needTick or false})
end

---@param icon string
---@param name string
---@return TouchInfoResidentCompDatum
function TouchInfoHelper.GenerateResidentCompData(icon, name)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_RESIDENT, { icon = icon, name = name})
end

---@param title string
---@param name string
---@return TouchInfoPollutionCompDatum
function TouchInfoHelper.GeneratePollutionCompData(title, name)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_POLLUTION, {title = title, name = name})
end

---@param title string
---@param progress number|fun():number
---@param progressText string|fun():string
---@param needTick boolean|nil
---@return TouchInfoTaskProgressCompDatum
function TouchInfoHelper.GenerateTaskProgressCompData(title, progress, progressText, needTick)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_TASK_PROGRESS, {title = title, progress = progress, progressText = progressText, needTick = needTick or false})
end

---@param desc string
---@param finished boolean
---@return TouchInfoSingleTaskCompDatum
function TouchInfoHelper.GenerateSingleTaskCompData(desc, finished)
    return TouchInfoCompDatum.new(TouchInfoTemplate.GROUP_TASK_SINGLE, {desc = desc, finished = finished})
end

return TouchInfoHelper