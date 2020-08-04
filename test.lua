local a = {
    a = 1
}

local b = {}

setmetatable(b, {
    __index = a
})

print(b.a)

local c = {}

setmetatable(c, {
    __index = a
})

print(c.a)

b.a = 2

print(b.a, c.a)

b.a = nil

print(b.a)