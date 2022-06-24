local class = require 'middleclass'
require 'lang'

require 'log'
LOG_LEVEL = log.LOGLEVEL_TRACE
LOG_TAG = 'rx'

local RxState = require 'rxState'
local RxComputed = require 'rxComputed'

local magic_vars = {'__init__', '__computed__', '__state__'}

local function isClsInst(cls, inst)
    return inst ~= nil and inst.isInstanceOf ~= nil and inst:isInstanceOf(cls)
end

--- @class Rx
local Rx = class('Rx'):include({
    __index = function(self, idx)
        -- log.info(LOG_TAG, 'try get', idx)

        if idx ~= '__computed__' and idx ~= '__state__' and self.__computed__ ~= nil then
            --- @type RxComputed
            -- print('checking', idx, 'is computed?')
            local existed_computed = self.__computed__[idx]
            if isClsInst(RxComputed, existed_computed) then
                log.info(LOG_TAG, idx, 'is', tostring(existed_computed))
                return existed_computed:get()
            end
        end

        if idx ~= '__state__' and self.__state__ ~= nil then
            local existed_state = self.__state__[idx]
            if existed_state ~= nil then
                return existed_state:get()
            end
        end

        local value = rawget(self, idx)
        -- if isClsInst(RxState, value) then
        --     return value:get()
        -- end
        
        return value
    end,

    --- @param self Rx
    __newindex = function(self, idx, val)
        if idx ~= '__init__' and self.__init__ == nil then
            self.class.super.initialize(self)
        end

        -- log.info(LOG_TAG, 'try set', idx, 'to', val)

        -- table.tree(self.class.__declaredMethods, 2)
        -- 是否和computed的名字相同
        if self.__computed__ ~= nil then
            local existed_computed = self.__computed__[idx]
            -- print(existed_computed)
            assert(
                not isClsInst(RxComputed, existed_computed),
                'can not set value to computed'
            )
        end

        if idx ~= '__computed__' and idx ~= '__state__' and self.__state__~= nil then
            --- @type RxState
            local existed_state = self.__state__[idx]
            if existed_state == nil then
                log.info(LOG_TAG, 'state', idx, 'create with', val)
                existed_state = RxState:new(val, idx)
                self.__state__[idx] = existed_state
                -- rawset(self, idx, existed_state)
            else
                existed_state:update(val)
            end
        else
            rawset(self, idx, val)
        end
    end
})

function Rx:action(fn)
    
end

function Rx:initialize()
    if self.__init__ then return end
    self.__init__ = true
    self.__computed__ = {}
    self.__state__ = {}
    
    log.info(LOG_TAG, 'rx inited')
    
    -- table.tree(self)
    local sm = getmetatable(self)
    for k, v in pairs(self.class.__declaredMethods) do
        if k ~= 'initialize' then 
            log.info(LOG_TAG, 'replace', k, 'to computed')
            sm[k] = nil
            local computed = RxComputed:new(self, v, k)
            self.__computed__[k] = computed
        end
    end


end

return Rx
