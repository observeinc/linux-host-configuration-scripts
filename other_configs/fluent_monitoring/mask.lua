function mask_sensitive_info(tag, timestamp, record)
    message = record["log"]
    if message then

        -- Match lines with token pattern accepting lower-case or upper-case characters as first letters
        -- Capture everything before colon with one group and everything after with second group
        local pattern = "(.-[Aa]uthorization%s+[Bb]earer%s+.-):(.*)$"

        -- Define the replacement string - second group replaced by stars
        local replacement = "%1:************"
        
        -- Perform the match and replace
        local result = message:gsub(pattern, replacement)

        record["log"] = result
    end
    -- replace original record but keep timestamp
    return 2, timestamp, record
end