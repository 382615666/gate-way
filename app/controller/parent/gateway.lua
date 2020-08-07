local Token = require('utils.token')
local parent = {}

function parent:init (req, res, option)
    self.req = req
    self.res = res
    self.option = option

    return self:handler()
end

function parent:handler ()
    ngx.log(ngx.ERR, 'u must override the method: hanlder')
end

function parent:prepare ()
    local token = Token:get()
    if not token then
        return false
    end
    local payload = Token:decode(token, false, self.option.key)
    if payload then
        req.auth = {
            userId = payload.uid, -- 用户 id 
            device = payload.device,
            sign = payload.sign  -- 登录签名信息
        }
        for key, value in pairs(payload.headers) do
            ngx.req.set_header(key, value)
        end
    end
end

function parent:setState (state)
    self.state = state
end

return parent