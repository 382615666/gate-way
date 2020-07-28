local lor = require("libs.lor.index")
local routes = require('routes.index')
local interceptors = require('interceptors')
local cjson = require('cjson')
local app = lor()

app:use(interceptors.coreConfig)
app:use(interceptors.reqParams)
app:use(interceptors.log)

routes(app)

app:erroruse(function(err, req, res, next)
    ngx.log(ngx.ERR, err)
    if not req:is_found() then
        res:status(ngx.HTTP_NOT_FOUND):send('404')
        return
    end
    res:status(ngx.HTTP_INTERNAL_SERVER_ERROR):send('500')
end)

app:run()