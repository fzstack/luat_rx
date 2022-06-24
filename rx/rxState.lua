local class = require 'middleclass'
local ioc = require 'ioc'

local RxContext = require'rxContext'

--- @class RxState
local RxState = class('RxState')


function RxState:initialize(value, name)
    self.value = value ---@protected
    self.ctx = ioc:resolve(RxContext)
    self.name = name
    --- @private
    --- @type RxComputed[]
    self._deps = {}
    setmetatable(self._deps, {_mode = 'k'})
end

--- @param dep RxComputed
function RxState:addDep(dep)
    if self._deps[dep] == nil then
        self._deps[dep] = true
        dep:watch(self)
    end
end

function RxState:update(value)
    if self.value == value then return end
    self.value = value
    self:notifyDeps()
end

function RxState:notifyDeps()
    for dep, _ in pairs(self._deps) do
        dep:notify(self)
    end
end

function RxState:get()
    --- 将ctx的top添加到依赖里
    local dependency = self.ctx:getDependency()
    if dependency ~= nil then
        self:addDep(dependency)
    end
    return self.value
end


return RxState
