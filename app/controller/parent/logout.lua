local logout = {}

function logout:isProcess (state, req)
    return state.name == self.name and string.lower(req.path) == '/api/logout' 
end

function logout:work(req, res)
    res.isProcess = true
    ngx.header['content-type'] = 'application/json'
    res:send('用户注销成功')
end

return logout