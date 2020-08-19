local parent = require('controller.parent.permission')
local refresh = require('controller.std.process.refresh')
local permission = {
    name = 'permission'
}

setmetatable(permission, {
    __index = parent
})

function permission:handler (gateway)
    if self:isProcess(gateway.state, gateway.req) then
        self:work(gateway.req, gateway.res, gateway.option)
    else
        gateway:setState(refresh)
        gateway:work()
    end
end

return permission