local factory = require('controller.factory')
local parent = require('controller.parent')
local ad = {}

setmetatable(ad, {
    __index = parent
})

function ad:handler ()
    
end

factory:register('ad', ad)

