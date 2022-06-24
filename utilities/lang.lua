module(..., package.seeall)

function string.starts(String, Start)
    return string.sub(String,1,string.len(Start))==Start
end

function string.split_by_chunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
    end
    return s
end

function enum(tbl)
    for i = 1, #tbl do
        local v = tbl[i]
        tbl[v] = i
    end

    return tbl
end

local function makeIndent(indent)
    s = ''
    for i=1,indent do
        s = s .. '    '
    end
    return s
end

function table.contains(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function table.tree(obj, max, indent)
    local nextMax
    if max == nil then
        nextMax = nil
    else
        if max <= 0 then return end
        nextMax = max - 1
    end
    if indent == nil then 
        indent = 0
    end
    for k, v in pairs(obj) do
        print(makeIndent(indent) .. tostring(k) .. ' | ' .. type(v) .. ' | ' .. tostring(v))
        if type(v) == 'table' then
            table.tree(v, nextMax, indent + 1)
        end
    end

end

function switch(sels, cond, ...)
    local found = sels[cond]
    if found ~= nil then
        return found(...)
    end
end

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function not_impl()
    assert(false, 'not implemented')
end