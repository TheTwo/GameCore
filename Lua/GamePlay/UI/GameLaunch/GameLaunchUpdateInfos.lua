local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
---@class GameUpdateInfoDesc
---@field image string
---@field desc string

---@class GameLaunchUpdateInfos : BaseUIComponent
local GameLaunchUpdateInfos = class('GameLaunchUpdateInfos', BaseUIComponent)

function GameLaunchUpdateInfos:ctor()

end

function GameLaunchUpdateInfos:OnCreate()    
    self.imgImageUpdate = self:Image('p_image_update')
    self.textTitle = self:Text('p_text_title', I18N.Temp().text_update_theme)
    self.textDetail = self:Text('p_text_detail')
end


---@param param GameUpdateInfoDesc
function GameLaunchUpdateInfos:OnFeedData(param)
    if not param then return end
    if param.image then
        g_Game.SpriteManager.LoadSprite(param.image,self.imgImageUpdate)        
    end
    if param.desc then
        self.textDetail.text = I18N(param.desc)
    end
end




return GameLaunchUpdateInfos;
