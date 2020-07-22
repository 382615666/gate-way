local lor = require("libs.lor.index")
local routes = require('routes.index')
local cjson = require('cjson')
local app = lor()

routes(app)

app:use(function (req, res, next)
    local t = {
        a = 1
    }
    ngx.log(ngx.ERR, type(cjson.decode(cjson.encode(t))))
end)

app:run()