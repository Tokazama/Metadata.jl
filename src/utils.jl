
function _construct_meta(meta::AbstractDict{Symbol}, kwargs::NamedTuple)
    for (k, v) in kwargs
        meta[k] = v
    end
    return meta
end
_construct_meta(meta::Nothing, kwargs::NamedTuple) = kwargs

function _construct_meta(meta, kwargs::NamedTuple)
    if isempty(kwargs)
        return meta
    else
        error("Cannot assign key word arguments to metadata of type $T")
    end
end

