local class = require 'middleclass'
require 'lang'

local Stack = require 'stack'

local RxBoundContext = require 'rxBoundContext'

--- @class RxContext
local RxContext = class 'RxContext'

function RxContext:initialize()
    self.queue = {} --- @type RxComputed[]
    setmetatable(self.queue, {_mode = 'k'})

    -- top在最后边
    self.depStack = Stack:new() --- @private

    self._commiting = false --- @private
    self._modified_computed = {} --- @type RxComputed[]
    setmetatable(self._modified_computed, {_mode = 'k'})
end

--- @param computed RxComputed
function RxContext:bind(computed)
    return RxBoundContext:new(self, computed)
end

--- @param computed RxComputed
function RxContext:enqueue(computed)
    if self.queue[computed] == nil then
        self.queue[computed] = true
    end
end

--- @param computed RxComputed
--- @param wrapper fun():void
function RxContext:record(computed, wrapper)
    self.depStack:push(computed)
    local result = wrapper()
    if result then
        
        if self._modified_computed[computed] == nil then
            print('computed', computed.name, 'is modified!')
            self._modified_computed[computed] = true
        end
    end
    self.depStack:pop()
    return result
end

--- @param computed RxComputed
function RxContext:isModified(computed)
    return self._modified_computed[computed] ~= nil
end

--- @return RxComputed
function RxContext:getDependency()
    if not self.depStack:isEmpty() then
        return self.depStack:top()
    end
end

function RxContext:commit()
    -- 更新queue里的computed
    -- 这些computed也可能互相依赖

    -- 比如A依赖C
    -- C被更新之后A也需要更新
    -- 假如这时候队列里是A先要更新

    -- 那么A就要等自己的依赖全更新好之后再更新自己
    self._commiting = true
    for computed, _ in pairs(self.queue) do
        computed:update()
    end
    self._commiting = false
    for k, _ in pairs(self.queue) do
        self.queue[k] = nil
    end
    for k, _ in pairs(self._modified_computed) do
        self._modified_computed[k] = nil
    end
end

return RxContext