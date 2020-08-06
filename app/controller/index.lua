require('controller.ad.index')
local factory = require('controller.factory')
local controller = {}

function controller:init (req, res, options)
    local gateway = factory:getGateway(options.type)
    return gateway:init(req, res, options)
end

return controller

