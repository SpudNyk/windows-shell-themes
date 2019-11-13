local function content() return os.date("%H:%M:%S") end

local section = {
    name = "time",
    content = content,
    options = {leader = " at ", foreground = COLOR_Yellow, bold = true}
}

SECTION_register(section)
