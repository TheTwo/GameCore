local BaseUIMediator = require('BaseUIMediator')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require("ArtResourceUtils")

local PetGeneMediator = class('PetGeneMediator', BaseUIMediator)
function PetGeneMediator:ctor()
    self._rewardList = {}
end

function PetGeneMediator:OnCreate()
    self.child_btn_close = self:Button('child_btn_close', Delegate.GetOrCreate(self, self.OnBtnBackClick))
    self.p_pet_dna = self:LuaObject('p_pet_dna')
end

function PetGeneMediator:OnShow(param)
    local res = param
    self.p_pet_dna:ShowDetail(true)
    self.p_pet_dna:FeedData(res)
end

function PetGeneMediator:OnHide(param)
end

function PetGeneMediator:OnBtnBackClick()
    g_Game.UIManager:CloseByName("PetGeneMediator")
end

return PetGeneMediator
