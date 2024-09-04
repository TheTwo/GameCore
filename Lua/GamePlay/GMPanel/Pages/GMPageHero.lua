local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
---@class GMPageHero:GMPage
local GMPageHero = class('GMPageHero', GMPage)

function GMPageHero:ctor()
    self.ui3dModel = nil
end


function GMPageHero:OnGUI()
    GUILayout.BeginVertical()

    -- if GUILayout.Button('Close UI 3D') then
    --     g_Game.UIManager:CloseUI3DModelView()
    -- end

    if GUILayout.Button('Turn') then
        if self.ui3dModel then
            self.ui3dModel:RotateModelY(1)
        end
    end
    GUILayout.BeginHorizontal()
    if GUILayout.Button('打开装备打造界面') then
        g_Game.UIManager:Open('HeroEquipForgeRoomUIMediator')
    end
    self._inputRequire = GUILayout.TextArea(self._inputRequire, GUILayout.expandWidth)
    GUILayout.EndHorizontal()
    GUILayout.EndVertical()
end

function GMPageHero:SetupModelView()
    -- self.ui3dModel:SetLitAngle(CS.UnityEngine.Vector3(30,322.46,0))
    -- self.ui3dModel:SetModelPosition(CS.UnityEngine.Vector3(0,-6.14,0))
    -- self.ui3dModel:SetScreenCenter(-0.051,0)
    -- self.ui3dModel:RefreshEnv()


    local resCell = nil
    for key, cell in ConfigRefer.HeroClientRes:ipairs() do
        -- body
        if cell:ShowModel() and cell:ShowModel() > 0 then
            resCell = cell
            break
        end
    end

    if resCell then
        local rootPos = CS.UnityEngine.Vector3(resCell:ModelPosition(1), resCell:ModelPosition(2), resCell:ModelPosition(3))
        self.ui3dModel:SetModelPosition(rootPos)
        self.ui3dModel:SetScreenCenter(-0.051,0)
        self.ui3dModel:SetEnvTransform(rootPos,CS.UnityEngine.Vector3(0,180,0))
    end

end

return GMPageHero