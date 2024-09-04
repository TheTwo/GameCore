local BaseUIComponent = require("BaseUIComponent")
local AllianceTechPromptPreviewComponent = class('AllianceTechPromptPreviewComponent', BaseUIComponent)

function AllianceTechPromptPreviewComponent:OnCreate(param)
    self.p_text_1 = self:Text("p_text_1")
    self.p_text_2 = self:Text("p_text_2")
end

function AllianceTechPromptPreviewComponent:OnFeedData(param)
    self.p_text_1.text = param.level
    self.p_text_2.text = param.data
end

return AllianceTechPromptPreviewComponent
