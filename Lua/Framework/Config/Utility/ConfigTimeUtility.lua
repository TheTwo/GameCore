local ConfigTimeUtility = {
    SecToNs = 10 ^ 9,
}

function ConfigTimeUtility.NsToSeconds(ns)
    return ns / ConfigTimeUtility.SecToNs
end

return ConfigTimeUtility