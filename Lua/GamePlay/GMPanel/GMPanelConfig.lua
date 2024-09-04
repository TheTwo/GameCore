---@type GMHeader[]
local registerForHeader = {
    {"显示帧率信息", require("GMHeaderFps")},
    {"显示卡顿信息", require("GMHeaderJank")},
    {"显示电流信息", require("GMHeaderCurrent")},
    {"显示渲染信息", require("GMHeaderRender")},
    {"显示网络信息", require("GMHeaderServiceManager")},
    -- {"显示启动状态", require("GMHeaderBootState")},
    {"显示剧情信息", require("GMHeaderStory")},
    {"显示大地图坐标", require("GMHeaderKingdomCoordinate")},
    {"显示城内坐标", require("GMHeaderCityCoordinate")},
    {"显示城内状态", require("GMHeaderCityState")},
    -- {"显示大地图状态", require("GMHeaderKingdomSceneState")},
}

---@type table[]
local registerForPage = {
    {"选服", require("GMPageSelectServer")},
    {"账户", require("GMPageAccount")},
    {"服务器GM", require("GMPageToServerCmd")},
    {"快捷方法", require("GMPageQuickTest")},
    {"物品获得", require("GMPageItem")},
    {"LUA调试器", require("GMPageLuaDebug")},
    {"LUA控制台", require("GMPageLua")},
    {"优化", require("GMPageOpt")},
    {"设置", require("GMPagePanelSettings")},
    {"异常", require("GMPageExceptionTest")},
    {"分析器", require("GMPageProfiler")},
    {"多语言", require("GMPageLocalization")},
    {"网络", require("GMPageNetwork")},
    {"特性", require("GMPageSupportedFeatures")},
    {"声音", require("GMPageSound")},
    {"剧情", require("GMPageStory")},
    {"信息", require("GMPageSystemInfo")},
    {"王国", require("GMPageKingdom")},
    {"主城", require("GMPageMyCity")},
    {"SE", require("GMPageSE")},
	{"SE爬塔", require("GMPageSEClimbTower")},
    {"SLG", require("GMPageSlg")},
    {'英雄',require("GMPageHero")},
    {"引导", require("GMPageGuide")},
    {"联盟", require("GMPageAlliance")},
    {"居民", require("GMPageCitizen")},
	{"宠物", require("GMPagePet")},
    {"活动", require("GMPageActivity")},
    {"临时入口", require("GMPageDebugEntry")},
}

return {Headers = registerForHeader, Pages = registerForPage}
