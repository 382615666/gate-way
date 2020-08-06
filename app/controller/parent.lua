local Token = require('utils.token')
local parent = {}

function parent:init (req, res, options)
    self.req = req
    self.res = res
    self.options = options

    return self:handler()
end

function parent:handler ()
    ngx.log(ngx.ERR, 'u must override the method: hanlder')
    return false
end


function parent:prepare ()
    local token = Token:get()
    if not token then
        return false
    end
    local payload = Token:decode(token, false)
    
end


return parent