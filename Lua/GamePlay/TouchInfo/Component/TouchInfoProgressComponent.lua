local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require("Delegate")

---@class TouchInfoProgressComponent:BaseUIComponent
local TouchInfoProgressComponent = class('TouchInfoProgressComponent', BaseUIComponent)

---@class TouchInfoProgressCompData
---@field icon string
---@field name string
---@field content string|fun():string
---@field progress number|fun():number
---@field needTick boolean

function TouchInfoProgressComponent:OnCreate()
    self._p_progress = self:Image("p_progress")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_item_name = self:Text("p_text_item_name")
    self._p_text_item_content = self:Text("p_text_item_content")
end

---@param data TouchInfoProgressCompData
function TouchInfoProgressComponent:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_item)
    self._p_text_item_name.text = data.name
    if type(data.content) == "string" then
        self._p_text_item_name.text = data.content
    elseif type(data.content) == "function" then
        self._p_text_item_content.text = data.content()
    end

    if type(data.progress) == "number" then
        self._p_progress.fillAmount = data.progress
    elseif type(data.progress) == "function" then
        self._p_progress.fillAmount = data.progress()
    end

    if data.needTick then
        self.data = data
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
        self.tick = true
    end
end

function TouchInfoProgressComponent:OnTick()
    if self.data then
        local data = self.data
        if type(data.content) == "string" then
            self._p_text_item_name.text = data.content
        elseif type(data.content) == "function" then
            self._p_text_item_content.text = data.content()
        end
    
        if type(data.progress) == "number" then
            self._p_progress.fillAmount = data.progress
        elseif type(data.progress) == "function" then
            self._p_progress.fillAmount = data.progress()
        end
    end
end

function TouchInfoProgressComponent:OnClose()
    if self.tick then
        self.tick = nil
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    end
end

return TouchInfoProgressComponent 