using Documenter

push!(LOAD_PATH,  "../../src")

using GenieCacheFileCache

makedocs(
    sitename = "GenieCacheFileCache - File Caching for Genie",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Home" => "index.md",
        "GenieCacheFileCache API" => [
          "GenieCacheFileCache" => "api/geniecachefilecache.md",
        ]
    ],
)

deploydocs(
  repo = "github.com/GenieFramework/GenieCacheFileCache.jl.git",
)
