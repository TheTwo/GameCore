--- scene:scene_league_popup_authority_position

local AllianceModuleDefine = require("AllianceModuleDefine")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceAuthorityPositionMediator:BaseUIMediator
---@field new fun():AllianceAuthorityPositionMediator
---@field super BaseUIMediator
local AllianceAuthorityPositionMediator = class('AllianceAuthorityPositionMediator', BaseUIMediator)

function AllianceAuthorityPositionMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")
    
    self._p_frame_head_r5 = self:Image("p_frame_head_r5")
    self._p_icon_logo_r5 = self:Image("p_icon_logo_r5")
    self._p_text_name_r5 = self:Text("p_text_name_r5")
    
    ---@type AllianceAuthorityPositionTitleComponent[]
    self._p_titles = {}

    for i = 1, 6 do
        local key = string.format("p_position_0%s", i)
        self._p_titles[i] = self:LuaObject(key)
    end
end

---@param param wds.AllianceMembers
function AllianceAuthorityPositionMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local btnData = {}
    btnData.title = I18N.Get("league_architecture")
    self._child_popup_base_l:FeedData(btnData)
    ---@type AllianceAuthorityPositionTitleComponentData[]
    local titleCellData = {}
    for i = 1, #self._p_titles do
        ---@type AllianceAuthorityPositionTitleComponentData
        local data = {}
        data.title = ConfigRefer.AllianceTitle:Find(i)
        titleCellData[i] = data
    end
    for _, v in pairs(param.Members) do
        if v.Rank == AllianceModuleDefine.LeaderRank then
            self._p_text_name_r5.text = v.Name
        end
    end
    for title, memberFacebookId in pairs(param.Titles) do
        local d = titleCellData[title]
        if title then
            d.player = param.Members[memberFacebookId]
        end
    end
    for i = 1, #self._p_titles do
        self._p_titles[i]:FeedData(titleCellData[i])
    end
end

return AllianceAuthorityPositionMediator