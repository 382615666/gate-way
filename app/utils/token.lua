local redis = require('utils.redis')
local jwt = require('libs.jwt')
local uuid = require('libs.resty.uuid')
local KEY_EXPIRE = 86400
local TOKEN = {}

function TOKEN:get ()
    return ngx.req.get_headers()['token'] or ngx.req.get_uri_args()['token']
end

function TOKEN:decode (token, skip_expire)
    local valid = jwt:verify(self:syncGenKey(), token)
    local result = nil
    if valid.valid and valid.verified then
        local expires = valid.payload.expires
        ngx.update_time()
        if skip_expire or ngx.time() <= expires then
            result = valid.payload.payload
        end
    end
    return result
end

function TOKEN:syncGenKey ()
    ngx.update_time()
    local date = os.date('%Y%m%d', ngx.time() - KEY_EXPIRE)
    local key = 'ability-gateway:jwt-key:' .. date
    uuid.seed()
    local client = redis:getClient()
    local lock = client:setnx(key, uuid())
    if lock == 1 then
        client:expire(key, KEY_EXPIRE)
    end
    local result = client:get(key)
    redis:closeClient(client)
    return result
end

return TOKEN