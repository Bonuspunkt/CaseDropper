-- rusify.lua: Latin → Cyrillic/Ukrainian URL rewriting
-- Full character substitution as per https://fsymbols.com/generators/rusify/

local lookup = {
    -- Uppercase
    ["A"] = "\xD0\x94",  -- Д U+0414
    ["E"] = "\xD0\x84",  -- Є U+0404
    ["G"] = "\xD0\x91",  -- Б U+0411
    ["I"] = "\xD0\x87",  -- Ї U+0407
    ["K"] = "\xD0\x9A",  -- К U+041A
    ["N"] = "\xD0\x98",  -- И U+0418
    ["O"] = "\xD0\x9E",  -- О U+041E
    ["R"] = "\xD0\xAF",  -- Я U+042F
    ["S"] = "\xE2\x82\xB4",  -- ₴ U+20B4
    ["U"] = "\xD0\xA6",  -- Ц U+0426
    ["W"] = "\xD0\xA8",  -- Ш U+0428
    ["Y"] = "\xD0\x8F",  -- Џ U+040F

    -- Lowercase
    ["b"] = "\xD0\xAC",  -- Ь U+042C
    ["e"] = "\xD1\x91",  -- ё U+0451
    ["h"] = "\xD0\xBD",  -- н U+043D
    ["i"] = "\xD1\x97",  -- ї U+0457
    ["k"] = "\xD0\xBA",  -- к U+043A
    ["m"] = "\xD0\xBC",  -- м U+043C
    ["n"] = "\xD0\xB8",  -- и U+0438
    ["o"] = "\xD0\xBE",  -- о U+043E
    ["r"] = "\xD1\x8F",  -- я U+044F
    ["t"] = "\xD1\x82",  -- т U+0442
    ["u"] = "\xD1\x86",  -- ц U+0446
    ["w"] = "\xD1\x88",  -- ш U+0448
    ["y"] = "\xD1\x83",  -- у U+0443
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
