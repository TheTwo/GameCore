local BaseTableViewProCell = require('BaseTableViewProCell')
local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIHelper = require('UIHelper')
local NodeColumnCell = class('NodeColumnCell',BaseTableViewProCell)

function NodeColumnCell:OnCreate(param)
    self.root = self:GameObject("")
    self.btnEmpty = self:Button('p_btn_empty', Delegate.GetOrCreate(self, self.OnBtnEmptyClick))
    self.compNotes = self:LuaBaseComponent('p_btn_notes')
    self.compLine = self:LuaBaseComponent('p_line')

    self.goNotes1 = self:GameObject('p_notes_1')
    self.goNotes2 = self:GameObject('p_notes_2')
    self.goNotes3 = self:GameObject('p_notes_3')
    self.goNotes4 = self:GameObject('p_notes_4')
    self.goNotes5 = self:GameObject('p_notes_5')
    self.goNotes6 = self:GameObject('p_notes_6')
    self.goNotes7 = self:GameObject('p_notes_7')
    self.goLineRoot = self:GameObject('p_line_root')

    self.notes = {self.goNotes1, self.goNotes2, self.goNotes3, self.goNotes4, self.goNotes5, self.goNotes6, self.goNotes7}
    self.compNotes.gameObject:SetActive(false)
    self.compLine.gameObject:SetActive(false)


    self.noteChilds = {}
    for index, note in ipairs(self.notes) do
        local childCount = note.transform.childCount
        for i = childCount - 1, 0, -1 do
            local child = note.transform:GetChild(i)
            local comp = child:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
            self.noteChilds[index] = comp
            comp.gameObject:SetActive(false)
        end
    end

    self.lineNoteChilds = {}
    local lineCount = self.goLineRoot.transform.childCount
    for i = lineCount - 1, 0, -1 do
        local child = self.goLineRoot.transform:GetChild(i)
        local comp = child:GetComponent(typeof(CS.DragonReborn.UI.LuaBaseComponent))
        self.lineNoteChilds[#self.lineNoteChilds + 1] = comp
        comp.gameObject:SetActive(false)
    end


end

function NodeColumnCell:OnBtnEmptyClick()
    g_Game.EventManager:TriggerEvent(EventConst.ON_CLICK_EMPTY)
    g_Game.EventManager:TriggerEvent(EventConst.ON_CLICK_TECH_NODE, nil)
end



function NodeColumnCell:OnFeedData(index)
    self.x = index % 10000
    self.stageId = (index - self.x) / 10000
    self.techList = self:GetTechByX()
    for _, techId in pairs(self.techList) do
        local techCfg = ConfigRefer.CityTechTypes:Find(techId)
        local comp
        if self.noteChilds[techCfg:Y()] then
            comp = self.noteChilds[techCfg:Y()]
        else
            comp = UIHelper.DuplicateUIComponent(self.compNotes, self.notes[techCfg:Y()].transform)
            self.noteChilds[techCfg:Y()] = comp
        end
        comp.gameObject.transform.localPosition = CS.UnityEngine.Vector3(0, 0, 0)
        comp.gameObject:SetActive(true)
        comp:FeedData(techId)
    end
    self:ShowLines()
end

function NodeColumnCell:GetTechByX()
    local techList = ModuleRefer.ScienceModule:GetTechListByStage(self.stageId)
    local list = {}
    for _, tech in pairs(techList) do
        if self.x == ConfigRefer.CityTechTypes:Find(tech):X() then
            list[#list + 1] = tech
        end
    end
    return list
end

function NodeColumnCell:ShowLines()
    local cityTechTypes = ConfigRefer.CityTechTypes
    local scienceModule = ModuleRefer.ScienceModule
    local x = self.root.transform.sizeDelta.x
    local lineCount = 1

    for _, techId in pairs(self.techList) do
        local techCfg = cityTechTypes:Find(techId)
        local techY = techCfg:Y()
        local techX = techCfg:X()
        for i = 1, techCfg:ChildTechLength() do
            local childTechId = techCfg:ChildTech(i)
            local childTechCfg = cityTechTypes:Find(childTechId)
            local childY = childTechCfg:Y()
            local childX = childTechCfg:X()
            local isLightLine = scienceModule:CheckIsResearched(techId) --and scienceModule:CheckIsResearched(childTechId)
            local lineHightX = 0
            if childX > techX + 1 then
                local offsetX = childX - techX - 1
                local line
                if self.lineNoteChilds[lineCount] then
                    line = self.lineNoteChilds[lineCount]
                else
                    line = UIHelper.DuplicateUIComponent(self.compLine, self.goLineRoot.transform)
                    self.lineNoteChilds[lineCount] = line
                end
                lineCount = lineCount + 1
                line.gameObject:SetActive(true)
                line:FeedData(isLightLine)
                local hight = offsetX * self.compNotes.gameObject.transform.sizeDelta.x
                line.gameObject.transform.sizeDelta = CS.UnityEngine.Vector2(5, hight)
                line.gameObject.transform.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, 90)
                local lineX = x + hight / 2
                local lineY = self.notes[techY].transform.localPosition.y
                line.gameObject.transform.localPosition = CS.UnityEngine.Vector3(lineX, lineY, 0)
                lineHightX = hight
            end
            if techY ~= childY then
                local line
                if self.lineNoteChilds[lineCount] then
                    line = self.lineNoteChilds[lineCount]
                else
                    line = UIHelper.DuplicateUIComponent(self.compLine, self.goLineRoot.transform)
                    self.lineNoteChilds[lineCount] = line
                end
                lineCount = lineCount + 1
                line.gameObject:SetActive(true)
                line:FeedData(isLightLine)
                local hight = math.abs(self.notes[techY].transform.localPosition.y - self.notes[childY].transform.localPosition.y)
                line.gameObject.transform.sizeDelta = CS.UnityEngine.Vector2(5, hight)
                local y = (self.notes[techY].transform.localPosition.y + self.notes[childY].transform.localPosition.y) / 2
                line.gameObject.transform.localPosition = CS.UnityEngine.Vector3(x + lineHightX, y, 0)
            end
        end
    end
end

return NodeColumnCell
