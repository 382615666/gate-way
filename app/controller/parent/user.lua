local utils = require('utils.index')
local userSign = require('utils.sign')
local token = require('utils.token')
local permission = require('utils.permission')
local user = {}

function user:isProcess (state, req, res, options)
    return state.name == self.name and string.lower(req.path) == '/api/current_user' and req.method == 'GET' 
end

function user:work(req, res, options)
    res.isProcess = true
    ngx.header['content-type'] = 'application/json'
    local token = token:get()
    if token then

    else
      res:status
    end
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
        local access_token = token:build(payload, option.key)
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

return user