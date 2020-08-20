local parent = require('controller.parent.auth')
local auth = {
    name = 'auth'
}

setmetatable(auth, {
    __index = parent
})

function auth:handler (gateway)
    local path = self:getPath()
    local isAuth = self:needAuth(gateway.req.path, gateway.option.include, gateway.option.dev)
    if not path or not isAuth then
        return
    end
    self:work(gateway.req, gateway.res, gateway.option)    
end

return auth