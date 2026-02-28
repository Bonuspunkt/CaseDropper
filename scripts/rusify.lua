-- rusify.lua: Latin → Cyrillic/Ukrainian URL rewriting
-- Decoded from https://fsymbols.com/generators/rusify/ source
--
-- The original randomly picks between two variants per character.
-- We use variant 1 for deterministic URL aliases.
--
-- Digraphs are matched before single characters:
--   io → ю   IO → Ю   bi → ы   BI → Ы

local lookup = {
    -- Lowercase
    ["b"] = "\xD0\xB2",      -- в U+0432
    ["e"] = "\xD1\x94",      -- є U+0454
    ["h"] = "\xD0\xBD",      -- н U+043D
    ["i"] = "\xD1\x97",      -- ї U+0457
    ["k"] = "\xD0\xBA",      -- к U+043A
    ["m"] = "\xD0\xBC",      -- м U+043C
    ["n"] = "\xD0\xB8",      -- и U+0438
    ["o"] = "\xD0\xBE",      -- о U+043E
    ["r"] = "\xD1\x8F",      -- я U+044F
    ["s"] = "\xC5\xA1",      -- š U+0161
    ["t"] = "\xD1\x82",      -- т U+0442
    ["u"] = "\xD1\x86",      -- ц U+0446
    ["w"] = "\xD1\x88",      -- ш U+0448
    ["x"] = "\xD0\xB6",      -- ж U+0436
    ["y"] = "\xD1\x83",      -- у U+0443

    -- Uppercase
    ["A"] = "\xD0\x94",       -- Д U+0414
    ["E"] = "\xD0\x84",       -- Є U+0404
    ["G"] = "\xD0\x91",       -- Б U+0411
    ["I"] = "\xD0\x87",       -- Ї U+0407
    ["K"] = "\xD0\x9A",       -- К U+041A
    ["N"] = "\xD0\x98",       -- И U+0418
    ["O"] = "\xD0\x9E",       -- О U+041E
    ["R"] = "\xD0\xAF",       -- Я U+042F
    ["S"] = "\xE2\x82\xB4",   -- ₴ U+20B4
    ["U"] = "\xD0\xA6",       -- Ц U+0426
    ["W"] = "\xD0\xA9",       -- Щ U+0429
    ["X"] = "\xD0\x96",       -- Ж U+0416
    ["Y"] = "\xD0\xA3",       -- У U+0423

    -- Digit
    ["3"] = "\xD0\x97",       -- З U+0417
}

local digraphs = {
    { "io", "\xD1\x8E" },    -- ю U+044E
    { "IO", "\xD0\xAE" },    -- Ю U+042E
    { "bi", "\xD1\x8B" },    -- ы U+044B
    { "BI", "\xD0\xAB" },    -- Ы U+042B
}

-- Rewrite only the filename stem, preserve extension and path separators
function rewrite(path)
    -- Find the last / to isolate the filename
    local dir, filename = path:match("^(.*/)([^/]+)$")
    if not dir then
        dir = ""
        filename = path
    end

    -- Split filename into stem and extension
    local stem, ext = filename:match("^(.+)(%.%w+)$")
    if not stem then
        stem = filename
        ext = ""
    end

    -- Process directory segments
    local dir_result = process(dir, true)
    -- Process filename stem
    local stem_result = process(stem, false)

    local rewritten = dir_result .. stem_result .. ext
    if rewritten == path then return nil end
    return rewritten
end

function process(text, preserve_slash)
    local result = {}
    local i = 1
    while i <= #text do
        local ch = text:sub(i, i)

        -- Preserve path separators
        if preserve_slash and ch == "/" then
            result[#result + 1] = ch
            i = i + 1
        else
            -- Try digraphs first (2-char sequences)
            local matched = false
            if i < #text then
                local pair = text:sub(i, i + 1)
                for _, dg in ipairs(digraphs) do
                    if pair == dg[1] then
                        result[#result + 1] = dg[2]
                        i = i + 2
                        matched = true
                        break
                    end
                end
            end

            if not matched then
                result[#result + 1] = lookup[ch] or ch
                i = i + 1
            end
        end
    end
    return table.concat(result)
end
