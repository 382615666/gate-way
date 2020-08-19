local parent = require('controller.parent.logout')
local permission = require('controller.std.process.permission')
local logout = {
    name = 'logout'
}

setmetatable(logout, {
    __index = parent
})

function logout:handler (gateway)
    if self:isProcess(gateway.state, gateway.req) then
        self:work(gateway.req, gateway.res, gateway.option)
    else
        gateway:setState(permission)
        gateway:work()
    end
end

return logout