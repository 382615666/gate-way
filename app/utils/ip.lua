local cjson = require('cjson')
local utils = require('utils.index')
local resolver = require('libs.resty.dns.resolver')
local constants = require('utils.constants')
local redis = require('utils.redis')
local IP = {}
local regex = '(?:(?:1[0-9][0-9]\\.)|(?:2[0-4][0-9]\\.)|(?:25[0-5]\\.)|(?:[1-9][0-9]\\.)|(?:[0-9]\\.)){3}(?:(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5])|(?:[1-9][0-9])|(?:[0-9]))'
local info = ngx.shared.info

function IP:getIp (hostname)
    local m, err = ngx.re.match(hostname, regex)
    if m then
        return hostname
    end
    local ip = info:get('host:'..hostname)
    if ip then
        return ip
    end
    -- dns:port
    local nameResult = utils:split(hostname, ':')
    local dns = result[1]
    local port = result[2] and ':' .. result[2] or ''

    -- https://github.com/openresty/lua-resty-dns
    local result, err = resolver:new{
        nameservers = {'127.0.0.11'},
        retrans = 5,
        timeout = 2000
    }

    if err then
        return
    end
    
    local answers, err = result:query(dns)
    if err then
        return
    end

    for index, item in ipairs(answers) do
        ip = item.address or item.name
    end

    info:set('host:' .. hostname, ip .. port, 60)

    return ip .. port

end

function IP:setDevIp (hostname, ip)
    local client = redis:getClient()
    client:hset(constants.HOST_DEVELOPMENT, hostname, ip)
    redis:closeClient(client)
end

function IP:getDevIp (hostname)
    local client = redis:getClient()
    local result, err = client:hget(constants.HOST_DEVELOPMENT, hostname)
    client:closeClient(client)
    if not err then
        return result
    else 
        return self:resolve(hostname)
    end
end

return IP
