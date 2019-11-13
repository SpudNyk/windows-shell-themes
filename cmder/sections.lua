-- Manage Prompt Sections
-- Sections Consist of a table with properties
local sections = {}

local function merge(t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

local function sectionContent(section, options, context)
    local text = section.content(options, context)
    if text then
        if type(text) == "table" then return text end
        if text ~= "" then
            if not options then options = {} end
            -- include core options fore each section
            return {
                title = nil,
                path = nil,
                text = text,
                foreground = options.foreground,
                background = options.background,
                bold = options.bold,
                leader = options.leader
            }
        end
    end
    return nil
end

local function empty() return nil end

local function getOptions(section, options)
    local combined = (section and section.options) or {}
    -- apply any passed in options to the sections options
    if options then combined = merge(merge({}, combined), options) end
    return combined
end

-- Register a section
function SECTION_register(section) sections[section.name] = section end

-- Compile a builder against a set of options
function SECTION_compile(name, options)
    local section = sections[name]
    local compiled = {prepare = empty, content = empty}
    -- no section found return empty builder
    if not section then return compiled end
    local opts = getOptions(section, options)

    -- add section functions
    if section.prepare then
        function compiled.prepare(context)
            return section.prepare(opts, context)
        end
    end
    if section.content then
        function compiled.content(context)
            return sectionContent(section, opts, context)
        end
    end

    return compiled
end

function SECTION_content(name, options, context)
    local section = sections[name]
    if section then
        local opts = getOptions(section, options)
        return sectionContent(section, opts, context)
    end
    return nil
end
