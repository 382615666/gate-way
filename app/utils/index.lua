local uuid = require('libs.resty.jit-uuid')
local constants = require('utils.constants')
local ip = require('utils.ip')
local info = ngx.shared.info
local utils = {}

function utils:split (str, delimeter)
    str = str or ''
    local result = {}
    local values = string.gmatch(str, '[^' .. delimeter ..']+')

    for value in values do
        table.insert(result, value)
    end

    return result
end

function utils:buildUUID ()
    return uuid.generate_v5(uuid(), self:getHostname() .. self.getInc())
end

function utils:getHostname ()
    local hostname = info:get(constants.HOSTNAME)
    if not hostname then
        -- local result = io:popen('cat /etc/home')
        -- hostname = result:read('*all')
        -- info:set(constants.HOSTNAME, hostname)
    end

    return hostname or ''
end

function utils:getInc ()
    local result = info:incr(constants.INC, 1, 0)
    result = result or 0
    return result
end

function utils:dateFormat (time)
    return os.date('%Y-%m-%d %H:%M:%S', time)
end

function utils:getRpcId ()
    ngx.ctx.rpcid = ngx.ctx.rpcid and ngx.ctx.rpcid + 1 or 1
    return '0.' .. ngx.ctx.rpcid
end

function utils:getHttpConstants (method)
    local methods = {
        GET = ngx.HTTP_GET,
        HEAD = ngx.HTTP_HEAD,
        PUT = ngx.HTTP_PUT,
        POST = ngx.HTTP_POST,
        DELETE = ngx.HTTP_DELETE,
        OPTIONS = ngx.HTTP_OPTIONS,
        PATCH = ngx.HTTP_PATCH,
    }
    return methods[method]
end

function utils:invoke (apis, body, ...) 
    local config = info:get(constants.GATEWAY_CORECONFIG)
    config = cjson.decode(config)

    local result = ''
    if config.dev then
        result = ip:getDevIp(apis.host)
    else
        result = ip:getIp(api.host)
    end

    if not result then
        ngx.log(ngx.ERR, 'can not resolve host: '..(apis.host or ''))
    end

    ngx.req.set_header('rpc_id', self:getRpcId())

    return ngx.location.capture('/_internal/proxy', {
        method = self:getHttpConstants(string.upper(apis.method)),
        body = cjson.encode(body),
        vars = {
            proxyuri = string.format('http://' .. result .. apis.uri, ...)
        }
    })
end

function utils:fileExists (path)
    local file = io.open(path, 'rb')
    if file then
        file:close()
    end
    return file ~= nil
end

return utils