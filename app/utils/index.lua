local utils = {}

function utils:split(str, delimeter)
    str = str or ''
    local result = {}
    local values = string.gmatch(str, '[^' .. delimeter ..']+')

    for value in values do
        table.insert(result, value)
    end

    return result
end

return utils