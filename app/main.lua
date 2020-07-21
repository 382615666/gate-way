local lor = require("libs.lor.index")
local app = lor()

app:get('/', function (req, res, next)
    res:send('111')
end)

app:run()