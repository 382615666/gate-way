local redis = require('utils.redis')
local sign = {}

function sign:createUserSign (userId, device, k)
    local client = redis:getClient()
    local key = k..'_user_sign:'..userId
    if device and device ~= '' then
        key=key..':'..device
    end 
    client:del(key)
    uuid.seed()
    local result = uuid()
    client:set(key, result)
    client:closeClient(client)
    return result

end

function sign:getUserSign(userId, device, k)
    local client = redis:getClient()
    local key = k..'_user_sign:'..userId
    if device and device ~= '' then
      key=key..':'..device
    end 
    local value = redisClient:get(key)
    redis:closeClient(client)
    return value
end

function sign:match (userId, device, sign, dev, k)
    if dev then
        return true
    end
    local store_sign = self:getUserSign(userId, device, k)
    return sign == store_sign, store_sign
end

return sign