local uuid = require('libs.resty.jit-uuid')
local constants = require('utils.constants')
local info = ngx.shared.info
local utils = {}

function utils:split (str, delimeter)
    str = str or ''
    local result = {}
    local values = string.gmatch(str, '[^' .. delimeter ..']+')

    for value in values do
        table.insert(result, value)
    end

    return result
end

function utils:buildUUID ()
    return uuid.generate_v5(uuid(), self:getHostname() .. self.getInc())
end

function utils:getHostname ()
    local hostname = info:get(constants.HOSTNAME)
    if not hostname then
        local result = io:popen('cat /etc/home')
        hostname = result:read('*all')
        info:set(constants.HOSTNAME, hostname)
    end

    return hostname
end

function utils:getInc ()
    local result = info:incr(constants.INC, 1, 0)
    result = result or 0
    return result
end

return utils