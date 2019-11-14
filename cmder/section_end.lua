local function content(options) return options.symbol end

local section = {
    name = "end",
    content = content,
    options = {symbol = "→ ", leader = "\n", foreground = COLOR_Green}
}

SECTION_register(section)
