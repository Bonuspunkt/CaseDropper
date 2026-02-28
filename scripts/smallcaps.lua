-- smallcaps.lua: Lowercase Latin → Unicode small capitals URL rewriting
-- Maps lowercase letters to their small capital Unicode equivalents
-- https://fsymbols.com/generators/smallcaps/

local lookup = {
    ["a"] = "\xE1\xB4\x80",  -- ᴀ U+1D00
    ["b"] = "\xCA\x99",      -- ʙ U+0299
    ["c"] = "\xE1\xB4\x84",  -- ᴄ U+1D04
    ["d"] = "\xE1\xB4\x85",  -- ᴅ U+1D05
    ["e"] = "\xE1\xB4\x87",  -- ᴇ U+1D07
    ["f"] = "\xEA\x9C\xB0",  -- ꜰ U+A730
    ["g"] = "\xC9\xA2",      -- ɢ U+0262
    ["h"] = "\xCA\x9C",      -- ʜ U+029C
    ["i"] = "\xC9\xAA",      -- ɪ U+026A
    ["j"] = "\xE1\xB4\x8A",  -- ᴊ U+1D0A
    ["k"] = "\xE1\xB4\x8B",  -- ᴋ U+1D0B
    ["l"] = "\xCA\x9F",      -- ʟ U+029F
    ["m"] = "\xE1\xB4\x8D",  -- ᴍ U+1D0D
    ["n"] = "\xC9\xB4",      -- ɴ U+0274
    ["o"] = "\xE1\xB4\x8F",  -- ᴏ U+1D0F
    ["p"] = "\xE1\xB4\x98",  -- ᴘ U+1D18
    ["r"] = "\xCA\x80",      -- ʀ U+0280
    ["s"] = "\xEA\x9C\xB1",  -- ꜱ U+A731
    ["t"] = "\xE1\xB4\x9B",  -- ᴛ U+1D1B
    ["u"] = "\xE1\xB4\x9C",  -- ᴜ U+1D1C
    ["v"] = "\xE1\xB4\xA0",  -- ᴠ U+1D20
    ["w"] = "\xE1\xB4\xA1",  -- ᴡ U+1D21
    ["y"] = "\xCA\x8F",      -- ʏ U+028F
    ["z"] = "\xE1\xB4\xA2",  -- ᴢ U+1D22
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

    -- Transform directory segments
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

    -- Transform only the stem
    for i = 1, #stem do
        local ch = stem:sub(i, i)
        result[#result + 1] = lookup[ch] or ch
    end
    result[#result + 1] = ext

    local rewritten = table.concat(result)
    if rewritten == path then return nil end
    return rewritten
end
