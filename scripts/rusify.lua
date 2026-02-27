-- rusify.lua: Latin → Cyrillic homoglyph URL rewriting
-- Maps visually similar Latin characters to their Cyrillic equivalents
-- https://fsymbols.com/generators/rusify/

local lookup = {
    ["a"] = "\xD0\xB0",  -- а
    ["c"] = "\xD1\x81",  -- с
    ["e"] = "\xD0\xB5",  -- е
    ["o"] = "\xD0\xBE",  -- о
    ["p"] = "\xD1\x80",  -- р
    ["x"] = "\xD1\x85",  -- х
    ["y"] = "\xD1\x83",  -- у
    ["k"] = "\xD0\xBA",  -- к
    ["A"] = "\xD0\x90",  -- А
    ["B"] = "\xD0\x92",  -- В
    ["C"] = "\xD0\xA1",  -- С
    ["E"] = "\xD0\x95",  -- Е
    ["H"] = "\xD0\x9D",  -- Н
    ["K"] = "\xD0\x9A",  -- К
    ["M"] = "\xD0\x9C",  -- М
    ["O"] = "\xD0\x9E",  -- О
    ["P"] = "\xD0\xA0",  -- Р
    ["T"] = "\xD0\xA2",  -- Т
    ["X"] = "\xD0\xA5",  -- Х
    ["Y"] = "\xD0\xA3",  -- У
}

-- Rewrite only the filename stem, preserve extension and path separators
function rewrite(path)
    local result = {}
    -- Find the last / to isolate the filename
    local dir, filename = path:match("^(.*/)([^/]+)$")
    if not dir then
        dir = ""
        filename = path
    end

    -- Rusify directory segments
    for i = 1, #dir do
        local ch = dir:sub(i, i)
        if ch == "/" then
            result[#result + 1] = ch
        else
            result[#result + 1] = lookup[ch] or ch
        end
    end

    -- Split filename into stem and extension
    local stem, ext = filename:match("^(.+)(%.%w+)$")
    if not stem then
        stem = filename
        ext = ""
    end

    -- Rusify only the stem
    for i = 1, #stem do
        local ch = stem:sub(i, i)
        result[#result + 1] = lookup[ch] or ch
    end
    result[#result + 1] = ext

    local rewritten = table.concat(result)
    if rewritten == path then return nil end
    return rewritten
end
