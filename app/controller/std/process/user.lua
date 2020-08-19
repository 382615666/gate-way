local parent = require('controller.parent.user')
local logout = require('controller.std.process.logout')
local user = {
    name = 'user'
}

setmetatable(user, {
    __index = parent
})

function user:handler (gateway)
    if self:isProcess(gateway.state, gateway.req) then
        self:work(gateway.req, gateway.res, gateway.option)
    else
        gateway:setState(logout)
        gateway:work()
    end
end

return user