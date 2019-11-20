local function content(options, context)
    if context.is_admin then return options.symbol end
    return ""
end

local section = {
    name = "admin",
    content = content,
    options = {
        leader = " ",
        symbol = "⚡",
        foreground = COLOR_Red,
        bold = true
    }
}

SECTION_register(section)
