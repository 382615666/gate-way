local parent = require('controller.parent.login')
local login = {
    name = 'login'
}

setmetatable(login, {
    __index = parent
})

function login:handler (gateway)
    if self:isProcess(gateway.state, gateway.req, gateway.res, gateway.option) then
        self:work(req, res, options)
    else
        gateway:setState()
        gateway:work()
    end
end

return login