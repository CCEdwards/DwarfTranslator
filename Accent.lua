local _, addon = ...

local replacements = {
    you = "ye", your = "yer", yours = "yers", yourself = "yerself",
    yourselves = "yerselves", ["you're"] = "ye're", ["you've"] = "ye've",
    ["you'll"] = "ye'll", ["you'd"] = "ye'd", yes = "aye", yeah = "aye",
    yep = "aye", nope = "nae", ["can't"] = "cannae",
    to = "te", ["for"] = "fer", with = "wi'", without = "wi'out",
    of = "o'", ["and"] = "an'", my = "mi", hello = "hullo",
    little = "wee", friend = "mate", friends = "mates",
    before = "ere", today = "todae", shit = "shite", shitty = "shite",
    fuck = "fook", fucking = "fookin'", ass = "arse", asshole = "arsehole",
    about = "'bout",
    family = "kin",
    ["isn't"] = "ain't", is = "be", fucker = "fooker", fuckass = "fookarse",
    -- Deliberate verb list: never strip every -ing word.
    going = "goin'", coming = "comin'", looking = "lookin'", fighting = "fightin'",
    drinking = "drinkin'", running = "runnin'", waiting = "waitin'",
    getting = "gettin'", doing = "doin'", talking = "talkin'", trying = "tryin'",
    nothing = "nothin'", something = "somethin'", know = "ken",
    small = "wee", very = "right",
}
local function caseLike(word, replacement)
    if word == word:upper() then return replacement:upper() end
    if word:sub(1, 1):match("%u") then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end
local function prose(text, keep)
    -- Include digits/UTF-8 bytes in tokens so identifiers and non-English words
    -- containing an English substring are never partially rewritten.
    return (text:gsub("[%w_\128-\255]+['\226\128\153]*[%w_\128-\255']*", function(word)
        local key = word:gsub("\226\128\153", "'"):lower()
        if keep and keep[key] then return word end
        local replacement = replacements[key]
        return replacement and caseLike(word, replacement) or word
    end))
end

function addon.Convert(text, keep)
    if type(text) ~= "string" or text == "" or text:match("^%s*/") then return text end
    local result, plain, i = {}, {}, 1
    local function flush()
        if #plain > 0 then
            result[#result + 1] = prose(table.concat(plain), keep)
            plain = {}
        end
    end
    while i <= #text do
        local tail = text:sub(i)
        local protected
        if tail:sub(1, 1) == "|" then
            protected = tail:match("^|H.-|h.-|h")
                or tail:match("^|c%x%x%x%x%x%x%x%x.-|r")
                or tail:match("^|T.-|t") or tail:match("^|A.-|a")
                or tail:match("^||") or tail:match("^|r")
            -- Unrecognized/incomplete markup: preserve the rest conservatively.
            protected = protected or tail
        elseif tail:sub(1, 1) == "{" then
            protected = tail:match("^%b{}") -- raid markers
        elseif tail:sub(1, 1) == "[" then
            protected = tail:match("^%b[]") -- unlinked item names too
        elseif tail:sub(1, 1) == "`" then
            protected = tail:match("^`[^`]*`") -- preserve literal text
        end
        if not protected then
            local token = tail:match("^%S+")
            if token and (token:find("://", 1, true) or token:match("^www%.")
                or token:find("@", 1, true) or token:match("^[%w%-]+%.[%a][%a]+[/%.%?]?")
                or token:match("^%%[%a]")) then
                protected = token
            end
        end
        if protected then
            flush()
            result[#result + 1] = protected
            i = i + #protected
        else
            plain[#plain + 1] = text:sub(i, i)
            i = i + 1
        end
    end
    flush()
    return table.concat(result)
end

