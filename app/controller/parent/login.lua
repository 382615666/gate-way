local utils = require('utils.index')
local userSign = require('utils.sign')
local TOKEN = require('utils.token')
local permission = require('utils.permission')
local login = {}

function login:isProcess (state, req)
    return state.name == self.name and string.lower(req.path) == '/api/login' and req.method == 'POST' 
end

function login:work(req, res, option)
    res.isProcess = true
    local subRes = self:getLoginInfo(option.urls.login, req.body)
    ngx.header['content-type'] = 'application/json'
    if subRes.status == ngx.HTTP_OK then
        local userInfo = cjson.decode(subRes.body)
        local device= ngx.var.arg_device or ''
        local sign = userSign:createUserSign(userInfo.userId, device, option.key)
        local payload = {
          uid = userInfo.userId,
          device = device,
          headers = userInfo.header or {},
          sign = sign,
          remember = req.body.remember
        }
        local access_token = TOKEN:build(payload, option.key)
        ngx.update_time()
        local result = {
          userId = userInfo.userId,
          access_token = access_token,
          timestamp = ngx.time()
        }
        permission:updateUserPermission(option.urls.permission, userInfo.userId, option.app, option.key)
        res:json(result)
    else
      res:pipe(sub_res)
    end
end

function login:getLoginInfo (address, data)
    return utils:invoke(address, data)
end

return login