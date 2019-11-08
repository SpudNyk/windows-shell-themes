local function prepare(options, context) CONTEXT_git_status(context) end

local function statusContent(status)
    if not status then return nil end
    return {
        text = status.text,
        leader = status.leader or " ",
        foreground = status.foreground,
        background = status.background
    }
end

local function content(options, context)
    local statuses = options.statuses
    if not statuses then return nil end
    local status = context.git_status
    if status and statuses[status] then
        return statusContent(statuses[status])
    end
    return nil
end

local section = {
    name = "git-status",
    prepare = prepare,
    content = content,
    options = {
        statuses = {
            clean = {text = "", foreground = COLOR_Green},
            dirty = {text = "±", foreground = COLOR_Yellow},
            conflict = {text = "!", foreground = COLOR_Red}
        }
    }
}

SECTION_register(section)
