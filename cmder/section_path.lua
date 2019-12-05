-- "full" for full path like collapses home directory
local pathTypeFull = "full"
-- "folder" for folder name only like System32
local pathTypeFolder = "folder"

local function pathReplace(path, leader, replace)
    local gsub = string.gsub
    -- anchor to the start and escape any special pattern chars
    leader = "^" .. gsub(leader, "[%%%]%^%-$().[*+?]", "%%%1")
    -- ensure replace is escaped properly
    replace = gsub(replace, "%%", "%%%%")
    return gsub(path, leader, replace)
end

local function contextContent(cwd, options, context)
    if not options then return nil end
    context = context[options.context]
    if not context then return nil end
    local dir = nil
    if options.dir then
        dir = context[options.dir]
    else
        dir = context
    end
    if not dir then return nil end
    local text = options.text and context[options.text]
    if not text then
        if options.placeholder then
            text = options.placeholder
        else
            text = ""
        end
    end
    if options.before then text = options.before .. text end
    if options.after then text = text .. options.after end
    return pathReplace(cwd, dir, text)
end

local function content(options, context)
    -- fullpath
    local cwd = context.cwd

    -- show just current folder
    if options.type == pathTypeFolder then
        return FILE_basename(cwd)
    else
        local contexts = options.contexts
        local contextOptions = options.contextOptions
        for i, name in pairs(contexts) do
            local text = contextContent(cwd, contextOptions[name], context)
            if text then return text end
        end
    end

    return cwd
end

local section = {
    name = "path",
    content = content,
    options = {
        leader = " in ",
        type = pathTypeFull,
        -- contexts applied in the order given, first one wins
        contexts = {"npm", "git", "home"},
        contextOptions = {
            home = {context = "home", placeholder = "~"},
            npm = {
                context = "npm_package",
                dir = "root",
                text = "name",
                placeholder = "npm",
                before = UTF8char(0xf8d6) .. " ",
                after = ""
            },
            git = {
                context = "git_dir_info",
                dir = "root",
                text = "name",
                placeholder = "git",
                before = UTF8char(0xf1d2) .. " ",
                after = ""
            }
        }
    }
}

SECTION_register(section)
