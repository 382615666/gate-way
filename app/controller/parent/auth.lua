local utils = require('utils.index')
local userSign = require('utils.sign')
local TOKEN = require('utils.token')
local permission = require('utils.permission')
local redis = require('utils.redis')
local auth = {}
local info = ngx.shared.info

function auth:needAuth(path, include, dev)
  local headers = ngx.req.get_headers()
  if self:devNoAuthHeaderMatch(dev) then
    return false
  end
  for index, item in ipairs(include) do
    local spath = string.lower(self:toPath(item)) 
    local i = string.find(string.lower(path), spath)
    if i == 1  then
      return true
    end
  end
  return false
end

function auth:toPath (name)
  local result = string.gsub(name, '[-_](v%d+)$', '/%1')
  result = '/'..result..'/'
  return result
end

function auth:getPath ()
  local headers =  ngx.req.get_headers()
  local url = 'http://' .. headers['host'] .. ngx.var.request_uri
  local result = nil
  local regex_str = '^(https|http)://([^/^:]+)(:\\d+)*/(\\w+)/v[0-9]*/([^?]+)'
  local m, err = ngx.re.match(url,regex_str,'i')
  if m then
    result = '/' .. string.lower(m[4]) .. '/' .. string.lower(m[5])
  end
  return result
end

function auth:devNoAuthHeaderMatch (dev)
  if not dev then
    return false
  end
  local value = ngx.get_headers['no-auth']
  if not value or value == '' then
    return false
  end
  local values = utils:split(value, ',')
  for index, item in ipairs(values) do
    local _, index = string.find(path, string.lower('/'.. item ..'/'))
    if index and index >= 1 then
      return true
    end
  end
  return false
end

function auth:getWhiteOrGreyApiList (address, app, key, type)
  local apis = {}
  local key = key .. '_' .. type .. '_' .. app .. '_apis'
  local apis_json = info:get(key)
  if not apis_json then
    local res = utils:invoke(address, nil, app)
    if res.status == 200 then
      local array = cjson.decode(res.body)
      for i,api in ipairs(array) do
        if api ~= nil and api ~= '' then
          local str = string.lower(api.method)..':'..
                      (string.find(api.apiDivisor,'/') == 1 and '' or '/') ..
                      api.apiDivisor
          table.insert(apis, string.lower(str))
        end
      end
      info:set(key, cjson.encode(apis), 60)
    end
  else
    apis = cjson.decode(apis_json)
  end
  return apis
end

function auth:whiteApi (req, res, option)
  local apis = self:getWhiteOrGreyApiList(option.urls.white_apis, option.app, option.key, 'white')
  local uri =  req.method .. ':' .. self:getPath()
  uri = string.lower(uri)
  local result = false
  for index, item in ipairs(apis) do
    local newstr, n1, err1 = ngx.re.gsub(item, '{[^/]+}', '[^/]+', "i")
    -- 替换通配符 * 为正则表达式
    local s, n1, err1 = ngx.re.gsub(newstr, '\\*', '.*', "i")
    local m, err = ngx.re.match(uri, newstr..'$')
    if m then
      result = true
      break
    end
  end
  if not result then
    self:greyApi(req, res, option)
  end
end

function auth:greyApi (req, res, option)
  local apis = self:getWhiteOrGreyApiList(option.urls.grey_apis, option.app, option.key)
  local uri =  req.method .. ':' .. self:getPath()
  uri = string.lower(uri)
  local result = false
  for index, item in ipairs(apis) do
    -- 替换路径参数为正则表达式
    local newstr, n1, err1 = ngx.re.gsub(v, '{[^/]+}', '[^/]+', "i")
    -- 替换通配符 * 为正则表达式
    local s, n1, err1 = ngx.re.gsub(newstr, '\\*', '.*', "i")
    local m, err = ngx.re.match(uri, s .. '$')
    if m then
      result = true
    end
  end
  if result then
    if not req.auth then
      res:err(constants.ERROR.e401002)
    else
      local r, sign = userSign:match(req.auth.userId,
                                        req.auth.device,
                                         req.auth.sign,
                                         option.dev,
                                         option.redis_host,
                                         option.redis_port,
                                         option.key
                                         )
      if not r and (sign == nil or sign == '' or sign == ngx.null) then
        res:err(constants.ERROR.e401004)
      end
      if not r and  sign ~= req.auth.sign then
        res:err(constants.ERROR.e401003)
      end
    end
  else
    self:permissionApi(req, res, option)
  end
end

function auth:replacePlaceholder (permissions)
  for i,v in ipairs(permissions) do
    local str=(string.find(v.apiDivisor,'/') == 1 and '' or '/')..v.apiDivisor
    local newstr, n, err = ngx.re.gsub(str, '/', '\\/+', "i")
    local newstr1, n1, err1 = ngx.re.gsub(newstr, '{[^/]+}', '[^/]+', "i")
    local s, n1, err1 = ngx.re.gsub(newstr1, '\\*', '.*', "i")
    v.apiUrl = '^'..string.lower(s)..'$'
  end
  return permissions
end
function auth:getPermissionApiList(address, app, key)
  local permissions_key = key .. '_all_permission'
  local permissions_json = info:get(permissions_key)
  if permissions_json then
    return cjson.decode(permissions_json)
  else
    ngx.log(ngx.ALERT, cjson.encode(address))
    local res = utils:invoke(address, nil,  app)
    if res.status == 200 then
      local obj = cjson.decode(res.body)
      local allPermissions = self:replacePlaceholder(obj)
      info:set(permissions_key, cjson.encode(allPermissions), 60)
      ngx.log(ngx.ALERT, cjson.encode(allPermissions))
      return allPermissions
    end
  end
end

function auth:hashPermission (apis, option, uid)
  local  client = redis:getClient()
  for i,v in ipairs(apis) do
    local key = option.key..'_permission_'..option.app..':'..uid
    local res, err = client:sismember(key, v.apiId)
    if res == 1 then
      return true
    end
  end
  redis:closeClient(client)
  return false
end

function auth:permissionApi(req, res, option)
  local apis = self:getPermissionApiList(option.urls.apis, option.app, option.key)
  local findapis = {}
  local hasValue = false
  for i,v in ipairs(apis) do
    local uri = string.lower(self:getPath())
    local apiuri =  string.lower(v.apiUrl)
    local m, err = ngx.re.match(uri,apiuri)
    if m and string.lower(req.method) == string.lower(v.method) then
      table.insert(findapis, v)
      hasValue = true
    end
  end
  if hasValue then
    if not req.auth then
      res:err(constants.ERROR.e401002)
    else
      local r, sign = data.matchUserSign(req.auth.userId,
                                          req.auth.device,
                                          req.auth.sign,
                                          option.dev,
                                          option.redis_host,
                                          option.redis_port,
                                          option.key)
      if not r and (sign == nil or sign == '' or sign == ngx.null ) then
        res:err(constants.ERROR.e401004)
      end
      if not r and  sign ~= req.auth.sign then
        res:err(constants.ERROR.e401003)
      end
    end
    local isPermission = self:hashPermission(req.auth.userId, option)
    if not isPermission then
      res:err(constants.ERROR.e403001)
    end
  else
    res:err(constants.ERROR.e403001)
  end
end


function auth:work(req, res, option)
    res.isProcess = true
    self:whiteApi(req, res, option)
end

return auth