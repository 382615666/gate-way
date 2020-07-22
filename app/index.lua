local lor = require("libs.lor.index")
local routes = require('routes.index')
local interceptors = require('interceptors')
local cjson = require('cjson')
local app = lor()

app:use(interceptors.coreConfig)

routes(app)

app:erroruse(function(err, req, res, next)
    ngx.log(ngx.ERR, err)
    res:status(500):send("服务器内发生未知错误")
end)

app:run()