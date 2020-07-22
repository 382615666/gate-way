local cjson = require('cjson')
local t = {
    a = 1
}

print(type(cjson.encode(t)))
