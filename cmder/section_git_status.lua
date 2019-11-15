local function prepare(options, context) CONTEXT_git_status(context) end

local function hasChanges(stage)
    return
        #(stage.added) > 0 or #(stage.modified) > 0 or #(stage.deleted) > 0 or
            #(stage.renamed) > 0 or #(stage.copied) > 0
end

local function content(options, context)
    local status = context.git_status
    if not status then return nil end
    local staged = status.index
    local working = status.working
    local unmerged = status.unmerged
    local branch = status.branch
    local result = ""
    local symbols = options.symbols
    if branch.ahead > 0 and symbols.ahead then
        result = result .. symbols.ahead
    end
    if branch.behind > 0 and symbols.behind then
        result = result .. symbols.behind
    end
    if #(unmerged) > 0 and symbols.unmerged then
        result = result .. symbols.unmerged
    end
    if hasChanges(staged) and symbols.staged then
        result = result .. symbols.staged
    end
    if #(working.modified) > 0 and symbols.modified then
        result = result .. symbols.modified
    end
    if #(working.deleted) > 0 and symbols.deleted then
        result = result .. symbols.deleted
    end
    if #(working.added) > 0 and symbols.untracked then
        result = result .. symbols.untracked
    end
    if result ~= "" then return options.before .. result .. options.after end
    return nil
end

local section = {
    name = "git-status",
    prepare = prepare,
    content = content,
    options = {
        leader = " ",
        foreground = COLOR_Red,
        bold = true,
        before = "[",
        after = "]",
        symbols = {
            ahead = "↑",
            behind = "↓",
            staged = "⌂",
            modified = "⌥",
            deleted = "✘",
            untracked = "?",
            unmerged = "‼"
        }
    }
}

SECTION_register(section)
