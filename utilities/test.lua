module(..., package.seeall)

local class = require 'middleclass'

require 'log'
LOG_LEVEL = log.LOGLEVEL_TRACE
LOG_TAG = 'test'

---@class TestCaseContext
local TestCaseContext = class('TestCaseContext')

--- @param testCaseName string
function TestCaseContext:initialize(modName, testCaseName)
    self.modName = modName
    self.testCaseName = testCaseName
    self.errHappened = false
end

---@type TestCaseContext
local testCaseContext

--- @class TestCount
--- @field total number
--- @field passed number


local function isMagicFn(name)
    local t = {setUp=0, tearDown=0}
    return t[name] ~= nil
end

--- @param c TestCount
--- @param mod module
--- @param fname string
--- @param obj any
local function runCase(c, mod, modName, fname, obj)
    if type(obj) == "function" and not isMagicFn(fname) then
        c.total = c.total + 1
        testCaseContext = TestCaseContext:new(modName, fname)
        if mod.setUp ~= nil then
            mod.setUp()
        end
        obj()
        if mod.tearDown ~= nil then
            mod.tearDown()
        end
        if not testCaseContext.errHappened then
            c.passed = c.passed + 1
            log.debug(LOG_TAG, fname .. ': 👌')
        else
            log.warn(LOG_TAG, fname .. ': 💩')
        end
        log.debug(LOG_TAG, '--------------------------')
    end
end

--- @param modName string
--- @param fns string[]
function run(modName, fns)

    --- @type TestCount
    local c = {
        total = 0,
        passed = 0
    }

    log.debug(LOG_TAG, '==== TESTING ' .. modName .. ' ====')
    local mod = require(modName)
    if fns == nil then
        for fname, obj in pairs(mod) do
            runCase(c, mod, modName, fname, obj)
        end
    else
        for _, fname in ipairs(fns) do
            local obj = mod[fname]
            runCase(c, mod, modName, fname, obj)
        end
    end
    log.debug(LOG_TAG, '~~~~~~~~ (' .. tostring(c.passed) ..'/' .. tostring(c.total) .. ') ~~~~~~~~')
end

--- @param result boolean
--- @param msg string
function assert(result, msg)
    if not result then
        testCaseContext.errHappened = true
        if msg ~= nil then
            log.fatal(testCaseContext.modName .. '.' .. testCaseContext.testCaseName, msg)
        end
    end
end

function assertEqual(a, b)
    assert(a == b, tostring(a) .. ' is not equals to '.. tostring(b))
end