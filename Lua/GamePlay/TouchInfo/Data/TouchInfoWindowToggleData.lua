---数据说明
---@showToggle : boolean类型, 如果为true, 则剩余3个参数必须要有有效值
---@toggleImageIds : number[]类型, 每一个对应一组window对应显示的图标配置id(cfg:ArtResourceUI)
---@firstToggle : number 第一个选中的Toggle, 其值范围为[1-#toggleImageIds]
---@windowIdxGroup : number[][]类型, 每一个数组元素是一个window id数组, 对应着windowdata的值(包括主Window, 所以小心不要填入1)

---@class TouchInfoWindowToggleData
---@field new fun(showToggle:boolean, toggleImageIds:number[], firstToggle:number|nil):TouchInfoWindowToggleData
local TouchInfoWindowToggleData = sealedClass("TouchInfoWindowToggleData")

function TouchInfoWindowToggleData:ctor(showToggle, toggleImageIds, firstToggle, windowIdxGroup)
    self.showToggle = showToggle
    self.toggleImageIds = toggleImageIds
    self.firstToggle = firstToggle or 1
    self.windowIdxGroup = windowIdxGroup
end

TouchInfoWindowToggleData.Default = TouchInfoWindowToggleData.new(false)
return TouchInfoWindowToggleData