module GenieCacheFileCache

import Serialization
import GenieCache


const CACHE_PATH = Ref{String}(Base.Filesystem.mktempdir(prefix="jl_genie_cache_"))


"""
    cache_path()

Returns the default path of the cache folder.
"""
function cache_path()
  CACHE_PATH[]
end


"""
    cache_path!(cachepath::AbstractString)

Sets the default path of the cache folder.
"""
function cache_path!(cachepath::AbstractString)
  CACHE_PATH[] = cachepath
end


"""
    cache_path(key::Any; dir::String = "") :: String

Computes the path to a cache `key` based on current cache settings.
"""
function cache_path(key::Any; dir::String = "") :: String
  path = joinpath(cache_path(), dir)
  ! isdir(path) && mkpath(path)

  joinpath(path, string(key))
end


#===#
# INTERFACE #


"""
    tocache(key::Any, content::Any; dir::String = "") :: Nothing

Persists `content` onto the file system under the `key` key.
"""
function GenieCache.tocache(key::Any, content::Any; dir::String = "", expiration::Int = GenieCache.cache_duration()) :: Nothing
  open(cache_path(string(key), dir = dir), "w") do io
    Serialization.serialize(io, content)
  end

  nothing
end


"""
    fromcache(key::Any, expiration::Int; dir::String = "") :: Union{Nothing,Any}

Retrieves from cache the object stored under the `key` key if the `expiration` delta (in seconds) is in the future.
"""
function GenieCache.fromcache(key::Any; dir::String = "", expiration::Int = GenieCache.cache_duration()) :: Union{Nothing,Any}
  file_path = cache_path(string(key), dir = dir)

  expiration > 0 && ( ! isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return nothing

  try
    open(file_path) do io
      Serialization.deserialize(io)
    end
  catch ex
    @warn ex
    nothing
  end
end


"""
    purge(key::Any) :: Nothing

Removes the cache data stored under the `key` key.
"""
function GenieCache.purge(key::Any; dir::String = "") :: Nothing
  rm(cache_path(GenieCache.cachekey(string(key)), dir = dir))

  nothing
end


"""
    purgeall(; dir::String = "") :: Nothing

Removes all cached data.
"""
function GenieCache.purgeall(; dir::String = "") :: Nothing
  rm(cache_path("", dir = dir), recursive = true)
  mkpath(cache_path("", dir = dir))

  nothing
end

end
