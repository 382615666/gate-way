local a = {
    1,
    2,
    3
}

for i, item in ipairs(a) do
    print(item)
    if item == 2 then
        break
    end
end