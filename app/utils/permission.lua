local redis = require('utils.redis')
local permission = {}

function permission:updateUserPermission (address, userId, app, key)
    local apis = self:getUserPermission(address, userId)
    self:writeUserPermission(apis, userId, app, key)
end

function permission:getUserPermission (address, userId)
    local res = utils:invoke(address, nil, userId)
    local result = {}
    if res.status == ngx.HTTP_OK then
        local body = cjson.decode(res.body)
        if body.apiList then
            body = body.apiList
        end
        for key, value pairs(body) do
            table.insert(result, value)
        end
        return result
    end
    return result
end

function permission:writeUserPermission (apiIds, userId, app, key)
    local client = redis:getClient()
    local key = key..'_permission_'..app..':'..userId
    client:del(key)
    for index, item in ipairs(apiIds) do
        redClient:sadd(key, item)
    end
    redis:closeClient(client)
end


return permission