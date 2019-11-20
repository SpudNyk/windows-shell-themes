local function handleBranch(line, branch)
    local key, value = line:match("^# branch%.(%w+) (.*)")
    if not key then return end
    if key == "oid" then
        branch.id = value
    elseif key == "head" then
        branch.name = value
    elseif key == "upstream" then
        branch.upstream = value
    elseif key == "ab" then
        local ahead, behind = value:match('%+(%d+) %-(%d+)')
        branch.ahead = tonumber(ahead, 10)
        branch.behind = tonumber(behind, 10)
    end
end

local function parseHeader(line, status)
    if line:match("^#") then
        handleBranch(line, status.branch)
        return true
    end
    return false
end
-- <sub> <mH> <mI> <mW> <hH> <hI>
local modeField = "[0-7]+"
local objectNameField = "%x+"
local statusChar = "[.MADRCU]"
-- captures statuses for index and working
local statusField = "(" .. statusChar .. ")(" .. statusChar .. ")"
local submoduleField = "[NS][.C][.M][.U]"

-- build patterns
local normalPattern = table.concat({
    "^1", -- leader
    statusField, -- index [1] and working [2] status
    submoduleField, -- submodule state
    modeField, -- mode head
    modeField, -- mode index
    modeField, -- mode working
    objectNameField, -- object name head
    objectNameField, -- object name index
    "(.*)$" -- path to file (captured) [3]
}, " ")

local renamedPattern = table.concat({
    "^2", -- leader
    statusField, -- index [1] and working [2] status 
    submoduleField, -- submodule state
    modeField, -- mode head
    modeField, -- mode index
    modeField, -- mode working
    objectNameField, -- object name head
    objectNameField, -- object name index
    "[RC](%d+)", -- rename/copy score [3]
    "(.*)\t(.*)$" -- path to destination [4] from source [5]
}, " ")

-- merge pattern
local unmergedPattern = table.concat({
    "^u", -- leader
    statusField, -- index [1] and working [2] status
    submoduleField, -- submodule state
    modeField, -- mode stage 1
    modeField, -- mode stage 2
    modeField, -- mode stage 3
    modeField, -- mode working
    objectNameField, -- object name stage 1
    objectNameField, -- object name stage 2
    objectNameField, -- object name stage 3
    "(.*)$" -- path to file (captured) [3]
}, " ")

local function addStatePath(status, state, path, renamedFrom, renameScore)
    if state == "." then return end
    if state == "A" then
        table.insert(status.added, path)
    elseif state == "M" then
        table.insert(status.modified, path)
    elseif state == "D" then
        table.insert(status.deleted, path)
    elseif state == "R" then
        table.insert(status.renamed,
                     {path = path, from = renamedFrom, score = renameScore})
    elseif state == "C" then
        table.insert(status.copied,
                     {path = path, from = renamedFrom, score = renameScore})
    end
end

local function handleNormal(line, status)
    local index, working, path = line:match(normalPattern)
    if not path then return false end
    addStatePath(status.index, index, path)
    addStatePath(status.working, working, path)
    return true
end

local function handleRenamed(line, status)
    local index, working, score, path, from = line:match(renamedPattern)
    if not path then return false end
    addStatePath(status.index, index, path, from, score)
    addStatePath(status.working, working, path, from, score)
    return true
end

local function handleUnmerged(line, status)
    local _, _, path = line:match(unmergedPattern)
    if not path then return false end
    table.insert(status.unmerged, path)
    return true
end

local function handleUntracked(line, status)
    local kind, path = line:match("^([?!]) (.*)$")
    if not path then return false end
    if kind == "?" then
        table.insert(status.working.added, path)
    else
        table.insert(status.ignored, path)
    end
    return true
end

local function parseBody(line, status)
    -- if handleStatus(line, status) then end
    if handleNormal(line, status) then return true end
    if handleRenamed(line, status) then return true end
    if handleUnmerged(line, status) then return true end
    if handleUntracked(line, status) then return true end
    return true
end

local function consume(file, fn, startLine)
    local line = startLine or file:read("*l")
    while line and fn(line) do line = file:read("*l") end
    return line
end

local function parser(fn, context)
    local function parse(line) return fn(line, context) end
    return parse
end

local function createStatus()
    return {added = {}, modified = {}, deleted = {}, renamed = {}, copied = {}}
end

-- get the git status (renames/copies are tracked as modifies and deletes)
function GIT_status(trackRenamed, untracked, ignored)
    local status = {
        -- branch information
        branch = {
            -- branch commit id
            id = nil,
            -- name of branch
            name = nil,
            -- upstream branch
            upstream = nil,
            -- commits ahead and behind
            ahead = 0,
            behind = 0
        },
        -- staged status
        index = createStatus(),
        -- working status (untracked files are under added)
        working = createStatus(),
        -- unmerged
        unmerged = {},
        ignored = {}
    }

    local gitCmd = "git status --porcelain=2 --branch"
    -- track renames by default - overide users git config
    if trackRenamed or trackRenamed == nil then
        gitCmd = gitCmd .. " --renames"
    else
        gitCmd = gitCmd .. " --no-renames"
    end

    if untracked == nil or untracked == true then
        untracked = "all"
    elseif untracked == false then
        untracked = "no"
    end

    gitCmd = gitCmd .. " --untracked-files=" .. untracked

    if not ignored then
        ignored = "no"
    elseif ignored == true then
        ignored = "traditional"
    end

    gitCmd = gitCmd .. " --ignored=" .. ignored .. " 2>nul"

    local output = io.popen(gitCmd)
    local headers = parser(parseHeader, status)
    local body = parser(parseBody, status)
    local unprocessed = consume(output, headers)
    if unprocessed then unprocessed = consume(output, body, unprocessed) end
    output:close()

    return status
end
