local utils = require('utils.index')
local constants = require('utils.constants')
local info = ngx.shared.info
local cjson = require('cjson')
local interceptors = {}


function formatSeriveName (name)
    local result = string.gsub(name, '[-_](v%d)+', '/%1')
    result = '/'..result..'/'
    return result
end

function getProxyConfig ()
    -- xx_v1,xx-xx_v1,xx_v1?location=xx&bodysize=xx

    local proxy = os.getenv('PROXY')
    local proxys = {}
    local services = utils:split(proxy, ',')
    
    for index, service in ipairs(services) do
        -- xx_v1?location=xx&bodysize=xx
        local res = utils:split('?')
        local name = res[1]

        proxys[name] = {
            location = nil,
            path = nil,
            body_size = nil,
            real = nil,
            auth = nil
        }
        
        -- location=xx&bodysize=xx
        local configs = utils:split(res[2], '&')
        for index, config in ipairs(configs) do
            -- location=xx
            local re = utils:split(config, '=')
            proxys[name][re[1]] = re[2]
        end
        
    end

    -- xx-xx_v1 -> /xx-xx/v1/
    local result = {}
    for name, config in pairs(proxys) do
        table.insert(result, {
            location = config.location or formatSeriveName(name),
            path = config.path or formatSeriveName(name),
            host = config.real or name
        })
    end
    return result
end

interceptors.coreConfig = function (req, res, next)
    local config = info:get(constants.GATEWAY_CORECONFIG)
    if not config then
        config = {
            redis_host = os.getenv('REDIS_HOST'),
            redis_port = os.getenv('REDIS_PORT') or 6379,
            dev = os.getenv('NGINX_ENV') == 'development',
            nginx_env = os.getenv('NGINX_ENV') or 'production',
            app_name = os.getenv('APP_NAME') or 'gateway',
            version = os.getenv('VERSION') or 'test'
        }

        config.proxy = getProxyConfig()
        info:set(constants.GATEWAY_CORECONFIG, cjson.encode(config))
    end
    next()
end

interceptors.reqParams = function (req, res, next)
    req.traceId = utils:buildUUID()
    req.rpcId = '0'
    req.request_time = ngx.req.start_time()

    local config = info:get(constants.GATEWAY_CORECONFIG)
    config = cjson.decode(config.nginx_env)
    req.env = config.nginx_env
    req.dev = config.dev
    req.app = config.app_name
    req.version = config.version

    ngx.req.set_header('tranceid', req.traceId)
    ngx.req.set_header('appname', req.app)

    local cookie = ngx.req.get_headers()['Cookie']
    -- 清除易观方舟的cookie
    if cookie then
        cookie = string.gsub(cookie, 'FZ_STROAGE=[^ ]*', '')
        ngx.req.set_header('Cookie', cookie)
    end

    if req.app and req.app ~= 'www' then
        ngx.req.clear_header('cookie')
    end

    next()
end
return interceptors