local class = require 'middleclass'

--- @class Ioc
local Ioc = class('Ioc')

function Ioc:initialize()
    self.insts = {} --- @private
end

--- @generic T
--- @param cls T
--- @return T
function Ioc:resolve(cls)
    local inst = self.insts[cls]
    if inst == nil then
        local depInsts = {}
        if cls.dependencies ~= nil then
            print(cls.name, 'HAS DEP FUNC!')
            local depClses = cls.dependencies
            for _, depCls in ipairs(depClses) do
                table.insert(depInsts, self:resolve(depCls))
            end
        end
        inst = cls:new(unpack(depInsts))
        self.insts[cls] = inst
    end
    return inst
end

return Ioc:new()