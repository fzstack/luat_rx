module(..., package.seeall)

require 'log'
LOG_LEVEL = log.LOGLEVEL_TRACE
LOG_TAG = 'testRx'

require 'test'
local class = require 'middleclass'
local Rx = require 'rx'
local RxContext = require 'rxContext'
local ioc = require 'ioc'

function basic() -- 一个computed，依赖一个state
    --- @class RxBasicTest : Rx
    local RxBasicTest = Rx:subclass('RxBasicTest')

    function RxBasicTest:initialize()
        self.testf = 233
    end

    function RxBasicTest:hi()
    local v = self.testf
        print('hi is called, with testf=', v)
        return 'hi ' .. tostring(v)
    end

    local re = RxBasicTest:new()
    log.debug(LOG_TAG, 'before: '.. re.hi)

    log.debug(LOG_TAG, 'no change: '.. re.hi) -- hi函数此时应该不会被执行

    re.testf = 100
    log.debug(LOG_TAG, 'after: '.. re.hi)
end

function depMultiState() -- 一个computed，依赖多个state(测试commit函数)
    --- @class RxDepMultiStateTest : Rx
    local RxDepMultiStateTest = Rx:subclass('RxDepMultiStateTest')

    function RxDepMultiStateTest:initialize()
        self.a = 1
        self.b = 2
        self.c = 3
    end

    function RxDepMultiStateTest:ab()
        return 'a + b = ' .. tostring(self.a + self.b)
    end

    function RxDepMultiStateTest:bc()
        return 'b + c = ' .. tostring(self.b + self.c)
    end

    function RxDepMultiStateTest:abc()
        return 'a + b + c = ' .. tostring(self.a + self.b + self.c)
    end

    local ctx = ioc:resolve(RxContext)
    local rx = RxDepMultiStateTest:new()

    log.debug(LOG_TAG, 'before first commit')
    ctx:commit()
    log.debug(LOG_TAG, 'after first commit')
    log.debug(LOG_TAG, 'ab: ', rx.ab, ', bc: ', rx.bc, ', abc: ', rx.abc)

    rx.a = 0 -- 应该在commit后正确更新ab和abc
    log.debug(LOG_TAG, 'before second commit')
    ctx:commit()
    log.debug(LOG_TAG, 'after second commit')
    log.debug(LOG_TAG, 'ab: ', rx.ab, ', bc: ', rx.bc, ', abc: ', rx.abc)
end

function multiRxInst() -- 同一个rx类存在多个实例
    --- @class RxMultiInstTest : Rx
    local RxMultiInstTest = Rx:subclass('RxMultiInstTest')

    function RxMultiInstTest:initialize(name)
        self.name = name
    end

    function RxMultiInstTest:text()
        return 'hi ' .. self.name
    end

    local rx1 = RxMultiInstTest:new('runar')
    local rx2 = RxMultiInstTest:new('lisa')

    test.assertEqual(rx1.text, 'hi runar')
    test.assertEqual(rx2.text, 'hi lisa')

    rx1.name = 'tom'
    test.assertEqual(rx1.text, 'hi tom')
    test.assertEqual(rx2.text, 'hi lisa')
end

function crossInstState() -- 状态在另一个对象里
    --- @class RxCrossInstStateTestSub : Rx
    local RxCrossInstStateTestSub = Rx:subclass('RxCrossInstStateTestSub')

    function RxCrossInstStateTestSub:initialize()
        self.a = 0
    end

    --- @class RxCrossInstStateTestOuter : Rx
    local RxCrossInstStateTestOuter = Rx:subclass('RxCrossInstStateTestOuter')

    function RxCrossInstStateTestOuter:initialize()
        self.s = RxCrossInstStateTestSub:new()
    end

    function RxCrossInstStateTestOuter:hi()
        return 'hi ' .. self.s.a
    end

    local rx = RxCrossInstStateTestOuter:new()
    test.assertEqual(rx.hi, 'hi 0')

    rx.s.a = 5
    test.assertEqual(rx.hi, 'hi 5')

end

-- TODO: 支持弱引用，防止内存泄漏

function depComputed() -- computed依赖另一个computed
    --- @class RxDepComputedTest : Rx
    local RxDepComputedTest = Rx:subclass('RxDepComputedTest')

    function RxDepComputedTest:initialize()
        self.a = 0
    end

    function RxDepComputedTest:b()
        return self.a + 1
    end

    function RxDepComputedTest:c()
        return self.b + 1
    end
    
    function RxDepComputedTest:d()
        return self.c + 1
    end

    local ctx = ioc:resolve(RxContext)
    local rx = RxDepComputedTest:new()

    log.debug(LOG_TAG, 'before first commit')
    ctx:commit()
    log.debug(LOG_TAG, 'after first commit')

    test.assertEqual(rx.a, 0)
    test.assertEqual(rx.b, 1)
    test.assertEqual(rx.c, 2)
    test.assertEqual(rx.d, 3)

    rx.a = 100
    log.debug(LOG_TAG, 'before second commit')
    ctx:commit()
    log.debug(LOG_TAG, 'after second commit')
    test.assertEqual(rx.a, 100)
    test.assertEqual(rx.b, 101)
    test.assertEqual(rx.c, 102)
    test.assertEqual(rx.d, 103)

    rx.a = 400
    log.debug(LOG_TAG, 'before third commit')
    ctx:commit()
    log.debug(LOG_TAG, 'after third commit')
    test.assertEqual(rx.a, 400)
    test.assertEqual(rx.c, 402)
    test.assertEqual(rx.d, 403)
    test.assertEqual(rx.b, 401)

    log.debug(LOG_TAG, 'with out commit')
    rx.a = 200
    test.assertEqual(rx.a, 200)
    test.assertEqual(rx.b, 201)
    test.assertEqual(rx.c, 202)
    test.assertEqual(rx.d, 203)
    ctx:commit()

    log.debug(LOG_TAG, 'with out commit(reverse order)')
    rx.a = 300
    test.assertEqual(rx.a, 300)
    test.assertEqual(rx.c, 302)
    test.assertEqual(rx.d, 303)
    test.assertEqual(rx.b, 301)
    ctx:commit()
end

function depComputedNState() -- computed依赖computed及state
    --- @class RxDepComputedTest : Rx
    local RxDepComputedNStateTest = Rx:subclass('RxDepComputedNStateTest')
    function RxDepComputedNStateTest:initialize()
        self.a = 1
        self.b = 2
        self.c = 3
    end

    function RxDepComputedNStateTest:pb()
        return self.b + 1
    end

    function RxDepComputedNStateTest:pc()
        return self.c + 2
    end

    function RxDepComputedNStateTest:bc()
        return self.pb + self.pc
    end

    function RxDepComputedNStateTest:abc()
        return self.a + self.bc
    end

    function RxDepComputedNStateTest:abbc()
        return self.a + self.b + self.bc
    end

    local ctx = ioc:resolve(RxContext)
    local rx = RxDepComputedNStateTest:new()

    log.debug(LOG_TAG, 'commit for init')
    ctx:commit()
    test.assertEqual(rx.a, 1)
    test.assertEqual(rx.b, 2)
    test.assertEqual(rx.c, 3)
    test.assertEqual(rx.pb, 3)
    test.assertEqual(rx.pc, 5)
    test.assertEqual(rx.bc, 8)
    test.assertEqual(rx.abc, 9)
    test.assertEqual(rx.abbc, 11)

    -- 只改变a、只更新abc
    rx.a = 3
    log.debug(LOG_TAG, 'commit for updating abc abbc')
    ctx:commit()
    test.assertEqual(rx.a, 3)
    test.assertEqual(rx.b, 2)
    test.assertEqual(rx.c, 3)
    test.assertEqual(rx.pb, 3)
    test.assertEqual(rx.pc, 5)
    test.assertEqual(rx.bc, 8)
    test.assertEqual(rx.abc, 11)
    test.assertEqual(rx.abbc, 13)

    rx.b = 3
    rx.c = 2
    log.debug(LOG_TAG, 'commit for updating pb pc bc abbc')
    ctx:commit()
    test.assertEqual(rx.a, 3)
    test.assertEqual(rx.b, 3)
    test.assertEqual(rx.c, 2)
    test.assertEqual(rx.pb, 4)
    test.assertEqual(rx.pc, 4)
    test.assertEqual(rx.bc, 8)
    test.assertEqual(rx.abc, 11)
    test.assertEqual(rx.abbc, 14)
end

function depDynamic()
    --- @class RxDepDynamicTest : Rx
    local RxDepDynamicTest = Rx:subclass('RxDepDynamicTest')
    function RxDepDynamicTest:initialize()
        self.a = 1
        self.b = 2
    end

    function RxDepDynamicTest:test()
        if self.a % 2 == 1 then
            return self.a * 2
        else
            return self.a + self.b
        end
    end

    local ctx = ioc:resolve(RxContext)
    
    log.debug(LOG_TAG, 'commit for init')
    local rx = RxDepDynamicTest:new()
    ctx:commit()
    test.assertEqual(rx.a, 1)
    test.assertEqual(rx.b, 2)
    test.assertEqual(rx.test, 2)

    
    log.debug(LOG_TAG, 'commit for just update b')
    rx.b = 3
    ctx:commit()
    test.assertEqual(rx.a, 1)
    test.assertEqual(rx.b, 3)
    test.assertEqual(rx.test, 2) 

    log.debug(LOG_TAG, 'commit for update a')
    rx.a = 2
    ctx:commit()
    test.assertEqual(rx.a, 2)
    test.assertEqual(rx.b, 3)
    test.assertEqual(rx.test, 5)

    log.debug(LOG_TAG, 'commit for update b after update a')
    rx.b = 4
    ctx:commit()
    test.assertEqual(rx.a, 2)
    test.assertEqual(rx.b, 4)
    test.assertEqual(rx.test, 6)
end