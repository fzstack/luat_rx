local class = require 'middleclass'

--- @class Stack
local Stack = class 'Stack'

function Stack:initialize()
    self.t = {}
end

function Stack:push(val)
    table.insert(self.t, val)
end

function Stack:pop()
    table.remove(self.t)
end

function Stack:isEmpty()
    return #self.t == 0
end

function Stack:top()
    return self.t[#self.t]
end

return Stack
