local utils = require('utils.index')
local userSign = require('utils.sign')
local TOKEN = require('utils.token')
local permission = require('utils.permission')
local refresh = {}

function refresh:isProcess (state, req)
    return state.name == self.name and string.lower(req.path) == '/api/refresh_token' and req.method == 'GET' 
end

function refresh:work(req, res, option)
    res.isProcess = true
    ngx.header['content-type'] = 'application/json'
    local token = TOKEN:get()
    if token then
      local payload = TOKEN:decode(token, false, option.key)
      if payload then
        local payload = {
          uid = payload.uid,
          device = payload.device,
          headers = payload.headers or {},
          sign = payload.sign,
          remember = payload.remember
        }
        local access_token = TOKEN:build(payload, option.key)
        local result = {
          userId = payload.uid,
          access_token = access_token
        }
        permission:updateUserPermission(option.urls.permission, payload.uid, option.app, option.key)
        res:json(result)
      else
        res:err(constants.ERROR.e401002)
      end
    else
      res:err(constants.ERROR.e401001)
    end
end

return refresh