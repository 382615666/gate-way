local parent = require('controller.parent.user')
local user = {
    name = 'user'
}

setmetatable(user, {
    __index = parent
})

function user:handler (gateway)
    if self:isProcess(gateway.state, gateway.req, gateway.res, gateway.option) then
        self:work(req, res, options)
    else
        gateway:setState()
        gateway:work()
    end
end

return user