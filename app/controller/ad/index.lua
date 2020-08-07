local factory = require('controller.factory')
local gateway = require('controller.parent.gateway')
local ad = {}

setmetatable(ad, {
    __index = gateway
})

function ad:handler ()
    self:prepare()

end

function ad:prepare ()
    local token = Token:get()
    if not token then
        return false
    end
    local payload = Token:decode(token, false, self.option.key)
    if payload then
        local empids = {}
        local entids = {}
        if payload.ids then
          for index, item in ipairs(payload.ids) do
              table.insert(empids, item.employeeId)
              table.insert(entids, item.partnerId)
          end
        end
        self.req.auth = {
            userId = payload.uid, -- 用户 id 
            device = payload.device,
            sign = payload.sign,  -- 登录签名信息
            ids = payload.ids
        }
        ngx.req.set_header("user-id", payload.uid)
        ngx.req.set_header("emp-ids", cjson.encode(empids))
        ngx.req.set_header("ent-ids", cjson.encode(entids))
    end
end


factory:register('ad', ad)

