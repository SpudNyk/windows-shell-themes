local function isAdmin()
    -- this command will fail if not in an admin shell
    local pipe = io.popen('net session 2>nul')
    pipe:read("*all")
    return pipe:close() == true
end

local function prepare(options, context)
    if context.is_admin == nil then context.is_admin = isAdmin() end
    return context.is_admin
end

local function content(options, context)
    if context.is_admin then return options.symbol end
    return ""
end

local section = {
    name = "admin",
    prepare = prepare,
    content = content,
    options = {
        leader = " ",
        symbol = "⚡",
        foreground = COLOR_Red,
        bold = true
    }
}

SECTION_register(section)
