local BaseModule = require("BaseModule")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local DBEntityPath = require('DBEntityPath')
local QueuedTask = require('QueuedTask')
local GuideConst = require('GuideConst')
local UIMediatorNames = require('UIMediatorNames')
local GotoUtils = require('GotoUtils')
---@class GamePlaySequenceModule : BaseModule
local cls = class('GamePlaySequenceModule',BaseModule)

function cls:ctor()

end

function cls:OnRegister()

end

function cls:OnRemove()

end

function cls:NeedFirstChapterUnlokedAnim()
    local chapterModule = ModuleRefer.QuestModule.Chapter
    if not chapterModule then
        return true
    end
    return  chapterModule:IsCurrentChapterIsFirstChapter() and not chapterModule:IsCurrentChapterGroupUnlockAnimPlayed()
end

---@param kingdomScene KingdomScene
---@param city City
function cls:StartSequence_EnterMyCity(kingdomScene,city)
    if not self.myCityTask then
        self.myCityTask = QueuedTask.new()
    elseif self.myCityTask:IsExecuting() then
        self.myCityTask:Release()
    end
    self.myCityTask:WaitTrue(function()
        return kingdomScene.basicCamera:Idle()
    end):WaitTrue(function()
        --wait for City is Ready
        return city:AllLoadFinished()
    end)
    :DoAction(function()
        require("PvPRequestService").InvalidateMapAOI()
        ModuleRefer.SlgModule:UpdateSlgScale(true)
    end)
    if self:NeedFirstChapterUnlokedAnim() then
        local storyEnd = false
        self.myCityTask:DoAction(function()
            ModuleRefer.QuestModule.Chapter:PlayCurrentGroupStory(function() storyEnd = true end)
        end):WaitTrue(function()
            return storyEnd
        end)
    end
    local guideEnd = false
    self.myCityTask:DoAction(function()
        ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.EnterCity,function()
            guideEnd = true
        end)
    end):WaitTrue(function()
        return guideEnd
    end)

    self.myCityTask:Start()
end

function cls:StopSequence_EnterMyCity()
    if self.myCityTask then
        if self.myCityTask:IsExecuting() then
            self.myCityTask:Release()
        end
        self.myCityTask = nil
    end
end

return cls