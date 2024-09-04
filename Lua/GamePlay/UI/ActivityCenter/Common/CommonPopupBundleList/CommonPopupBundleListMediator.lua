---scene: scene_common_popup_bundle_list
--- I'm so scared of the word 'common' that I'm going to split each kind of parameter into a separate file,
--- @see BasePopupBundleListDataProvider
local BaseUIMediator = require("BaseUIMediator")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
---@class CommonPopupBundleListMediator : BaseUIMediator
local CommonPopupBundleListMediator = class("CommonPopupBundleListMediator", BaseUIMediator)

function CommonPopupBundleListMediator:ctor()
    ---@type BasePopupBundleListCellParameter[]
    self.cells = {}
end

function CommonPopupBundleListMediator:OnCreate()
    self.p_text_reward_name = self:Text("p_text_reward_name")
    self.p_table_bundle = self:TableViewPro("p_table_bundle")
    self.child_btn_close = self:Button("child_btn_close", Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
end

---@param provider BasePopupBundleListDataProvider
function CommonPopupBundleListMediator:OnOpened(provider)
    self.provider = provider
    self.p_text_reward_name.text = provider:GetTitle()

    self:ResetUI()
end

function CommonPopupBundleListMediator:OnShow()
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.ResetUI))
end

function CommonPopupBundleListMediator:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.ResetUI))
end

function CommonPopupBundleListMediator:OnClose()
    table.clear(self.cells)
end

function CommonPopupBundleListMediator:ResetUI()
    self.p_table_bundle:Clear()
    table.clear(self.cells)
    for _, cell in ipairs(self.provider:GetCellDatas()) do
        self.p_table_bundle:AppendData(cell)
        table.insert(self.cells, cell)
    end
end

function CommonPopupBundleListMediator:OnBtnCloseClicked()
    self:CloseSelf()
end

return CommonPopupBundleListMediator