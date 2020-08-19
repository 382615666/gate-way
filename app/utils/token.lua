local redis = require('utils.redis')
local jwt = require('libs.jwt')
local uuid = require('libs.resty.uuid')
local KEY_EXPIRE = 86400
local JWT_EXPIRE = 7200
local TOKEN = {}

function TOKEN:get ()
    return ngx.req.get_headers()['token'] or ngx.req.get_uri_args()['token']
end

function TOKEN:decode (token, skip_expire, key)
    local valid = jwt:verify(self:syncGenKey(key), token)
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

function TOKEN:syncGenKey (key)
    ngx.update_time()
    local date = os.date('%Y%m%d', ngx.time() - KEY_EXPIRE)
    local key = key .. '-gateway:jwt-key:' .. date
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

function TOKEN:build (payload, key)
    ngx.update_time()
    local data =  {
        payload = payload,
        expires = ngx.time() + JWT_EXPIRE
    }
    local table_of_jwt = {
        header = { typ= 'JWT', alg= 'HS256' },
        payload = data
    }
    return jwt:sign(self:syncGenKey(key), table_of_jwt)
end

return TOKEN