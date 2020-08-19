local constants = {
    GATEWAY_CORECONFIG = 'gateway_coreConfig',
    HOST_DEVELOPMENT = 'host_development',
    HOSTNAME = 'hostname',
    INC = 'inc',
    GATEWAY_LOGCONFIG = 'gateway_logConfig',
    GATEWAY_APISTATISTICSCONFIG = 'gateway_apiStatisticsConfig',
    GATEWAY_PROXYCONFIG = 'gateway_ProxyConfig',
    GATEWAY_PROXYCONFIG = 'gateway_StaticConfig',
    GATEWAY_AUTHCONFIG = 'gateway_AuthConfig',
    ERROR = {
        e401001 = {
            status = 401,
            info = {
                code = 401001,
                message = '没有找到访问令牌，请登录'
            }
        },
        e401002 = {
            status = 401,
            info = {
                code = 401002,
                message = 'token 无效或已过期'
            }
        },
        e401003 = {
            status = 401,
            info = {
                code = 401003,
                message = '当前用户已在其它地方登录，请确认'
            }
        },
        e401004 = {
            status = 401,
            info = {
                code = 401004,
                message = '当前用户密码或权限已被修改，请重新登录'
            }
        }
    }
}

return constants