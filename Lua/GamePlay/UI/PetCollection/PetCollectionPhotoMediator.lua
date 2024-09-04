local BaseUIMediator = require('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local TimerUtility = require('TimerUtility')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local PetCollectionEnum = require('PetCollectionEnum')

local PetCollectionPhotoMediator = class('PetCollectionPhotoMediator', BaseUIMediator)
function PetCollectionPhotoMediator:ctor()
    self._rewardList = {}
end

function PetCollectionPhotoMediator:OnCreate()
    self.booktitle = self:Text('p_text_subtitle')
    self.bookPhotos = self:TableViewPro('p_table_photo')
    self.bookTabs = self:TableViewPro('p_tab_table')
    self.backButton = self:LuaObject('child_common_btn_back')
    self.Content_tab = self:RectTransform('Content_tab')
    self.p_btn_tab_cell = self:RectTransform('p_btn_tab_cell')
end

function PetCollectionPhotoMediator:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PET_COLLECTION_TAB, Delegate.GetOrCreate(self, self.Refresh))
    self.backButton:FeedData({title = I18N.Get(ConfigRefer.PetConsts:PetHandbookName())})
    if param then
        self.bookTabs:Clear()
        self:Refresh(param)
    end

    if param.curIndex > 5 then
        self.Content_tab.localPosition = CS.UnityEngine.Vector3(self.Content_tab.localPosition.x, self.Content_tab.localPosition.y + (param.curIndex - 5) * self.p_btn_tab_cell.rect.height, 0)
    end
end

function PetCollectionPhotoMediator:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PET_COLLECTION_TAB, Delegate.GetOrCreate(self, self.Refresh))
end

function PetCollectionPhotoMediator:Refresh(param)
    self:RefreshTabs(param)
    self:RefreshPhotos(param)
end

-- 区域Tab
function PetCollectionPhotoMediator:RefreshTabs(param)
    local curIndex = param.curIndex

    local add = self.bookTabs.DataCount == 0
    local list = ModuleRefer.PetCollectionModule:GetAreaList()

    for i = 1, #list do
        local data = list[i]
        if (data.passSys and data.passWorldStage) then
            data.curIndex = curIndex

            if add then
                self.bookTabs:AppendData(data)
            end
        end
    end
    -- self.bookTabs:RefreshAllShownItem()
end

-- 图鉴照片
function PetCollectionPhotoMediator:RefreshPhotos(param)
    local areaIndex = param.areaIndex
    self.bookPhotos:Clear()

    local list = ModuleRefer.PetCollectionModule:GetPetsByArea(areaIndex)
    local pageIndex = 1
    local max = 0
    for k, v in pairs(list) do
        v.pageIndex = pageIndex
        v.areaIndex = areaIndex
        self.bookPhotos:AppendData(v)
        pageIndex = pageIndex + 1
        max = max + 1
    end

    local count = ModuleRefer.PetCollectionModule:GetCurPetNumByArea(areaIndex)
    self.booktitle.text = ModuleRefer.PetCollectionModule:GetAreaName(param.areaIndex) .. ":" .. count .. "/" .. max
    self.bookPhotos:RefreshAllShownItem()
end

return PetCollectionPhotoMediator
