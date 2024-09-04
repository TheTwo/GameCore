
local CitizenBubbleState = require("CitizenBubbleState")

---@class CitizenBubbleStateNone:CitizenBubbleState
---@field new fun():CitizenBubbleStateNone
---@field super CitizenBubbleState
local CitizenBubbleStateNone = class('CitizenBubbleStateNone', CitizenBubbleState)

return CitizenBubbleStateNone