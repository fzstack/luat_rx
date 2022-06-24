local class = require 'middleclass'
require 'lang'

local ioc = require 'ioc'

local RxState = require 'rxState'
local RxContext = require'rxContext'
local RxBoundContext = require 'rxBoundContext'

--- @class RxComputed : RxState
local RxComputed = RxState:subclass('RxComputed')

--- @param origin function
function RxComputed:initialize(outer, origin, name)
    self.class.super.initialize(self, nil, name)
    self._outer = outer --- @private
    self._origin = origin --- @private
    self.boundCtx = self.ctx:bind(self)
    self._dirty = true --- @private
    self._inited = false

    --- @private
    --- @type table<RxState, boolean>
    self._watches = {}
    setmetatable(self._watches, {_mode = 'k'})

    --- @private
    self._changed_state = {} --- @type RxState[]
    setmetatable(self._changed_state, {_mode = 'k'})

    self.boundCtx:enqueue()
end

function RxComputed:wrapper()
    local outer = self
    return function(self, ...)
        return outer.value
    end
end

--- @param source RxState
function RxComputed:notify(source)
    self._dirty = true
    print('computed', self.name, 'been notified by', source.name)
    if source.class == RxState then
        if self._changed_state[source] == nil then
            -- print('computed', self.name, 'add', source.name, 'to _changed_state')
            self._changed_state[source] = true
        end
    end

    self.boundCtx:enqueue()
    self:notifyDeps()
end

function RxComputed:watch(target)
    if self._watches[target] == nil then
        self._watches[target] = true
    end
end


-- function RxComputed:isDirty()
--     return self._dirty
-- end

function RxComputed:update()
    -- 如果自己的任何一个依赖是dirty，就在之后再更新
    -- print('updating', self.name)
    if not self._dirty then
        return false
    end
    print('computed', self.name, 'is dirty')
    local result = self.boundCtx:record(function() -- 用于更新依赖列表

        local anyChanged = false

        if not self._inited then
            self._inited = true
            anyChanged = true
        else
            -- TODO 收集观察对象，并判断是否改变了
            for target, _ in pairs(self._watches) do
                if self._changed_state[target] ~= nil then
                    anyChanged = true
                    break
                end
                if target.class == RxComputed then
                    local isModified = self.ctx:isModified(target)
                    local targetUpdateResult = target:update()
                    local isChanged = isModified or targetUpdateResult
                    print(self.name, 'testing', target.name, ', isModified:', isModified, ', targetUpdateResult:', targetUpdateResult)
                    if isChanged then
                        anyChanged = true
                    end
                    
                end
            end
            for k, _ in pairs(self._changed_state) do
                self._changed_state[k] = nil
            end
        end
        
        if not anyChanged then return false end
        print('computed', self.name, 'need update')

        local value = self._origin(self._outer)
        print('computed', self.name, '->', value)
        if self.value == value then return false end
        self.value = value
        return true
    end)
    self._dirty = false
    return result
end

function RxComputed:get()
    if self._dirty then
        self:update()
    end
    return self.class.super.get(self)
end

function RxComputed:__tostring()
    local watchNames = {}
    for target, _ in pairs(self._watches) do
        table.insert(watchNames, target.name)
    end
    return 'computed{' .. table.concat(watchNames, ', ') .. '}'
end

return RxComputed