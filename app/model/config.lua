local cjson = require('cjson')
local constants = require('utils.constants')
local utils = require('utils.index')
local info = ngx.shared.info



local CONFIG = {}

function CONFIG:coreConfig ()
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
end

function CONFIG:openApiConfig ()
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
    return apiConfig
end

function CONFIG:authConfig ()
    local config = info:get(constants.GATEWAY_AUTHCONFIG)
    if config then
        config = cjson.decode(config)
    else
        local auth = os.getenv('AUTH')
        if auth then
            auth = utils:split(auth, '|')
            config = {
                type = auth[1],
                -- options = require()
            }
        end
    end

    return config
end

function CONFIG:staticConfig ()
    local config = info:get(constants.GATEWAY_STATICCONFIG)    
    if config then
        config = cjson.decode(config)
    else
        config = {}
        local staticFile = os.getenv('STATIC_FILE')
        staticFiles = utils:split(staticFile, '|')
        for index, item in ipairs(staticFiles) do
            local ite = utils:split(item, '&')
            local temp = {}
            for ind, it in ipairs(ite) do
                local i = utils:split(it, '=')
                if string.lower(i[1]) == 'url' then
                    temp.path = i[2]
                elseif string.lower(i[1] == 'path') then
                    temp.dir = i[2]
                elseif string.lower(i[1] == 'h5') then
                    temp.h5 = true
                end
            end
            if temp.path and temp.dir then
                table.insert(config, temp)
            end
        end
        info:set(constants.GATEWAY_STATICCONFIG, cjson.encode(config))
    end
    return config
end


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

function CONFIG:proxyConfig ()
    local config = info:get(constants.GATEWAY_PROXYCONFIG)
    if config then
        config = cjson.decode(config)
    else 
        config = getProxyConfig()
        info:set(constants.GATEWAY_PROXYCONFIG, cjson.encode(config))
    end
    return config
end

return CONFIG