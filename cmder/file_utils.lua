-- return parent path for specified entry (either file or directory)
function FILE_parent(path)
    local prefix = ""
    local i = path:find("[\\/:][^\\/:]*$")
    if i then prefix = path:sub(1, i - 1) end
    return prefix
end

function FILE_basename(path)
    local reversePath = string.reverse(path)
    local slashIndex = string.find(reversePath, "\\")
    return string.sub(path, string.len(path) - slashIndex + 2)
end
-- Find closest parent that returns info for the get_info or nil
function FILE_closest_parent_info(path, get_info)
    local current = path
    local next = FILE_parent(current)
    local info = get_info(current)
    while info == nil and next ~= current do
        current = next
        next = FILE_parent(current)
        info = get_info(current)
    end
    if info == nil then return nil end
    return info
end