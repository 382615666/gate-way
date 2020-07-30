local redis = require('libs.resty.redis')
local constants = require('utils.constants')
local cjson = require('cjson')
local ip = require('utils.ip')
local info = ngx.shared.info
local REDIS = {}

function REDIS:getClient ()
    local client = redis:new()
    client:set_timeout(5000)
    local config = info:get(constants.HOST_DEVELOPMENT)
    config = cjson.encode(config)
    local ip = ip:getIp(config.redis_host)
    client:connect(ip, config.redis_port)
    return client
end

function REDIS:closeClient (client)
    client:set_keepalive(100000, 10)
end

return REDIS