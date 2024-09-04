local Delegate = require('Delegate')
local rapidJson = require("rapidjson")
local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local ProtocolId = require('ProtocolId')
local ConfigRefer = require('ConfigRefer')
local PrePayParameter = require("PrePayParameter")
local FPCoinPayParameter = require('FPCoinPayParameter')
local EventConst = require('EventConst')

--- ProductData举例
-- {
--     "amount_fen": 99,
--     "amount": "0.99",
--     "product_id": "com.kingsgroup.ssr.1usd",
--     "price": "USD0.99",
--     "currency": "USD",
--     "channel_product_id": "com.kingsgroup.1usd.ssr_gp"
-- }
--- PayPlatform.csv 是价目档位表
--- PayGoods.csv 是商品表

---@class ProductData
---@field amount_fen number 金额，分
---@field amount number 金额，元
---@field product_id string 游戏内档位Id
---@field channel_product_id string 渠道的档位Id
---@field price string 展示价格
---@field currency string 货币

---@class PayModule
local PayModule = class('PayModule', BaseModule)

function PayModule:OnRegister()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PayResult, Delegate.GetOrCreate(self, self.PushPayResult))
    g_Game.ServiceManager:AddResponseCallback(PrePayParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPrePayCallback))
    g_Game.ServiceManager:AddResponseCallback(FPCoinPayParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFPCoinPayCallback))
end

function PayModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PayResult, Delegate.GetOrCreate(self, self.PushPayResult))
    g_Game.ServiceManager:RemoveResponseCallback(PrePayParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPrePayCallback))
    g_Game.ServiceManager:RemoveResponseCallback(FPCoinPayParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFPCoinPayCallback))
end

--- 支付模块初始化
function PayModule:Initialize()
    if USE_FPXSDK then
        ModuleRefer.FPXSDKModule:GetProductsInfo(Delegate.GetOrCreate(self, self.OnGetLocalProductsInfoCallback))
    else
        self:InitializeDefaultProductList()
    end
end

--- 处理本地化的商品数据 (来源是渠道商店, 如GooglePlay)
function PayModule:OnGetLocalProductsInfoCallback(b, list)
    if b then
        g_Logger.Log('成功获取到本地化商品列表: %s', rapidJson.encode(list))
        self.localProductMap = {}
        for _, data in ipairs(list) do
            ---@type ProductData
            local productData = data
            local productId = productData.product_id
            self.localProductMap[productId] = data
        end
    end

    -- 初始化默认配置，防止报错
    self:InitializeDefaultProductList()
end

--- 初始化默认商品配置(来源是配置表, 此时sdk没有成功初始化)
function PayModule:InitializeDefaultProductList()
    self.defaultProductMap = {}

    for i, v in ConfigRefer.PayPlatform:ipairs() do
        ---@type ProductData
        local productData = {}
        productData.amount = math.float02(v:Price())
        productData.amount_fen = math.floor(v:Price() * 100)
        productData.product_id = v:FPXProductId()
        productData.channel_product_id = v:ChannelProductId()
        productData.currency = v:Currency()
        productData.price = string.format('%s %s', productData.currency, productData.amount)
        self.defaultProductMap[v:FPXProductId()] = productData
    end
end

--- 通过FPXProductId获取本地化商品信息
---@param fpxProductId string
---@return ProductData
function PayModule:GetProductData(fpxProductId)
    if table.ContainsKey(self.localProductMap, fpxProductId) then
        return self.localProductMap[fpxProductId]
    end

    return self:GetDefaultProductData(fpxProductId)
end

--- 通过FPXProductId获取默认商品信息
---@param fpxProductId string
---@return ProductData
function PayModule:GetDefaultProductData(fpxProductId)
    if table.ContainsKey(self.defaultProductMap, fpxProductId) then
        return self.defaultProductMap[fpxProductId]
    end

    g_Logger.Error('GetDefaultProductData %s failed', fpxProductId)
    return nil
end

--- 趣加币购买PayGoods表的商品
--- 传PayGoods.csv表的Id字段
---@param goodsId number
---@param chooseItems table<number, number>
function PayModule:BuyGoodsWithFpxDiamond(goodsId, chooseItems)
    local goodsConfig = ConfigRefer.PayGoods:Find(goodsId)
    if not goodsConfig then
        g_Logger.Error('趣加币支付异常终止: PayGoods.csv表中没有找到%s', goodsId)
        return
    end

    local payPlatformConfig = ConfigRefer.PayPlatform:Find(goodsConfig:PayPlatformId())
    if not payPlatformConfig then
        g_Logger.Error('趣加币支付异常终止: PayGoods.csv中的%s没有找到支付档位配置')
        return
    end

    local fPCoinPayParameter = FPCoinPayParameter.new()
    fPCoinPayParameter.args.GoodsId = goodsId
    if chooseItems then
        fPCoinPayParameter.args.ChooseItemGroups:AddRange(chooseItems)
    end
    fPCoinPayParameter:Send()

    g_Logger.Log('BuyGoodsWithFpxDiamond %s FPCoinPay send', goodsId)
end

---@param isSuccess boolean
---@param response any
function PayModule:OnFPCoinPayCallback(isSuccess, response)
    if isSuccess then
        -- 通知支付成功，业务进行后续处理，如刷新页面，或刷新礼包链
        g_Logger.Log('趣加币支付成功')
        g_Game.EventManager:TriggerEvent(EventConst.PAY_SUCCESS)
    else
        g_Logger.Error('趣加币支付异常终止: 服务器拒绝')
    end
end

--- 游戏内购买PayGoods表的商品
--- 传PayGoods.csv表的Id字段
---@param goodsId number
---@param chooseItems table<number, number>
function PayModule:BuyGoods(goodsId, chooseItems)
    local goodsConfig = ConfigRefer.PayGoods:Find(goodsId)
    if not goodsConfig then
        g_Logger.Error('支付异常终止: PayGoods.csv表中没有找到%s', goodsId)
        return
    end

    local payPlatformConfig = ConfigRefer.PayPlatform:Find(goodsConfig:PayPlatformId())
    if not payPlatformConfig then
        g_Logger.Error('支付异常终止: PayGoods.csv中的%s没有找到支付档位配置')
        return
    end

    --- 先跟服务器预先通信，提前判断是否可以购买
    local prePayParameter = PrePayParameter.new()
    prePayParameter.args.Param.IsTestPay = self:IsTestPay()
    prePayParameter.args.Param.FPXProductId = payPlatformConfig:FPXProductId()
    prePayParameter.args.Param.GoodsId = goodsId
    if chooseItems then
        prePayParameter.args.Param.ChooseItems:AddRange(chooseItems)
    end
    prePayParameter:Send()

    g_Logger.Log('BuyGoods %s PrePay send', goodsId)

    require('UIHelper').AddFullScreenLock(30)
end

---@param isSuccess boolean
---@param response any
function PayModule:OnPrePayCallback(isSuccess, response)
    if isSuccess then
        ---@type wrpc.PrePayResult
        local result = response.Result
        if self:IsTestPay() then
            -- 测试支付流程到此结束
            require('UIHelper').RemoveFullScreenLock()
            g_Logger.Log('支付正常结束: Buy Goods %s end by TestPay', rapidJson.encode(result))
            return
        end

        -- SDK支付流程开始
        local goodsId = result.GoodsId
        local extreData = result.ExtraData    -- 透传参数，给后端用
        local goodsConfig = ConfigRefer.PayGoods:Find(goodsId)
        local payPlatformConfig = ConfigRefer.PayPlatform:Find(goodsConfig:PayPlatformId())
        local productData = self:GetProductData(payPlatformConfig:FPXProductId())
        if not productData then
            g_Logger.Error('支付异常终止: 没有拿到商店里的商品数据，也没有拿到本地默认的商品数据')
            require('UIHelper').RemoveFullScreenLock()
            return
        end

        local FPXKey = CS.FunPlus.SDK.FPX.FPXKey
        local paymentInfo = {}
        paymentInfo[FPXKey.PRICE] = productData.amount
        paymentInfo[FPXKey.PRODUCT_ID] = productData.product_id
        paymentInfo[FPXKey.PRODUCT_NAME] = goodsConfig:Name()
        paymentInfo[FPXKey.PRODUCT_DESC] = goodsConfig:Desc()
        paymentInfo[FPXKey.PAY_EXTRA] = extreData
        ModuleRefer.FPXSDKModule:Pay(paymentInfo, function(b) 
            if b then
                ModuleRefer.FPXSDKModule:TrackPaymentSuccess('in_app_purchase_new', productData)
                g_Logger.Log('支付成功: SDK支付成功, 等待服务器推送支付结果')
            else
                g_Logger.Error('支付异常终止: SDK支付失败')
            end
            require('UIHelper').RemoveFullScreenLock()
        end)
    else
        g_Logger.Error('支付异常终止: 服务器拒绝')
        require('UIHelper').RemoveFullScreenLock()
    end
end

--- 是否走测试支付流程
--- 不带sdk, 走测试支付
--- 带sdk, 通过GM工具打开设置测试支付开关
--- 最终能否使用测试支付, 后端有最终决定权
function PayModule:IsTestPay()
    if not USE_FPXSDK then
        return true
    end

    if g_Game.PlayerPrefsEx:GetInt("GMTestPay") == 1 then
        return true
    end

    return false
end

--- 游戏内购买结果(GameServer返回)
function PayModule:PushPayResult(isSuccess, response)
    if isSuccess then
        -- 通知支付成功，业务进行后续处理，如刷新页面，或刷新礼包链
        g_Game.EventManager:TriggerEvent(EventConst.PAY_SUCCESS)
    end
end

--- 是否启用代币
---@return boolean
function PayModule:IsUseFunplusDiamond()
    return ModuleRefer.AppInfoModule:UseFpxDiamond() or false
end

return PayModule