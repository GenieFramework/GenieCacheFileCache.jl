module GenieCacheFileCache

import Serialization
import GenieCache

"""
    tocache(key::Any, content::Any; dir::String = "") :: Nothing

Persists `content` onto the file system under the `key` key.
"""
function tocache(key::Any, content::Any; dir::String = "") :: Nothing
  open(cache_path(string(key), dir = dir), "w") do io
    Serialization.serialize(io, content)
  end

  nothing
end


"""
    fromcache(key::Any, expiration::Int; dir::String = "") :: Union{Nothing,Any}

Retrieves from cache the object stored under the `key` key if the `expiration` delta (in seconds) is in the future.
"""
function fromcache(key::Any, expiration::Int; dir::String = "") :: Union{Nothing,Any}
  file_path = cache_path(string(key), dir = dir)

  ( ! isfile(file_path) || stat(file_path).ctime + expiration < time() ) && return nothing

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
    cache_path(key::Any; dir::String = "") :: String

Computes the path to a cache `key` based on current cache settings.
"""
function cache_path(key::Any; dir::String = "") :: String
  path = joinpath(GenieCache.cache_path(), dir)
  ! isdir(path) && mkpath(path)

  joinpath(path, string(key))
end


#===#
# INTERFACE #


"""
    withcache(f::Function, key::Any, expiration::Int = GenieCache.cache_duration(); dir = "", condition::Bool = true)

Executes the function `f` and stores the result into the cache for the duration (in seconds) of `expiration`. Next time the function is invoked,
if the cache has not expired, the cached result is returned skipping the function execution.
The optional `dir` param is used to designate the folder where the cache will be stored (within the configured cache folder).
If `condition` is `false` caching will be skipped.
"""
function GenieCache.withcache(f::Function, key::Any, expiration::Int = GenieCache.cache_duration(); dir::String = "", condition::Bool = true)
  ( expiration == 0 || ! condition ) && return f()

  cached_data = fromcache(GenieCache.cachekey(string(key)), expiration, dir = dir)

  if cached_data === nothing
    output = f()
    tocache(GenieCache.cachekey(string(key)), output, dir = dir)

    return output
  end

  cached_data
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
