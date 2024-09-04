--- scene:scene_league_popup_authority

local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

local BaseUIMediator = require("BaseUIMediator")

---@class AllianceAuthorityMediator:BaseUIMediator
---@field new fun():AllianceAuthorityMediator
---@field super BaseUIMediator
local AllianceAuthorityMediator = class('AllianceAuthorityMediator', BaseUIMediator)

function AllianceAuthorityMediator:OnCreate(param)
    ---@type CommonPopupBackComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")
    self._p_table = self:TableViewPro("p_table")
    ---@type AllianceAuthorityRankColumComponent[]
    self._prs = {}
    for i = 1, 5 do
        local key = string.format("p_r%s", i)
        self._prs[i] = self:LuaObject(key)
    end
end

function AllianceAuthorityMediator:OnOpened(param)
    ---@type CommonBackButtonData
    local btnData = {
        title = I18N.Get("league_permission")
    }
    self._child_popup_base_l:FeedData(btnData)
    local selfRank = ModuleRefer.PlayerModule:GetPlayer().Owner.AllianceRank
    for i = 1, #self._prs do
        self._prs[i]:FeedData(i)
    end
    self._p_table:Clear()
    local showRowBackground = false
    local l = ConfigRefer.AllianceAuthority.length
    for _, v in ConfigRefer.AllianceAuthority:ipairs() do
        l = l - 1
        if v:Hide() then
            goto continue
        end
        ---@type AllianceAuthorityRankCellData
        local cellData = {
            rank = selfRank,
            authority = v,
            isLast = l == 0,
            showRowBackground = showRowBackground
        }
        showRowBackground = not showRowBackground
        self._p_table:AppendData(cellData)
        ::continue::
    end
end

function AllianceAuthorityMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
end

function AllianceAuthorityMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_LEAVED, Delegate.GetOrCreate(self, self.CloseSelf))
end

return AllianceAuthorityMediator