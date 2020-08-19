local utils = require('utils.index')
local userSign = require('utils.sign')
local TOKEN = require('utils.token')
local constants = require('utils.constants')
local user = {}

function user:isProcess (state, req)
    return state.name == self.name and string.lower(req.path) == '/api/current_user' and req.method == 'GET' 
end

function user:work(req, res, option)
    res.isProcess = true
    ngx.header['content-type'] = 'application/json'
    local token = TOKEN:get()
    if token then
      local payload = TOKEN:decode(token, false, option.key)
      if payload then
        local r, store_sign = userSign:match(payload.uid, payload.device, payload.sign, option.dev, option.key)
        if not r or not store_sign or store_sign == '' then
          res:err(constants.ERROR.e401004)
        end
        if not r and  store_sign ~= req.auth.sign then
          res:err(constants.ERROR.e401003)
        end
      else
        res:err(constants.ERROR.e401002)
      end
    else
      res:err(constants.ERROR.e401001)
    end
end

return user