local parent = require('controller.parent.refresh')
local refresh = {
    name = 'refresh'
}

setmetatable(refresh, {
    __index = parent
})

function refresh:handler (gateway)
    if self:isProcess(gateway.state, gateway.req) then
        self:work(gateway.req, gateway.res, gateway.option)
    end
end

return refresh