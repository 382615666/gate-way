local lor = require("libs.lor.index")
local routes = require('routes.index')
local interceptors = require('interceptors')
local utils = require('utils.index')
local cjson = require('cjson')
local app = lor()

-- 增强
app:use(interceptors.coreConfig)
app:use(interceptors.reqParams)
-- 日志
app:use(interceptors.log)
-- open api 调用统计
app:use(interceptors.openApiConfig)
-- 静态资源
app:use(interceptors.staticConfig)
-- 反向代理
app:use(interceptors.proxyConfig)

routes(app)

-- 未定义的路由不进入中间件
-- local getUrlPath = function()
--     local strs = utils:split(ngx.var.request_uri, '?')
--     local result = string.gsub(strs[1], '%%(%x%x)', function (h)
--          return string.char(tonumber(h, 16)) 
--     end)
--     return result
-- end

-- function handler (req, res)
--     if not res.isProcess then
--         res:status(ngx.HTTP_NOT_FOUND):send('')
--     end
-- end

-- app:get(getUrlPath(), handler)
--     :post(getUrlPath(), handler)
--     :delete(getUrlPath(), handler)
--     :put(getUrlPath(), handler)
--     :options(getUrlPath(), handler)
--     :head(getUrlPath(), handler)

app:use('/', function (req, res, next)
    ngx.log(ngx.ERR, '/')
    next()
end)

app:erroruse(function(err, req, res, next)
    ngx.log(ngx.ERR, err)
    if not req:is_found() then
        res:status(ngx.HTTP_NOT_FOUND):send('')
        return
    end
    res:status(ngx.HTTP_INTERNAL_SERVER_ERROR):send('')
end)

app:run()