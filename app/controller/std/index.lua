local factory = require('controller.factory')
local gateway = require('controller.parent.gateway')
local login = require('controller.std.process.login')
local std = {
    state = login
}

setmetatable(std, {
    __index = gateway
})

function std:handler ()
    self:prepare()
    self:work()
end

function std:work ()
    self.state:handler(self)
end

factory:register('std', std)

