local function prepare(options, context) CONTEXT_git_branch(context) end

local function content(options, context)
    local branch = context.git_branch
    if branch then return options.symbol .. " " .. branch end
    return ""
end

local section = {
    name = "git-branch",
    prepare = prepare,
    content = content,
    options = {
        leader = " on ",
        symbol = "",
        foreground = COLOR_Magenta,
        bold = true
    }
}

SECTION_register(section)
