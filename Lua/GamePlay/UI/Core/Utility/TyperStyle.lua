local Delegate = require ("Delegate")

---@class RichTag
---@field new fun():RichTag
local RichTag = class("RichTag")
do
	function RichTag:ctor(leftTag, leftIdx, rightTag, rightIdx)
		self.leftTag = leftTag
		self.leftIdx = leftIdx
		self.leftEndIdx = leftIdx + #leftTag - 1
		self.rightTag = rightTag
		self.rightIdx = rightIdx
		self.rightEndIdx = rightIdx + #rightTag - 1
	end

	function RichTag:InTagContent(start, stop)
		if self.leftIdx <= self.leftEndIdx then
			if self.leftIdx <= start and stop <= self.leftEndIdx then
				return 1
			end
		end
		if self.rightIdx <= self.rightEndIdx then
			if self.rightIdx <= start and stop <= self.rightEndIdx then
				return 2
			end
		end
		return 0
	end
end

---@class TyperStyle
local TyperStyle = class("TyperStyle")
do
	---@param source string
	---@param onFill fun(text:string)
	---@param onComplete fun()
	---@param interval number
	function TyperStyle:Initialize(source, onFill, onComplete, interval)
		if interval == nil then interval = 0.01 end
		self:StopTyping()
		--source = [[<color=#fcb538>汉末建安中，庐江府小吏焦仲卿妻刘氏，</color>为仲卿母所遣，自誓不嫁。其家逼之，<color=#ff0022>乃投水而死。</color>仲卿闻之，亦自缢于庭树。时人伤之，为诗云尔。]]
		self._originalText = source
		self._onFill = onFill
		self._onComplete = onComplete
		self._complete = false
		self._interval = interval
        self._noTagWordCount = 0

		self:PostInitRichText()
	end
    
    function TyperStyle:GetRuntimeInterval()
        return self._interval * self._intervalMultiple
    end
    
    function TyperStyle:SetIntervalMultiple(value)
        self._intervalMultiple = math.clamp(value, 0.1, 10)
    end
    
    function TyperStyle:CalculateTime(interval)
        return self._noTagWordCount * interval
    end

	function TyperStyle:PostInitNonRichText()
		
	end

	function TyperStyle:PostInitRichText()
		---@type RichTag[]
		self._richTag = {}

		local stack = {}

		local index = 1
		local length = string.len(self._originalText)
		local startTag, startTagIdx = false, 0

		while index <= length do
			if string.sub(self._originalText, index, index) == '<' then
				startTag = true
				startTagIdx = index
			elseif string.sub(self._originalText, index, index) == ">" then
				if startTag then
					startTag = false
					local tagContext = string.sub(self._originalText, startTagIdx, index)
					if string.StartWith(tagContext, "</") then
						if #stack > 0 then
							local start = table.remove(stack)
							local tagPair = RichTag.new(start.context, start.index, tagContext, startTagIdx)
							table.insert(self._richTag, tagPair)
						end
					else
						table.insert(stack, {context = tagContext, index = startTagIdx})
						startTagIdx = 0
					end
				end
			end
			index = index + 1
		end

		while #stack > 0 do
			local start = table.remove(stack)
			local tagPair = RichTag.new(start.context, start.index, "", length)
			table.insert(self._richTag, tagPair)
		end

		index = 1
		local utf8len = utf8.len(self._originalText)
		local words = {}
		local noTagWord = 0
		while index <= utf8len do
			local start = utf8.offset(self._originalText, index)
			local stop = index == length and #self._originalText or (utf8.offset(self._originalText, index + 1) - 1)
			local isWord = true
			for i, v in ipairs(self._richTag) do
				local intag = v:InTagContent(start, stop)
				if intag ~= 0 then
					isWord = false
					if intag == 1 then
						v.startBefore = noTagWord + 1
					elseif intag == 2 then
						v.endAfter = noTagWord
					end
					break
				end
			end
			if isWord then
				table.insert(words, string.sub(self._originalText, start, stop))
				noTagWord = noTagWord + 1
			end
			index = index + 1
		end
        self._noTagWordCount = noTagWord
		self.sequence = {}
		for i = 1, noTagWord do
			for k, v in pairs(self._richTag) do
				if v.startBefore == i then
					table.insert(self.sequence, {isTag = true, isEnter = true, tag = v})
				end
			end
			table.insert(self.sequence, {str = words[i]})
			for k, v in pairs(self._richTag) do
				if v.endAfter == i then
					table.insert(self.sequence, {isTag = true, isEnter = false, tag = v})
				end
			end
		end
	end

	function TyperStyle:IsTypingComplete()
		return self._complete
	end

	function TyperStyle:StartTyping()
		if self._coroutine == nil then
			self._complete = false
			self._coroutine = coroutine.start(Delegate.GetOrCreate(self, self.InternalWriteText))
		end
	end

	function TyperStyle:CompleteTyping()
		if not string.IsNullOrEmpty(self._originalText) then
			if self._onFill ~= nil then
				self._onFill(self._originalText)
			end
			self._complete = true
			if self._onComplete ~= nil then
				self._onComplete()
			end
			self:StopTyping()
		end
	end

	function TyperStyle:StopTyping()
		if self._coroutine ~= nil then
			coroutine.stop(self._coroutine)
			self._coroutine = nil
		end
	end

	function TyperStyle:InternalWriteText()
		local tagStack = {}
		local curStr = ""
		local postfix
        local frameTimeLag = nil
		for i, v in ipairs(self.sequence) do
			if v.isTag then
				if v.isEnter then
					table.insert(tagStack, v.tag)
					curStr = curStr.. v.tag.leftTag
				else
					local tag = table.remove(tagStack)
                    if tag then
                        curStr = curStr.. tag.rightTag
                    end
				end
			else
				curStr = curStr..v.str
				if #tagStack > 0 then
					postfix = ""
					for i = #tagStack, 1, -1 do
						postfix = postfix..tagStack[i].rightTag
					end
				else
					postfix = ""
				end
				if self._onFill ~= nil then
					self._onFill(curStr..postfix)
				end
                if frameTimeLag == nil then
                    if self:GetRuntimeInterval() < CS.UnityEngine.Time.deltaTime then
                        frameTimeLag = self:GetRuntimeInterval()
                        goto ForFameTimeLag
                    end
                else
                    frameTimeLag = frameTimeLag + self:GetRuntimeInterval()
                    if frameTimeLag > CS.UnityEngine.Time.deltaTime then
                        frameTimeLag = nil
                        coroutine.wait(0.00001)
                    end
                    goto ForFameTimeLag
                end
                coroutine.wait(self:GetRuntimeInterval())
			end
            ::ForFameTimeLag::
		end
		self._complete = true
		if self._onComplete ~= nil then
			self._onComplete()
		end
	end

	function TyperStyle:ctor()
		self._colorWraps = {}
		self._textWraps = {}
		self._builder = ""
		self._originalText = ""
		self._complete = 0
		self._coroutine = nil
		self._onFill = nil
		self._onComplete = nil
		self._interval = 0
        self._noTagWordCount = 0
        self._intervalMultiple = 1.0
	end
end

return TyperStyle