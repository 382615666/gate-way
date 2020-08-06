local lor = require("libs.lor.index")
local routes = require('routes.index')
local interceptors = require('utils.interceptors')
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
-- 认证
app:use(interceptors.authConfig)
-- 静态资源
app:use(interceptors.staticConfig)
-- 反向代理
app:use(interceptors.proxyConfig)
--h5中间件
app:use(interceptors.h5Config)

routes.routes(app)

local getUrlPath = function()
    local strs = utils:split(ngx.var.request_uri, '?')
    local result = string.gsub(strs[1], '%%(%x%x)', function (h)
         return string.char(tonumber(h, 16)) 
    end)
    return result
end

function handler (req, res)
    if not res.isProcess then
        res:status(ngx.HTTP_NOT_FOUND):send('')
    end
end

local domainPath = getUrlPath()
-- 未定义的路由不进入中间件
function handlerUnExistRouter (url)
    local result = true
    local method = string.lower(ngx.req.get_method())
    local existRoutes = routes.routers[method] 
    if existRoutes then
        for index, item in ipairs(existRoutes) do
            if item == url then
                result = false
                break
            end
        end
    end
    if result then
        if method == 'post' then
            app:post(url, handler)
        elseif method == 'get' then
            app:get(url, handler)
        elseif method == 'delete' then
            app:delete(url, handler)
        elseif method == 'put' then
            app:put(url, handler)
        elseif method == 'options' then
            app:options(url, handler)
        elseif method == 'head' then
            app:head(url, handler)
        end
    end
end

handlerUnExistRouter(domainPath)

app:erroruse(function(err, req, res, next)
    ngx.log(ngx.ERR, err)
    if not req:is_found() then
        res:status(ngx.HTTP_NOT_FOUND):send('')
        return
    end
    res:status(ngx.HTTP_INTERNAL_SERVER_ERROR):send('')
end)

app:run()