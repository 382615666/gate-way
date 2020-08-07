local utils = require('utils.index')
local AUTHCONFIG = {}

function formatConfig (str, separator)
    local result = {}
    local strResult = utils:split(str, separator)
    for index, item in ipairs(strResult) do
        table.insert(result, item)
    end
    return result
end

function formatServices (config)
    local result = {}
    local services = utils:split(config, ',')
    for index, item in ipairs(services) do
        local it = utils:split(item, '=')
        result[it[1]] = it[2] 
    end
    return result
end

function AUTHCONFIG:zyx (config)
    local serviceResult = formatServices(config, ',')

    local include = utils:split(serviceResult['include'], '%&')
    local exclude = utils:split(serviceResult['exclude'], '%&')
    
    local token = utils:split(serviceResult['token'], '%&')
    token.name = token.name or 'token'
    token.cookie = token.cookie and true or false
    token.header = token.header and true or false
    token.url = token.url and true or false
    
    local us_v1 = serviceResult['us_v1'] or 'us_v1'
    local os_v1 = serviceResult['os_v1'] or 'os_v1'

    return {
        include = include,
        exclude = exclude,
        token = token,
        key = 'api-gateway',
        urls = {
          -- 权限api接口
          apis = {
            host = us_v1,
            uri = '/us/v1/permissions?auth=1',
            method = 'get'
          },
          -- 白名单api接口
          white_apis = {
            host = us_v1,
            uri = '/us/v1/permissions?auth=2&appName=%s',
            method = 'get'
          },
          -- 灰名单api接口
          grey_apis = {
            host = us_v1,
            uri = '/us/v1/permissions?auth=3&appName=%s',
            method = 'get'
          },
          -- 获取企业员工接口权限列表（%s 用户id）
          permission = {
            host = os_v1,
            uri = '/os/v1/user/%s/apis',
            method = 'get'
          },
          -- 用户登录接口
          login = {
            host = us_v1,
            uri = '/us/v1/user/login',
            method = 'post'
          },
          -- 用户退出登录接口 (%s 用户id )
          logout = {
            host = us_v1,
            uri = '/us/v1/user/login/%s',
            method = 'post'
          },
          -- 用户信息接口 (%s 用户id)
          user = {
            host = us_v1,
            uri = '/us/v1/user/%s',
            method = 'get'
          },
          -- 员工信息接口 ( %s 用户id )
          employee = {
            host = os_v1,
            uri = '/os/v1/user/%s/employees',
            method = 'get'
          }
        }
      }
end

function AUTHCONFIG:openapi (config)
    local serviceResult = formatServices(config, ',')
    
    local include = utils:split(serviceResult['include'], '&')
    
    local saas_openapi_v1 = serviceResult['saas_openapi_v1'] or 'saas_openapi_v1'

    return {
        include = include,
        urls = {
          appsign_api ={
            host = saas_openapi_v1,
            uri = '/saas_openapi/v1/app/%s/appsign',
            method = 'get'
          },
          appInfo = {
            host = saas_openapi_v1,
            uri = '/saas_openapi/v1/app/%s',
            method = 'get'
          },
          apis = {
            host = saas_openapi_v1,
            uri = '/saas_openapi/v1/app/%s/apis?pageSize=100000',
            method = 'get'
          }
        }
      }
end

function AUTHCONFIG:ad (config)
    local serviceResult = formatServices(config, ',')

    local include = utils:split(serviceResult['include'], '&')
    local exclude = utils:split(serviceResult['exclude'], '&')
        
    local paas_ability_us_v1 = serviceResult['paas_ability_us_v1'] or 'paas_ability_us_v1'
    local paas_ability_os_v1 = serviceResult['paas_ability_os_v1'] or 'paas_ability_os_v1'
    
    return {
        include = include,
        exclude = exclude,
        key = 'ability-gateway',
        urls = {
          -- 权限api接口
          apis = {
            host = paas_ability_os_v1,
            uri = '/paas_ability_os/v1/gateway/permissions?auth=1&appName=%s',
            method = 'get'
          },
          -- 白名单api接口
          white_apis = {
            host = paas_ability_os_v1,
            uri = '/paas_ability_os/v1/gateway/permissions?auth=2&appName=%s',
            method = 'get'
          },
          -- 灰名单api接口
          grey_apis = {
            host = paas_ability_os_v1,
            uri = '/paas_ability_os/v1/gateway/permissions?auth=3&appName=%s',
            method = 'get'
          },
          -- 获取企业员工接口权限列表（%s 用户id）
          permission = {
            host = paas_ability_os_v1,
            uri = '/paas_ability_os/v1/gateway/user/%s/apis',
            method = 'get'
          },
          -- 用户登录接口
          login = {
            host = paas_ability_us_v1,
            uri = '/paas_ability_us/v1/gateway/user/login',
            method = 'post'
          },
          -- 用户退出登录接口 (%s 用户id )
          logout = {
            host = paas_ability_us_v1,
            uri = '/paas_ability_us/v1/gateway/user/login/%s',
            method = 'post'
          },
          -- 用户信息接口 (%s 用户id)
          user = {
            host = paas_ability_us_v1,
            uri = '/paas_ability_us/v1/gateway/user/%s',
            method = 'get'
          },
          -- 员工信息接口 ( %s 用户id )
          employee = {
            host = paas_ability_os_v1,
            uri = '/paas_ability_os/v1/gateway/user/%s',
            method = 'get'
          }
        }
      }
end

function AUTHCONFIG:emp (config)
    local serviceResult = formatServices(config, ',')
    local include = utils:split(serviceResult['include'], '&')
    local emp_os_v1 = serviceResult['emp_os_v1'] or 'emp_os_v1'
    return {
        include = include,
        key = 'api-gateway',
        urls = {
          current_user = {
            host = 'www.ejw.cn',
            uri = '/api/current_user?token=%s',
            method = 'get'
          },
          user_apidivisors = {
            host = emp_os_v1,
            uri = '/emp_os/v1/user/%s/employee',
            method = 'get'
          },
          bind = {
            host = emp_os_v1,
            uri = '/emp_os/v1/employee/user/%s',
            method = 'post'
          },
          apidivisors = {
            host = emp_os_v1,
            uri = '/emp_os/v1/apidivisor',
            method = 'get'
          }
        }
      }
end

function AUTHCONFIG:information (config)
    local serviceResult = formatServices(config, ',')
    local include = utils:split(serviceResult['include'], '&')
    local info_saas_us_v1 = serviceResult['info_saas_us_v1'] or 'info_saas_us_v1'

    return {
        include = include,
        key = 'information-gateway',
        urls = {
          -- 权限api接口
          apis = {
            host = info_saas_us_v1,
            uri = '/info_saas_us/v1/apis?auth=1&appName=%s',
            method = 'get'
          },
          -- 白名单api接口
          white_apis = {
            host = info_saas_us_v1,
            uri = '/info_saas_us/v1/apis?auth=2&appName=%s',
            method = 'get'
          },
          -- 灰名单api接口
          grey_apis = {
            host = info_saas_us_v1,
            uri = '/info_saas_us/v1/apis?auth=3&appName=%s',
            method = 'get'
          },
          -- 获取员工接口权限列表（%s 用户id）
          permission = {
            host = info_saas_us_v1,
            uri = '/info_saas_us/v1/user/%s/apis?appName=%s',
            method = 'get'
          },
          -- 用户登录接口
          login = {
            host = info_saas_us_v1,
            uri = '/info_saas_us/v1/user/login',
            method = 'post'
          },
          -- 用户信息接口 (%s 用户id)
          user = {
            host = info_saas_us_v1,
            uri = '/info_saas_us/v1/user/%s/active',
            method = 'get'
          }
        }
      }
end

function AUTHCONFIG:std (config)
    local serviceResult = formatServices(config, ',')
    local key = serviceResult['key'] or 'std'
    local include = utils:split(serviceResult['include'], '&')

    local login_url = utils:split(serviceResult['login_url'], '@')
    local login_host = login_url[1] or 'us_v1'
    login_url = login_url[2] or '/us/v1/gateway/login'

    local api_url = utils:split(serviceResult['api_url'], '@')
    local api_host = api_url[1] or 'os_v1'
    api_url = api_url[2] or '/os/v1/gateway/apis'

    local permission_url = utils:split(serviceResult['permission_url'], '@')
    local permission_host = permission_url[1] or 'os_v1'
    permission_url = permission_url[2] or '/os/v1/gateway/user/%s/apis'
    return {
        include = include,
        key = key,
        urls = {
          -- 权限api接口
          apis = {
            host = api_host,
            uri = api_url..'?auth=1&appName=%s',
            method = 'get'
          },
          -- 白名单api接口
          white_apis = {
            host = api_host,
            uri = api_url..'?auth=2&appName=%s',
            method = 'get'
          },
          -- 灰名单api接口
          grey_apis = {
            host = api_host,
            uri = api_url..'?auth=3&appName=%s',
            method = 'get'
          },
          -- 获取员工接口权限列表（%s 用户id）
          permission = {
            host = permission_host,
            uri = permission_url,
            method = 'get'
          },
          -- 用户登录接口
          login = {
            host = login_host,
            uri = login_url,
            method = 'post'
          }
        }
      }
end

return AUTHCONFIG