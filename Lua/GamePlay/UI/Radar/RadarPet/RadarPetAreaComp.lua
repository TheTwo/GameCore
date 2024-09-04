local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require('I18N')

---@class RadarPetAreaComp : BaseTableViewProCell
---@field data HeroConfigCache
local RadarPetAreaComp = class('RadarPetAreaComp', BaseTableViewProCell)

function RadarPetAreaComp:ctor()

end

function RadarPetAreaComp:OnCreate()
    self.p_holder = self:GameObject("p_holder")
    self.p_img_landform = self:Image("p_img_landform")
    self.p_text_need_1 = self:Text("p_text_need_1")
    self.p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnGotoClick))
end

function RadarPetAreaComp:OnFeedData(param)
    self.lockCastleLevel = param.lockCastleLevel
    self.cfgId = ModuleRefer.RadarModule:GetRadarTraceSelectPet()
    if param.lockCastleLevel then
        local level = ConfigRefer.Pet:Find(self.cfgId):PetTrackRadarLevel()
        self.p_text_need_1.text = I18N.GetWithParams("radartrack_info_upgrade_level", level)
    else
        local landCfgId = ConfigRefer.Pet:Find(self.cfgId):PetTrackLandId()
        local name = I18N.Get(ConfigRefer.Land:Find(landCfgId):Name())
        self.p_text_need_1.text = I18N.GetWithParams("radartrack_info_move_to_landform", name)
    end
end

function RadarPetAreaComp:OnGotoClick()
    if self.lockCastleLevel then
        local scene = g_Game.SceneManager.current
        if scene:IsInCity() then
            g_Game.UIManager:CloseByName(UIMediatorNames.RadarPetTraceMediator)
            g_Game.UIManager:CloseByName(UIMediatorNames.RadarMediator)
            ModuleRefer.GuideModule:CallGuide(1001)
        else
            g_Game.UIManager:CloseByName(UIMediatorNames.RadarPetTraceMediator)
            g_Game.UIManager:CloseByName(UIMediatorNames.RadarMediator)
            scene:ReturnMyCity(function()
                -- ModuleRefer.GuideModule:CallGuide(1001)
            end)
        end
        return
    end
    local landCfgId = ConfigRefer.Pet:Find(self.cfgId):PetTrackLandId()
    ---@type LandformIntroUIMediatorParam
    local data = {}
    data.entryLandCfgId = landCfgId
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator, data)
end

return RadarPetAreaComp
