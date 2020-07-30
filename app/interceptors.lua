local utils = require('utils.index')
local constants = require('utils.constants')
local redis = require('utils.redis')
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

        info:set(constants.GATEWAY_CORECONFIG, cjson.encode(config))
    end
    next()
end

interceptors.reqParams = function (req, res, next)
    req.traceId = utils:buildUUID()
    req.rpcId = '0'
    req.request_time = ngx.req.start_time()

    local config = info:get(constants.GATEWAY_CORECONFIG)
    config = cjson.decode(config)
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

interceptors.log = function (req, res, next)
    next()
    ngx.update_time()
    ngx.flush()

    local fmt = info:get(constants.GATEWAY_LOGCONFIG)
    if not fmt then
        fmt = os.getenv('ACCESS_LOG_FORMAT')
        fmt = fmt or '[$level][$datetime][$app]$userid $traceid $rpcid "$protocol" "$method" "$url" "$useragent" '
                ..'$status $request_time $body_bytes_sent "$http_referer"'
        info:set(constants.GATEWAY_LOGCONFIG, fmt)
    end

    local config = info:get(constants.GATEWAY_CORECONFIG)
    config = cjson.decode(config)

    local log = {
        level = 'INFO ',
        datetime = utils:dateFormat(ngx.req.start_time()),
        app = config.app_name,
        userid = req.auth and req.auth.userId or 'null',
        traceid = req.traceId,
        rpcid = req.rpcId,
        protocol = 'HTTP/1.1',
        method = ngx.req.get_method(),
        url = 'http://' .. ngx.var.host .. req.path,
        useragent = ngx.var.http_user_agent,
        status = ngx.status,
        request_time = math.floor((ngx.now() - ngx.req.start_time()) * 1000),
        body_bytes_sent = ngx.var.bytes_sent,
        http_referer = ngx.var.http_referer or ''
    }

    for key, value in pairs(log) do
        fmt = string.gsub(fmt, '%$' .. key, value)
    end

    io.stdout:write(fmt .. '\r\n')
    io.stdout:flush()
    
end

function getOpenApiList (apis, appid)
    local config = info:get('all_open_api:' .. appid)
    if config then
        return cjson.decode(config)
    else
        local res = utils:invoke(apis, nil, appid)
        if res.status == 200 then
            local result = cjson.decode(res.body)
            for index, item in ipairs(result.data) do
                local path = ngx.re.gsub(item.apiPath, '/', '\\/+', "i")
                path = ngx.re.gsub(path, '{[^/]+}', '[^/]+', "i")
                item.apiUrl = '^'..string.lower(path)..'$'
            end
            info:set('all_open_api:' .. appid, cjson.encode(result.data), 60)
            return result.data
        end
        return {}
    end

end

interceptors.openApiConfig = function (req, res, next)

    next()

    local apiConfig = info:get(constants.GATEWAY_APISTATISTICSCONFIG)
    if apiConfig then
        apiConfig = cjson.decode(apiConfig)
    else
        local service = os.getenv('API_STATISTICS')
        if not service then
            return
        end
        service = utils:split(service, '=')
    
        local config = info:get(constants.GATEWAY_CORECONFIG)
        config = cjson.decode(config)
    
        apiConfig =  {
            redis_host = config.redis_host,
            redis_port = config.redis_port,
            urls = {
                apis = {
                    host = service[2] or 'saas_openapi_v1',
                    uri = '/saas_openapi/v1/app/%s/apis?pageSize=100000',
                    method = 'get'
                }
            }
        }

        info:set(constants.GATEWAY_APISTATISTICSCONFIG, cjson.encode(apiConfig))
    end

    local appid = ngx.req.get_headers()['app-id']
    if not appid then
        return 
    end

    local apis = getOpenApiList(apiConfig.urls.apis, appid)
    local path = ngx.re.gsub(req.path, '/(\\w+)/v[0-9]+/', '/$1/')
    local api = nil
    for index, item in ipairs(apis) do
        local p = ngx.re.match(path, item.apiUrl)
        if p and string.upper(item.apiMethod) == req.method then
            api = item
            break
        end
    end
    if not api then
        return
    end
    local key = 'open-gateway:' .. appid .. ':' .. obj.apiId .. ':' .. obj.apiNo .. ':' .. (math.floor(ngx.time()/60/60))
    if ngx.status == ngx.HTTP_OK then
        key = key .. ':1'
    else 
        key = key .. ':0'
    end
    
    local client = redis:getClient()
    local result = client:incr(key)
    client:closeClient(client)
    if result == 1 then
        client:expire(key, 86400)
    end
    ngx.log(ngx.ALERT,key .. "-----" .. ok)
end

return interceptors