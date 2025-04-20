--[[

basicbrackets

Copyright (c) 2025 Tenony

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]


local lang = {}


lang.help = [[
Argument notation: 
    not required?
    specifically this value!
    repeats...
    {is a code body}
    [pattern]

This list is not generated automatically!

log ...                                             Prints out everything

while {condition} {body}                            Repeats body while condition evaulates true
if [condition {body}]... {else}?                    Executes body if preciding condition is true. If none are true and the number of arguments is odd, it executes the last body put in.
if lazy:true! [{condition} {body}]... {else}?       "lazy" set to true wont execute the other conditions after the true one
loop n {body}                                       Executes body n amount of times

or ...                                              Returns the first truthy value or the last value
and ...                                             Returns the first falsy value or the last value
not x                                               Negates x

= ...                                               Returns true if all values are equal (Wont work on tables, bodies or nan's)
+ ...                                               Sum of all numeric inputs
* ...                                               Product of all numeric inputs
- ...                                               Subtracts numeric inputs in order
/ ...                                               Divides numeric inputs in order
mod ...                                             Modulus of numeric inputs in order
join ...                                            Concatenates inputs into a string, serializes tables
len x                                               Returns length of table, string or tostring(x)
type x                                              Returns Lua type of x
normalize x                                         Converts input to a normalized value type (helper)

var varname                                         Gets variable
var varname... value...                             Sets variable(s). Requires same number of values as variable names
def name {body} arg...                              Defines a function with named arguments. Argument names will be local to the body of the definition.
delete varname...                                   Deletes listed keys from variables and definitions
clearvars                                           Removes all variables and definitions

index x i                                           Access table or string (x) at key or index
setindex x i value                                  Sets index or key of a table (x) to inputed value 

exists name?                                        Returns type of name ("function", "variable", etc) or list of all
exec body                                           Executes body
u table                                             Unpacks table

}R x                                                (INTERNAL FUNCTION) Returns the first value without processing
}L ...                                              (INTERNAL FUNCTION) Returns all values as a table

L                                                   Returns Lua variabes - {G = _G, ENV = _ENV, LUAVER = _VERSION}
lfe luafunc arg...                                  Calls a raw Lua function with arguments ("lfe" - "lua function execute")
]]

local unpack = unpack or table.unpack

local function parse(tokens)
    local result = {}
    while #tokens > 0 do
        local token = table.remove(tokens,1)
        if token == "(" then
            table.insert(result, parse(tokens))
        elseif token == ")" then
            break
        else
            table.insert(result, token)
        end
    end
    local i = 0
    while #result>=i do
        i = i+1
        local a,b,c = result[i-1],result[i],result[i+1]
        if b == "|" and type(a) == "table" and type(c) == "table" then
            table.insert(result[i+1],2,result[i-1])
            table.remove(result,i)
            table.remove(result,i-1)
            i = i-3
        end
        if b == "." and type(a) == "table" and c ~= nil then
            result[i+1] = {"index",a,c}
            table.remove(result,i)
            table.remove(result,i-1)
            i = i-3
        end
        if --[[result[1] == "}L" and]] b == ":" and (type(a) ~= "table" and a ~= nil) and c ~= nil then
            result[a] = c
            table.remove(result,i+1)
            table.remove(result,i)
            table.remove(result,i-1)
            i = i-3
        end
    end
    return result
end


function lang.deserialize(code)
    local tokens = {""}
    local isString = false
    local partOfString = {}
    local i = 1

    while i <= #code do
        local char = code:sub(i,i)

        if char == '"' then
            if isString then
                partOfString[#tokens] = true
                table.insert(tokens,"")
            end
            isString = not isString

        elseif isString and char=="\\" then
            i = i + 1
            local c = code:sub(i, i) or ""
            if c == "n" then c = "\n" end
            tokens[#tokens] = tokens[#tokens] .. c
        elseif not isString and char==" " then
            table.insert(tokens, "")
        elseif not isString and (char=="(" or char==")" or char=="." or char=="|" or char == ":") then
            table.insert(tokens,char)
            table.insert(tokens,"")
        elseif not isString and char == "[" then
            table.insert(tokens,"(")
            table.insert(tokens,"}L")
            table.insert(tokens,"")
        elseif not isString and char == "]" then
            table.insert(tokens,")")
            table.insert(tokens,"")
        elseif not isString and char == "{" then
            table.insert(tokens,"(")
            table.insert(tokens,"}R")
            table.insert(tokens,"(")
            table.insert(tokens,"")
        elseif not isString and char == "}" then
            table.insert(tokens,")")
            table.insert(tokens,")")
            table.insert(tokens,"")
        else
            tokens[#tokens] = tokens[#tokens]..char
        end
        i=i+1
    end

    local finalTokens = {}
    local isComment
    for i, v in ipairs(tokens) do
        if v == "/*" and not partOfString[i] then
            isComment = true
        elseif v == "*/" and not partOfString[i] then
            isComment = false
        elseif (v~="" or partOfString[i]) and not isComment then
            table.insert(finalTokens,v)
        end
    end

    for i, v in ipairs(finalTokens) do
        local num = tonumber(v)
        local bool = ({["true"]=true,["false"]=false})[v]
        if num then
            finalTokens[i] = num
        end
        if bool ~= nil then
            finalTokens[i] = bool
        end
    end

    return parse(finalTokens)
end




local function normalizeValueType(value) -- normalize and remove references
    local valueType = type(value)

    if valueType == "number" then
        return (value ~= value and 0 or value)+0 -- NaN check
    elseif valueType == "string" then
        local parsedNumber = tonumber(value)
        return parsedNumber or (value.."")
    elseif valueType == "boolean" then
        return value and true or false
    elseif valueType == "table" then
        return value
    end

    return 0
end



local ignore = {["}R"]=true}
function lang.run(code,data)
    if type(code)~="table" then return code end
    local variables,definitioninputs,functions = lang.variables,lang.definitioninputs,lang.functions
    local inputs = {}
    local name;
    local indexbreak = 1 -- tracking if the index breaks
    for k, v in pairs(code) do
        local result,shouldunpack;
        if (type(v)=="table") and not ignore[name or ""] then
            result = {lang.run(v,data)}
        else
            result = {v}
        end
        if k == 1 then
            name = result[1]
        else
            if type(k) == "number" then
                if indexbreak then
                    if k == indexbreak+1 then
                        for k, v in pairs(result) do
                            inputs[indexbreak] = v
                            indexbreak = indexbreak+1
                        end
                    else
                        inputs[k] = result[1]
                        indexbreak = false
                    end
                end
            else
                inputs[k] = result[1]
            end
        end
    end
    if functions[name] then return functions[name](inputs,data) end
    if definitioninputs[name] and variables[name] then
        local h = {}
        for k, v in pairs(definitioninputs[name]) do
            local t = type(variables[v]) --removing potential references
            if t=="boolean" then
                h[v] = not not variables[v]
            elseif t=="number" then
                h[v] = variables[v]+0
            elseif t=="string" then
                h[v] = variables[v]..""
            end
            variables[v] = inputs[k]
        end
        local r = {lang.run(variables[name],data or "")}
        for k, v in pairs(h) do
            variables[k] = v
        end
        return unpack(r)
    end
    if variables[name] then return variables[name] end
end












lang.definitioninputs = {}
lang.variables = {PRINTLOGS=true}
lang.functions = {
    log = function(inputs,data)
        local t = {}
        for k, v in pairs(inputs) do
            if type(v) == "string" then
                t[k] = v
            else
                t[k] = lang.serializer(v)
            end
        end
        if lang.variables.PRINTLOGS then
            print(unpack(t))
        end
    end,
    ["while"] = function(inputs,data)
        while lang.run(inputs[1],data) do
            lang.run(inputs[2],data)
        end
    end,
    ["if"] = function(inputs,data)
        local l = math.floor(#inputs/2)*2
        if inputs.lazy then
            for i = 2, l, 2 do
                if lang.run(inputs[i-1]) then
                    return lang.run(inputs[i],data)
                end
            end
            if inputs[l+1] and lang.run(inputs[l+1]) then
                return lang.run(inputs[l+1],data)
            end
        else
            for i = 2, l, 2 do
                if inputs[i-1] then
                    return lang.run(inputs[i],data)
                end
            end
            if inputs[l+1] then
                return lang.run(inputs[l+1],data)
            end
        end
    end,
    loop = function(inputs,data)
        for i = 1, inputs[1] do
            lang.run(inputs[2],data)
        end
    end,

    ["or"] = function(inputs)
        for k, v in pairs(inputs) do
            if v then
                return v
            end
        end
        return inputs[#inputs]
    end,
    ["and"] = function(inputs)
        for k, v in ipairs(inputs) do
            if not v then
                return v
            end
        end
        return inputs[#inputs]
    end,
    ["not"] = function(inputs)
        return not inputs[1]
    end,


    ["="] = function(inputs)
        for k, v in pairs(inputs) do
            if inputs[1]~=v then return false end
        end
        return true
    end,
    ["+"] = function(inputs)
        local result = 0
        for k, v in pairs(inputs) do
            if type(v) == "number" then
                result = result+v
            end
        end
        return result
    end,
    ["*"] = function(inputs)
        local result
        for k, v in pairs(inputs) do
            if type(v) == "number" then
                if not result then result = v+0
                else result = result*v end
            end
        end
        return result
    end,
    ["-"] = function(inputs)
        local result
        for k, v in pairs(inputs) do
            if type(v) == "number" then
                if not result then result = v+0
                else result = result-v end
            end
        end
        return result
    end,
    ["/"] = function(inputs)
        local result
        for k, v in pairs(inputs) do
            if type(v) == "number" then
                if not result then result = v+0
                else result = result/v end
            end
        end
        return result
    end,
    ["mod"] = function(inputs)
        local result
        for k, v in pairs(inputs) do
            if type(v) == "number" then
                if not result then result = v+0
                else result = result%v end
            end
        end
        return result
    end,
    ["join"] = function(inputs)
        local result = ""
        for k, v in pairs(inputs) do
            result = result..(type(v)=="table" and lang.serializer(v,{newline="", indent=""}) or tostring(v))
        end
        return result
    end,
    len = function(inputs)
        local t = type(inputs[1])
        if t == "string" or t == "table" then
            return #inputs[1]
        else
            return #(tostring(inputs[1]))
        end
    end,
    type = function(inputs)
        return type(inputs[1])
    end,
    normalize = function(inputs)
        return normalizeValueType(inputs[1])
    end,


    index = function(inputs)
        if type(inputs[1]) == "table" then
            return inputs[1][inputs[2]]
        elseif type(inputs[1]) == "string" and type(inputs[2]) == "number" then
            return inputs[1]:sub(inputs[2],inputs[2])
        end
    end,
    setindex = function(inputs)
        if type(inputs[1]) == "table" then
            inputs[1][inputs[2]] = inputs[3]
            return inputs[1]
        end
    end,


    var = function(inputs)
        if inputs[2] == nil then
            return lang.variables[inputs[1]]
        else
            local l = math.floor(#inputs/2)
            for i = 1, l do
                lang.variables[inputs[i]] = inputs[i+l]
            end
        end
    end,
    def = function(inputs)
        lang.variables[inputs[1]] = inputs[2]
        lang.definitioninputs[inputs[1]] = {}
        for k, v in pairs(inputs) do
            if k>2 then
                table.insert(lang.definitioninputs[inputs[1]],v)
            end
        end
    end,
    delete = function(inputs)
        for k, v in pairs(inputs) do            
            lang.definitioninputs[k] = nil
            lang.variables[k] = nil
        end
    end,
    clearvars = function()
        lang.definitioninputs = {}
        lang.variables = {}
    end,


    exists = function(inputs)
        if not inputs[1] then
            local t = {}
            for k, v in pairs(lang.functions) do
                table.insert(t,k)
            end
            for k, v in pairs(lang.variables) do
                table.insert(t,k)
            end
            return t
        elseif type(inputs[1]) == "string" then
            return 
                (lang.functions[inputs[1]] and "function") or
                (lang.definitioninputs[inputs[1]] and "definition") or
                (lang.variables[inputs[1]] and "variable") or false
        end
    end,
    exec = function(inputs,data)
        return lang.run(inputs[1]),data
    end,
    u = function(inputs) return unpack(inputs[1]) end,

    ["}R"] = function(inputs) return inputs[1] end,
    ["}L"] = function(inputs) return inputs end,


    
    help = function()
        lang.functions.log({lang.help..""})
    end,
    lfe = function(inputs)
        return inputs[1](unpack(inputs,2))
    end,
    L = function()
        return {G=_G,ENV=_ENV,LUAVER=_VERSION}
    end
}




return lang