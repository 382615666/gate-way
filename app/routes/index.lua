local constants = require('utils.constants')
local cjson = require('cjson')
local ip = require('utils.ip')
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
        local config = info:get(constants.GATEWAY_CORECONFIG)
        config = cjson.decode(config)
        local body = req.body
        if config.dev then
            if (not body.host) then
                res:status(500):send('host参数不能为空')
                return
            end
            if (not body.ip) then
                res:status(500):send('ip参数不能为空')
                return
            end
            
            ip:setDevIp(body.host, body.ip)
            res:send('设置host成功')
        end
    end):get('/api/host', function (req, res)
        local config = info:get(constants.GATEWAY_CORECONFIG)
        config = cjson.decode(config)
        res:json(config)
    end)
end


return routes