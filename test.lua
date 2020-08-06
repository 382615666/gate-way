local a = {
    a = 1
}

function a:test ()
    print(self.b)
end

local b = {
    b = 2
}

setmetatable(b, {
    __index = a
})


b:test()


