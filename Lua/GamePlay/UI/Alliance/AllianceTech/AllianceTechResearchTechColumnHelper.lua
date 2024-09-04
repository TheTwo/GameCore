
-- 1 (1)
        -- 5 (2)
-- 2 (3)
        -- 6 (4)
-- 3 (5)
        -- 7 (6)
-- 4 (7)

---@class AllianceTechResearchTechColumnHelper
---@field new fun():AllianceTechResearchTechColumnHelper
local AllianceTechResearchTechColumnHelper = sealedClass('AllianceTechResearchTechColumnHelper')

function AllianceTechResearchTechColumnHelper.CalculateCellEvenOddPos(idx, columnCellCount)
    local isOdd = (columnCellCount & 1) == 1
    if isOdd then
        if columnCellCount == 1 then
            return 4
        end
        return idx * 2
    elseif columnCellCount == 2 then
        if idx == 1 then
            return 2
        else
            return 6
        end
    end
    return idx * 2 - 1
end

return AllianceTechResearchTechColumnHelper