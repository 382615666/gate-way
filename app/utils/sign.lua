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

return sign