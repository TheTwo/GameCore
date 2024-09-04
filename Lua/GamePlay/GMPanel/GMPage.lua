---@class GMPage
local GMPage = class('GMPage')

function GMPage:ctor()
    
end

---@param panel GMPanel
function GMPage:Init(panel)
    self.panel = panel
end

function GMPage:OnShow()
    
end

function GMPage:OnGUI()
    -- override this
end

function GMPage:Tick()

end

function GMPage:OnHide()
    
end

function GMPage:Release()
    
end

return GMPage