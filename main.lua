PROJECT = 'test'
VERSION = '2.0.0'
require 'log'
LOG_LEVEL = log.LOGLEVEL_TRACE
require 'sys'
require 'test'

local Rx = require 'rx'

require 'testRx'
require "io"


sys.taskInit(function()
	test.run('testRx', {
		'depDynamic',
	})
end)

sys.init(0, 0)
sys.run()