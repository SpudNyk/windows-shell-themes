local function get_npm_package_info(path)
    local filepath = path .. '\\package.json'
    local json_file = io.open(filepath)
    if not json_file then return nil end

    local content = json_file:read('*a')
    json_file:close()
    local name = string.match(content, '"name"%s*:%s*"(%g-)"')
    local version = string.match(content, '"version"%s*:%s*"(.-)"')
    return {root = path, file = filepath, name = name, version = version}
end

function CONTEXT_npm_package(context)
    local npm_package = context.npm_package
    if npm_package == false then return nil end
    if npm_package ~= nil then return npm_package end
    local package = FILE_closest_parent_info(context.cwd, get_npm_package_info)
    if not package then context.npm_package = false end
    context.npm_package = package
    return package
end

local function prepare(options, context) CONTEXT_npm_package(context) end

local function content(options, context)
    local package = context.npm_package
    if package then
        local name = package.name
        local version = package.version
        local text = nil
        local symbols = options.symbols
        if options.showName and name ~= '' then
            if options.showVersion and version ~= "" then
                local separator = (symbols and symbols.separator) or "@"
                text = name .. separator .. version
            else
                text = name
            end
        else
            if options.showVersion and version ~= "" then
                local prefix = (symbols and symbols.versionOnly) or ""
                text = prefix .. version
            end
        end

        if text and symbols and symbols.package then
            return symbols.package .. " " .. text
        end
        return text
    end
    return nil
end

local section = {
    name = "npm",
    prepare = prepare,
    content = content,
    options = {
        leader = " is ",
        symbols = {package = "", separator = "@", versionOnly = "v"},
        foreground = COLOR_Green,
        showName = true,
        showVersion = true
    }
}

SECTION_register(section)
