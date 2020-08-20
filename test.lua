local a = {
    1,
    2,
    3,
    4
}

for index in ipairs(a) do
    print(index)
    if index == 2 then
        break
    end
end