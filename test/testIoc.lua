module(..., package.seeall)

require 'log'
LOG_LEVEL = log.LOGLEVEL_TRACE
LOG_TAG = 'testIoc'

local ioc = require 'ioc'
local class = require 'middleclass'

function basic()
    local DepClass = class('DepClass') --- @class DepClass

    function DepClass:initialize()
        print('dep cls ctor!')
    end

    function DepClass:get()
        return 'hi'
    end
    
    local TestClass = class('TestClass'):include({
        dependencies = { DepClass }
    }) --- @class TestClass

    --- @param depCls DepClass
    function TestClass:initialize(depCls)
        self.depCls = depCls
        print('test cls ctor!')
    end

    function TestClass:say(name)
        return table.concat({self.depCls:get(), name}, ' ')
    end

    local c1 = ioc:resolve(TestClass)
    local c2 = ioc:resolve(TestClass)
    print(c2:say('runar'))
    test.assertEqual(c1, c2)

    local d = ioc:resolve(DepClass)
    test.assertEqual(d, c1.depCls)
end