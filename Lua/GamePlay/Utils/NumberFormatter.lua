---@class NumberFormatter
local NumberFormatter = class('NumberFormatter')

---@private
---separate thousands
---@field amount number
---@return string
function NumberFormatter.comma_value(amount)
    local formatted = amount
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
        break
        end
    end
    return formatted
end

---@public
---@field num number
---@return string
function NumberFormatter.Normal(num)
    if not num then return '' end
    --Floor to int
    num = math.floor(num)    
    return NumberFormatter.comma_value(num)
end

local AbbrValue = {
    1000000000000000000, --E
    1000000000000000, --P
    1000000000000, --T
    1000000000, --G
    1000000, --M
    1000, --K
}
local AbbrStr = {'E','P','T','G','M','K'}

---@public
---Number Abbreviation,
---K=1,000
---M=1,000 K
---G=1,000 M
---T=1,000 G
---P=1,000 T
---E=1,000 P
---Max=9.2E
function NumberFormatter.NumberAbbr(num, stripPointZero, withSign)
    if num == nil then
        return ''
    end
    
    local pNum = num >= 0
    num = math.abs(num)
    if num < 1000 then
        if withSign then
            if stripPointZero then
                return string.format(pNum and "+%.0f" or "-%.0f", num)
            else
                return pNum and ("+" .. tostring(num)) or tostring(-num)
            end
        end
        if stripPointZero then
            return string.format(pNum and "%.0f" or "-%.0f", num)
        else
            return pNum and tostring(num) or tostring(-num)
        end
    end
    local formatNum = ''
    for i = 1, 6 do
        if num >= AbbrValue[i] then
            num = num / AbbrValue[i]
            --keep one significant digit 
            num = math.floor(num*10 + 0.5) / 10.0
            if stripPointZero then
                local v = math.floor(num * 10) % 10
                if v == 0 then
                    if withSign then
                        formatNum = string.format(pNum and '+%.0f%s' or '-%.0f%s',num,AbbrStr[i])
                    else
                        formatNum = string.format(pNum and '%.0f%s' or '-%.0f%s',num,AbbrStr[i])
                    end
                    break
                end
            end
            if withSign then
                formatNum = string.format(pNum and '+%0.1f%s' or '-%0.1f%s',num,AbbrStr[i])
            else
                formatNum = string.format(pNum and '%0.1f%s' or '-%0.1f%s',num,AbbrStr[i])
            end
            break
        end
    end
    return formatNum
end

---@public
---Convert to Percent
function NumberFormatter.Percent(num)
    num = math.floor( num * 1000 + 0.5 )
    if math.abs(num) % 10 > 0 then
        return string.format('%0.1f%%',num / 10.0)
    else
        return string.format('%d%%',num / 10.0)
    end
end

function NumberFormatter.PercentKeep2(num)
    num = math.floor( num * 10000 + 0.5 )
    return string.format('%0.2f%%',num / 100.0)
end

function NumberFormatter.WithSign(num, decimal)
    if num == nil then return string.Empty end

    decimal = decimal or 0
    local formatter = num >= 0 and string.format("+%%.%df", decimal) or string.format("%%.%df", decimal)
    return string.format(formatter, num)
end

function NumberFormatter.PercentWithSignSymbol(num, decimal, removeTrailingZeros)
    if num == nil then return string.Empty end

    decimal = decimal or 0
    num = math.floor( num * 10000 + 0.5 ) / 100
    local formatter = num >= 0 and string.format("+%%.%df%%%%", decimal) or string.format("%%.%df%%%%", decimal)
    if removeTrailingZeros then
        return NumberFormatter.RemoveTrailingZeros(string.format(formatter, num))
    else
        return string.format(formatter, num)
    end
end

function NumberFormatter.RemoveTrailingZeros(percentStr)
    if type(percentStr) ~= "string" then return percentStr end

    local nstr = percentStr:gsub("%%", "")
    local postFix = percentStr ~= nstr and "%" or ""
    nstr = nstr:gsub("%.0*$", "")
    nstr = nstr:gsub("(%..-[^0])0+$", "%1")
    nstr = nstr:gsub("%.$", "")
    return string.format("%s%s", nstr, postFix)
end

---@public
function NumberFormatter.DoTest()
    NumberFormatter.Percent(0)
    NumberFormatter.Percent(0.1)
    NumberFormatter.Percent(0.234123431)
    NumberFormatter.Percent(3)
    NumberFormatter.Percent(-0.11)
    NumberFormatter.Percent(-0.4422123)
    NumberFormatter.Percent(-5)
end

return NumberFormatter
