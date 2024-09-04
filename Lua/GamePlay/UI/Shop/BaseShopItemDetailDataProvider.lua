local ConfigRefer = require('ConfigRefer')
local FunctionClass = require('FunctionClass')
---@class BaseShopItemDetailDataProvider
local BaseShopItemDetailDataProvider = class("BaseShopItemDetailDataProvider")

local BtnShowBitMask = {
    None = 0,
    Left = 1 << 0,
    Right = 1 << 1,
    Center = 1 << 2,
}

BaseShopItemDetailDataProvider.BtnShowBitMask = BtnShowBitMask

---virtual
function BaseShopItemDetailDataProvider:ctor(id)
    self._id = id
    self._showSlider = false
    self._showCoins = false
    self._showMoney = false
    self._showBtnIcon = false

    self._useSmallItemIcon = false
    self._useCommonDiscountTag = false
    self._useGiftBase = false
    self._useStoreBase = false

    self._btnShowMask = BtnShowBitMask.None

    ---@type fun(...)
    self._onBuyClick = function() end
end

---virtual
---@return ItemConfigCell
function BaseShopItemDetailDataProvider:GetItemCfg()
    return nil
end

---virtual
---@return string
function BaseShopItemDetailDataProvider:GetName()
    return string.Empty
end

---virtual
function BaseShopItemDetailDataProvider:GetDesc()
    return string.Empty
end

---virtual
---@return CommonDiscountTagParam
function BaseShopItemDetailDataProvider:GetDiscountTagParam()
    local dummy = {}
    dummy.discount = 0
    dummy.quality = 0
    dummy.isSoldOut = true
    return dummy
end

---virtual
---@return number
function BaseShopItemDetailDataProvider:GetDiscount()
    return 0
end

---virtual
---@return number
function BaseShopItemDetailDataProvider:GetIconId()
    return 0
end

---virtual
---@return string
function BaseShopItemDetailDataProvider:GetIconPath()
    return string.Empty
end

---virtual
---@return string | number
function BaseShopItemDetailDataProvider:GetIcon()
    return nil
end

---virtual
---@return CS.UnityEngine.Color
function BaseShopItemDetailDataProvider:GetQualityColor()
    return CS.UnityEngine.Color.white
end

---virtual
---@return number
function BaseShopItemDetailDataProvider:GetBuyLimit()
    return 0
end

---virtual
---@return number
function BaseShopItemDetailDataProvider:GetBoughtTimes()
    return 0
end

---virtual
---@return number
function BaseShopItemDetailDataProvider:GetPurchaseableCount()
    return 0
end

---virtual
---@return ItemConfigCell[]
function BaseShopItemDetailDataProvider:GetPriceItemCfgs()
    return {}
end

---virtual
---@return string
function BaseShopItemDetailDataProvider:GetPriceText()
    return string.Empty
end

---virtual
---@return number[]
function BaseShopItemDetailDataProvider:GetPrices()
    return {}
end

---virtual
---@return GiftTipsListInfoCell[]
function BaseShopItemDetailDataProvider:GetGoodsItemList()
    return {}
end

---virtual
---@return number
function BaseShopItemDetailDataProvider:GetExchangeNum()
    return 0
end

---@return UIPossiblePetCompData[]
function BaseShopItemDetailDataProvider:GetPetEggPreviewDatas()
    local itemCfg = self:GetItemCfg()
    if itemCfg == nil then
        return {}
    end
    return self:InternalGetPetEggPreviewDatas(itemCfg)
end

---@param itemCfg ItemConfigCell
---@return UIPossiblePetCompData[]
function BaseShopItemDetailDataProvider:InternalGetPetEggPreviewDatas(itemCfg)
    local functionClass = itemCfg:FunctionClass()
    if functionClass ~= FunctionClass.OpenPetEgg then
        return {}
    end
    local petPool = ConfigRefer.PetEggRewardPool:Find(tonumber(itemCfg:UseParam(1)))

    --找到对应宠物池
    local poolCfg = petPool:RandomCfg(petPool:RandomCfgLength()):RandomPool()
    local randomPool = ConfigRefer.PetEggRewardRandomPool:Find(poolCfg)

    --添加宠物
    local sortData = {}
    for i = 1, randomPool:RandomWeightLength() do
        local petCfgId = randomPool:RandomWeight(i):RefPet()
        local quality = ConfigRefer.Pet:Find(petCfgId):Quality()
        ---@type UIPossiblePetCompData
        local data = {
            cfgId = petCfgId,
            quality = quality,
        }

        local isContain = false
        for _, v in pairs(sortData) do
            if v.cfgId == petCfgId then
                isContain = true
                break
            end
        end
        if not isContain then
            table.insert(sortData,data)
        end
    end

    --按品质排序
    table.sort(sortData,function(a,b)
        return a.quality > b.quality
    end)

    return sortData
end

function BaseShopItemDetailDataProvider:UseSmallItemIcon(use)
    if use == nil then
        return self._useSmallItemIcon
    end
    self._useSmallItemIcon = use
end

function BaseShopItemDetailDataProvider:UseCommonDiscountTag(use)
    if use == nil then
        return self._useCommonDiscountTag
    end
    self._useCommonDiscountTag = use
end

function BaseShopItemDetailDataProvider:UseGiftBase(use)
    if use == nil then
        return self._useGiftBase
    end
    self._useGiftBase = use
end

function BaseShopItemDetailDataProvider:UseStoreBase(use)
    if use == nil then
        return self._useStoreBase
    end
    self._useStoreBase = use
end

function BaseShopItemDetailDataProvider:ShowSlider(show)
    if show == nil then
        return self._showSlider
    end
    self._showSlider = show
end

function BaseShopItemDetailDataProvider:ShowCoins(show)
    if show == nil then
        return self._showCoins
    end
    self._showCoins = show
end

function BaseShopItemDetailDataProvider:ShowMoney(show)
    if show == nil then
        return self._showMoney
    end
    self._showMoney = show
end

function BaseShopItemDetailDataProvider:ShowBtnIcon(show)
    if show == nil then
        return self._showBtnIcon
    end
    self._showBtnIcon = show
end

function BaseShopItemDetailDataProvider:BtnShowMask(mask)
    if mask == nil then
        return self._btnShowMask
    end
    self._btnShowMask = mask
end

---@param callback fun(...)
function BaseShopItemDetailDataProvider:OnBuyClick(callback, ...)
    if callback == nil then
        self._onBuyClick(...)
        return
    end
    self._onBuyClick = callback
end

return BaseShopItemDetailDataProvider