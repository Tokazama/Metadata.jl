var documenterSearchIndex = {"docs":
[{"location":"#Metadata","page":"Metadata","title":"Metadata","text":"","category":"section"},{"location":"","page":"Metadata","title":"Metadata","text":"Metadata","category":"page"},{"location":"#Metadata","page":"Metadata","title":"Metadata","text":"Metadata.jl\n\n(Image: Build Status) (Image: stable-docs) (Image: dev-docs)\n\nIntroduction\n\nThe term \"metadata\" is widely used across very different applications. Therefore, \"metadata\" may translate to very different structures and implementations in code. The Metadata package attempts to provide a generic interface for interacting with metadata in Julia that is agnostic to the exact type of metadata present. This package typically assumes metadata to be a collection of values paired to Symbol keys (e.g., AbstractDict{Symbol,Any}, NamedTuple), but metadata that doesn't perfectly fit this criteria should still work with most methods if adhering to the basic interface.\n\nAttaching Metadata\n\nThe most important method to know is attach_metadata. It's intended to give users a generic way of attaching metadata to any given type without worrying about the particulars what type is appropriate for binding metadata to a particular. For example, attaching metadata to an array should produce something that can act like an array still. Instead of requiring users to know what type is used internally (Metadata.MetaArray), an appropriate type is chosen by default and the method of accessing metadata is the same.\n\njulia> using Metadata\n\njulia> x = ones(2, 2);\n\njulia> meta = (x = 1, y = 2);\n\njulia> mx = attach_metadata(x, meta)\n2×2 attach_metadata(::Array{Float64,2}, ::NamedTuple{(:x, :y),Tuple{Int64,Int64}}\n  • metadata:\n     x = 1\n     y = 2\n)\n 1.0  1.0\n 1.0  1.0\n\njulia> mx.x\n1\n\njulia> mx.y\n2\n\njulia> attach_metadata(x, (x = 1, y = 2, suppress= [:x]))\n2×2 attach_metadata(::Array{Float64,2}, ::NamedTuple{(:x, :y, :suppress),Tuple{Int64,Int64,Array{Symbol,1}}}\n  • metadata:\n     x = <suppressed>\n     y = 2\n)\n 1.0  1.0\n 1.0  1.0\n\n\nThere are three things you should notice from the previous example:\n\nThe display is nearly identical to how the parent x would be printed. The only addition is a list of the metadata and the argument used to bind the x and meta.\nWe can access the metadata as if they were properties.\nWe can suppress the printing of any value if metadata(x, :suppress) returns a collection of symbols containing that value.\n\nThere are a limited number of interfaces that require special types for binding metadata. The rest are bound to Metadata.MetaStruct.\n\njulia> mr = attach_metadata(3//5, meta)\nattach_metadata(3//5, ::NamedTuple{(:x, :y),Tuple{Int64,Int64}})\n  • metadata:\n     x = 1\n     y = 2\n\njulia> propertynames(mr)\n(:x, :y)\n\njulia> mr.num\n3\n\njulia> mr.den\n5\n\nHere we attached the same metadata to a rational number. Again, our metadata is now considered the properties of mr, but we can still access the parent's properties.\n\nIf the type you want to attach metadata to is mutable then each instance has a unique global identifier and you may attach metadata to a global dictionary.\n\njulia> x = ones(2, 2);\n\njulia> @attach_metadata(x, meta);\n\njulia> @metadata!(x, :z, 3);\n\njulia> @metadata(x, :z)\n3\n\njulia> Pair(:x, 1) in @metadata(x)\ntrue\n\nIf users want to access all of the metadata from one structure and attach it to another they should instead use share_metadata(src, dst) or copy_metadata(src, dst).\n\njulia> mx = attach_metadata(ones(2, 2), @metadata(x));\n\njulia> mx2 = share_metadata(mx, ones(2, 2));\n\njulia> metadata(mx2) === metadata(mx)\ntrue\n\njulia> mx3 = copy_metadata(mx2, ones(2, 2));\n\njulia> metadata(mx3) === metadata(mx2)\nfalse\n\njulia> metadata(mx3) == metadata(mx2)\ntrue\n\nInterface For Specific Metadata Glue Types\n\nA new structure of type T and instance g that glues some data x to metadata m require the following methods:\n\nRequired Methods Brief Description\nMetadata.metadata(g; dim) -> m returns the metadata\nMetadata.metadata_type(::Type{T}; dim) returns the type of the metadata\nBase.parent(g) -> x returns the parent instance attached to the metadata\nMetadata.attach_metadata(x, m) -> T(x, m) returns an instance of T that has the metadata m attached to x.\n\nOptional Methods returns an instance of T that has the metadata m attached to x.\nBase.getproperty(x, k) get metadata assigned to key k\nBase.setproperty!(x, k, val) set metadata at key k to val\nBase.propertynames(x) return the keys/properties of x\n\n\n\n\n\n","category":"module"},{"location":"#Public","page":"Metadata","title":"Public","text":"","category":"section"},{"location":"","page":"Metadata","title":"Metadata","text":"Metadata.attach_metadata\nMetadata.@attach_metadata\n\nMetadata.has_metadata\nMetadata.@has_metadata\n\nMetadata.metadata\nMetadata.@metadata\n\nMetadata.metadata!\nMetadata.@metadata!\n\nMetadata.copy_metadata\nMetadata.@copy_metadata\n\nMetadata.share_metadata\nMetadata.@share_metadata\n\nMetadata.drop_metadata","category":"page"},{"location":"#Metadata.attach_metadata","page":"Metadata","title":"Metadata.attach_metadata","text":"attach_metadata(x, metadata)\n\nGeneric method for attaching metadata to x.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.@attach_metadata","page":"Metadata","title":"Metadata.@attach_metadata","text":"@attach_metadata(x, meta)\n\nAttach metadata meta to the object id of x (objectid(x)) in the current module's global metadata.\n\nSee also: GlobalMetadata\n\n\n\n\n\n","category":"macro"},{"location":"#Metadata.has_metadata","page":"Metadata","title":"Metadata.has_metadata","text":"has_metadata(x[, k; dim]) -> Bool\n\nReturns true if x has metadata. If k is specified then checks for the existence of a metadata paired to k. If dim is specified then this checks the metadata at the corresponding dimension.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.@has_metadata","page":"Metadata","title":"Metadata.@has_metadata","text":"@has_metadata(x) -> Bool\n@has_metadata(x, k) -> Bool\n\nDoes x have metadata stored in the curren modules' global metadata? Checks for the presenece of the key k if specified.\n\n\n\n\n\n","category":"macro"},{"location":"#Metadata.metadata","page":"Metadata","title":"Metadata.metadata","text":"metadata(x[, k; dim])\n\nReturns metadata from x. If k is specified then the metadata value paired to k is returned. If dim is specified then the operation is performed for metadata specific to dimension dim.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.@metadata","page":"Metadata","title":"Metadata.@metadata","text":"@metadata(x[, k])\n\nRetreive metadata associated with the object id of x (objectid(x)) in the current module's global metadata. If the key k is specified only the value associated with that key is returned.\n\n\n\n\n\n","category":"macro"},{"location":"#Metadata.metadata!","page":"Metadata","title":"Metadata.metadata!","text":"metadata!(x, k, val[; dim])\n\nSet x's metadata paired to k to val. If dim is specified then the metadata corresponding to that dimension is mutated.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.@metadata!","page":"Metadata","title":"Metadata.@metadata!","text":"@metadata!(x, k, val)\n\nSet the value of x's global metadata associated with the key k to val.\n\n\n\n\n\n","category":"macro"},{"location":"#Metadata.copy_metadata","page":"Metadata","title":"Metadata.copy_metadata","text":"copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))\n\nCopies the the metadata from src and attaches it to dst. Note that this method specifically calls deepcopy on the metadata of src to ensure that changing the metadata of dst does not affect the metadata of src.\n\nSee also: share_metadata.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.@copy_metadata","page":"Metadata","title":"Metadata.@copy_metadata","text":"@copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))\n\nCopies the metadata from src by attaching it to dst. This assumes that metadata for src is stored in a global dictionary (i.e. not part of src's structure) and attaches a new copy to dst through a global reference within the module.\n\nSee also: @share_metadata, copy_metadata\n\n\n\n\n\n","category":"macro"},{"location":"#Metadata.share_metadata","page":"Metadata","title":"Metadata.share_metadata","text":"share_metadata(src, dst) -> attach_metadata(dst, metadata(src))\n\nShares the metadata from src by attaching it to dst. The returned instance will have properties that are synchronized with src (i.e. modifying one's metadata will effect the other's metadata).\n\nSee also: copy_metadata.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.@share_metadata","page":"Metadata","title":"Metadata.@share_metadata","text":"@share_metadata(src, dst) -> @attach_metadata(@metadata(src), dst)\n\nShares the metadata from src by attaching it to dst. This assumes that metadata for src is stored in a global dictionary (i.e. not part of src's structure) and attaches it to dst through a global reference within the module.\n\nSee also: @copy_metadata, share_metadata\n\n\n\n\n\n","category":"macro"},{"location":"#Metadata.drop_metadata","page":"Metadata","title":"Metadata.drop_metadata","text":"drop_metadata(x)\n\nReturns x without metadata attached.\n\n\n\n\n\n","category":"function"},{"location":"#Internal","page":"Metadata","title":"Internal","text":"","category":"section"},{"location":"","page":"Metadata","title":"Metadata","text":"Metadata.NoMetadata\nMetadata.metadata_summary\nMetadata.MetaArray\nMetadata.MetaRange\nMetadata.MetaUnitRange\nMetadata.MetadataPropagation\nMetadata.CopyMetadata\nMetadata.DropMetadata\nMetadata.ShareMetadata","category":"page"},{"location":"#Metadata.NoMetadata","page":"Metadata","title":"Metadata.NoMetadata","text":"NoMetadata\n\nInternal type for the Metadata package that indicates the absence of any metadata. DO NOT store metadata with the value NoMetadata().\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.metadata_summary","page":"Metadata","title":"Metadata.metadata_summary","text":"metadata_summary([io], x)\n\nCreates summary readout of metadata for x.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.MetaArray","page":"Metadata","title":"Metadata.MetaArray","text":"MetaArray(parent::AbstractArray, metadata)\n\nCustom AbstractArray object to store an AbstractArray parent as well as some metadata.\n\nExamples\n\njulia> using Metadata\n\njulia> Metadata.MetaArray(ones(2,2), metadata=(m1 =1, m2=[1, 2]))\n2×2 attach_metadata(::Array{Float64,2}, ::NamedTuple{(:m1, :m2),Tuple{Int64,Array{Int64,1}}}\n  • metadata:\n     m1 = 1\n     m2 = [1, 2]\n)\n 1.0  1.0\n 1.0  1.0\n\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.MetaRange","page":"Metadata","title":"Metadata.MetaRange","text":"MetaRange(x::AbstractRange, meta)\n\nType for storing metadata alongside a range.\n\nExamples\n\njulia> using Metadata\n\njulia> Metadata.MetaRange(1:1:2, (m1 =1, m2=[1, 2]))\nattach_metadata(1:1:2, ::NamedTuple{(:m1, :m2),Tuple{Int64,Array{Int64,1}}})\n  • metadata:\n     m1 = 1\n     m2 = [1, 2]\n\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.MetaUnitRange","page":"Metadata","title":"Metadata.MetaUnitRange","text":"MetaUnitRange(x::AbstractUnitRange, meta)\n\nType for storing metadata alongside a anything that is subtype of AbstractUnitRange.\n\nExamples\n\njulia> using Metadata\n\njulia> Metadata.MetaUnitRange(1:2, (m1 =1, m2=[1, 2]))\nattach_metadata(1:2, ::NamedTuple{(:m1, :m2),Tuple{Int64,Array{Int64,1}}})\n  • metadata:\n     m1 = 1\n     m2 = [1, 2]\n\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.MetadataPropagation","page":"Metadata","title":"Metadata.MetadataPropagation","text":"MetadataPropagation(::Type{T})\n\nReturns type informing how to propagate metadata of type T. See DropMetadata, CopyMetadata, ShareMetadata.\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.CopyMetadata","page":"Metadata","title":"Metadata.CopyMetadata","text":"CopyMetadata\n\nInforms operations that may propagate metadata to attach a copy to any new instance created.\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.DropMetadata","page":"Metadata","title":"Metadata.DropMetadata","text":"DropMetadata\n\nInforms operations that may propagate metadata to insead drop it.\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.ShareMetadata","page":"Metadata","title":"Metadata.ShareMetadata","text":"ShareMetadata\n\nInforms operations that may propagate metadata to attach a the same metadata to any new instance created.\n\n\n\n\n\n","category":"type"}]
}
