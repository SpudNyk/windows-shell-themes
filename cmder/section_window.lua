local function contextTitle(cwd, options, context)
    if not options then return nil end
    context = context[options.context]
    if not context then return nil end
    local title = context
    if options.title then title = context[options.title] end
    if not title or title == "" then return nil end
    if options.before then title = options.before .. title end
    if options.after then title = title .. options.after end
    return title
end

local function content(options, context)
    -- fullpath
    local cwd = context.cwd

    local contexts = options.contexts
    local contextOptions = options.contextOptions

    for i, name in pairs(contexts) do
        local title = contextTitle(cwd, contextOptions[name], context)
        if title then return {title = title, path = cwd} end
    end

    return {path = cwd}
end

local section = {
    name = "window",
    content = content,
    options = {
        -- contexts applied in the order given, first one wins
        contexts = {"npm", "git", "path"},
        contextOptions = {
            path = {context = "name"},
            npm = {
                context = "npm_package",
                title = "name",
                before = "Package: ",
                after = ""
            },
            git = {
                context = "git_dir_info",
                title = "name",
                before = "",
                after = ""
            }
        }
    }
}

SECTION_register(section)
