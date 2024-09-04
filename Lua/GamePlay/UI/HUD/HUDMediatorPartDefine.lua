---@class HUDMediatorPartDefine
local HUDMediatorPartDefine = {
    none = 0,

    topLeft = 1 << 1,
    left = 1 << 2,
    bottomLeft = 1 << 3,
    topRight = 1 << 4,
    right = 1 << 5,
    bottomRight = 1 << 6,
    top = 1 << 7,
    bottom = 1 << 8,
    fullscreen = 1 << 9,
    base_top = 1 << 10,
    bossInfo = 1 << 11,
    ---logic part
    allLeft = 1 << 1 | 1 << 2 | 1 << 3,
    allRight = 1 << 4 | 1 << 5 | 1 << 6,
    allTop = 1<< 1 | 1 << 4 | 1 << 7,
    allBottom = 1 << 3 | 1 << 6 | 1 << 9,

    bottomCenterRight = 1 << 5 | 1 << 6,

    
    everyThingButNotbossInfo = ~(1 << 11),
    everyThing = ~0
}
return HUDMediatorPartDefine

