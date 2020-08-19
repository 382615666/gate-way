local parent = require('controller.parent.login')
local user = rqeuire('controller.std.process.user')
local login = {
    name = 'login'
}

setmetatable(login, {
    __index = parent
})

function login:handler (gateway)
    if self:isProcess(gateway.state, gateway.req) then
        self:work(gateway.req, gateway.res, gateway.option)
    else
        gateway:setState(user)
        gateway:work()
    end
end

return login