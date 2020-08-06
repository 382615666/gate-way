local factory = {}

local object = {}


function object:register (name, object)
    factory[name] = object
end

function object:getGateway (name)
    return factory[name]
end

return object