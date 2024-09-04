local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local QueuedTask = require('QueuedTask')

---@class UIGuideFingerDialogComponent : BaseUIComponent
local UIGuideFingerDialogComponent = class('UIGuideFingerDialogComponent', BaseUIComponent)

function UIGuideFingerDialogComponent:ctor()
    
end

function UIGuideFingerDialogComponent:OnCreate()    
    self.txtInfo = self:Text('p_text_content_1')
    self.imgInfo = self:Image('p_img_hero_1')
end


function UIGuideFingerDialogComponent:OnShow(param)
  
end

function UIGuideFingerDialogComponent:OnFeedData(param)    
    self.txtInfo.text = I18N.Get(param.infoContain)
    self:LoadSprite(param.infoImage,self.imgInfo)
end


return UIGuideFingerDialogComponent
