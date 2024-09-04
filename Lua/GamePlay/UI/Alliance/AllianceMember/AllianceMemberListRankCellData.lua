local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceMemberListRankCellData:BaseTableViewProExpendData
---@field super BaseTableViewProExpendData
---@field Rank number
---@field count number
---@field max number
---@field __childCellsData wds.AllianceMember[]
local AllianceMemberListRankCellData = class("AllianceMemberListRankCellData", BaseTableViewProExpendData)

function AllianceMemberListRankCellData:ctor()
    AllianceMemberListRankCellData.super.ctor(self)
    self.Rank = 0
    self.count = 0
    self.max = 0
end

---@param memberFacebookId number
function AllianceMemberListRankCellData:HasMember(memberFacebookId)
    for _, value in pairs(self.__childCellsData) do
        if value.FacebookID == memberFacebookId then
            return true
        end
    end
    return false
end

return AllianceMemberListRankCellData