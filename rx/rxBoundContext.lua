local class = require 'middleclass'

--- @class RxBoundContext
local RxBoundContext = class('RxBoundContext')

--- @param outer RxContext
--- @param computed RxComputed
function RxBoundContext:initialize(outer, computed)
    self.outer = outer
    self.computed = computed
end

function RxBoundContext:enqueue()
    self.outer:enqueue(self.computed)
end

--- @param wrapper fun():void
function RxBoundContext:record(wrapper)
    return self.outer:record(self.computed, wrapper)
end

return RxBoundContext