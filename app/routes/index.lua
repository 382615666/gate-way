local constants = require('utils.constants')
local cjson = require('cjson')
local info = ngx.shared.info

function routes (app)
    app:get('/api/version', function (req, res)
        ngx.header['content-type'] = 'application/json'
        res:json(req.version)
    end)

    app:get('/echo', function (req, res)
        res:send('gateway is ok!')
    end)

    app:post('/api/host', function (req, res)
        
    end):get('/api/host', function (req, res)
        local config = info:get(constants.GATEWAY_CORECONFIG)
        config = cjson.decode(config)
        res:json(config)
    end)
end


return routes