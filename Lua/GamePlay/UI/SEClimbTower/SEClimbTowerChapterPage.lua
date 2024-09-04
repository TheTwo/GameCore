local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")

---@class SEClimbTowerChapterPage:BaseUIComponent
---@field new fun():SEClimbTowerChapterPage
---@field super BaseUIComponent
local SEClimbTowerChapterPage = class('SEClimbTowerChapterPage', BaseUIComponent)

function SEClimbTowerChapterPage:OnCreate()
    self.tableChapter = self:TableViewPro('p_table_chapter')
end

function SEClimbTowerChapterPage:OnFeedData(data)
    self.tableChapter:Clear()
    for _, cell in ConfigRefer.ClimbTowerChapter:ipairs() do
        ---@type SEClimbTowerChapterCellData
        local data = {}
        data.configCell = cell
        self.tableChapter:AppendData(data)
    end
    self.tableChapter:RefreshAllShownItem(true)
end

return SEClimbTowerChapterPage