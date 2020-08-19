local utils = require('utils.index')
local TOKEN = require('utils.token')
local constants = require('utils.constants')
local permission = require('utils.permission')
local PERMISSION = {}

function PERMISSION:isProcess (state, req, res, options)
    return state.name == self.name and string.lower(req.path) == '/api/update_current_permission' and req.method == 'GET' 
end

function PERMISSION:work(req, res, options)
    res.isProcess = true
    ngx.header['content-type'] = 'application/json'
    local token = TOKEN:get()
    if token then
      local payload = TOKEN:decode(token, false, options.key)
      if payload then
        permission:updateUserPermission(options.urls.permission, payload.uid, options.app, options.key)
        res:send('ok')
      else
        res:err(constants.ERROR.e401004)
      end
    else
      res:err(constants.ERROR.e401003)
    end
end

return PERMISSION