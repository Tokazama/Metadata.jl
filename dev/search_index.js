var documenterSearchIndex = {"docs":
[{"location":"#Metadata","page":"Metadata","title":"Metadata","text":"","category":"section"},{"location":"#Public","page":"Metadata","title":"Public","text":"","category":"section"},{"location":"","page":"Metadata","title":"Metadata","text":"Metadata.attach_metadata\nMetadata.has_metadata\nMetadata.metadata\nMetadata.metadata!\nMetadata.copy_metadata\nMetadata.drop_metadata\nMetadata.share_metadata","category":"page"},{"location":"#Metadata.attach_metadata","page":"Metadata","title":"Metadata.attach_metadata","text":"attach_metadata(x, metadata)\n\nGeneric method for attaching metadata to x.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.has_metadata","page":"Metadata","title":"Metadata.has_metadata","text":"has_metadata(x[, k; dim]) -> Bool\n\nReturns true if x has metadata. If k is specified then checks for the existence of a metadata paired to k. If dim is specified then this checks the metadata at the corresponding dimension.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.metadata","page":"Metadata","title":"Metadata.metadata","text":"metadata(x[, k; dim])\n\nReturns metadata from x. If k is specified then the metadata value paired to k is returned. If dim is specified then the operation is performed for metadata specific to dimension dim.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.metadata!","page":"Metadata","title":"Metadata.metadata!","text":"metadata!(x, k, val[; dim])\n\nSet x's metadata paired to k to val. If dim is specified then the metadata corresponding to that dimension is mutated.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.copy_metadata","page":"Metadata","title":"Metadata.copy_metadata","text":"copy_metadata(src, dst) -> attach_metadata(dst, copy(metadata(src)))\n\nCopies the the metadata from src and attaches it to dst. Note that this method specifically calls deepcopy on the metadata of src to ensure that changing the metadata of dst does not affect the metadata of src.\n\nSee also: share_metadata.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.drop_metadata","page":"Metadata","title":"Metadata.drop_metadata","text":"drop_metadata(x)\n\nReturns x without metadata attached.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.share_metadata","page":"Metadata","title":"Metadata.share_metadata","text":"share_metadata(src, dst) -> attach_metadata(dst, metadata(src))\n\nShares the metadata from src by attaching it to dst. The returned instance will have properties that are synchronized with src (i.e. modifying one's metadata will effect the other's metadata).\n\nSee also: copy_metadata.\n\n\n\n\n\n","category":"function"},{"location":"#Internal","page":"Metadata","title":"Internal","text":"","category":"section"},{"location":"","page":"Metadata","title":"Metadata","text":"Metadata.NoMetadata\nMetadata.MetadataPropagation\nMetadata.metadata_summary\nMetadata.MetaArray\nMetadata.MetaRange\nMetadata.MetaUnitRange","category":"page"},{"location":"#Metadata.NoMetadata","page":"Metadata","title":"Metadata.NoMetadata","text":"NoMetadata\n\nInternal type for the Metadata package that indicates the absence of any metadata. DO NOT store metadata with the value NoMetadata().\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.MetadataPropagation","page":"Metadata","title":"Metadata.MetadataPropagation","text":"MetadataPropagation(::Type{T}) -> Union{Drop,Copy,Share}\n\nWhen metadata of type T is attached to something should the same in memory instance be attached or a deep copy of the metadata?\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.metadata_summary","page":"Metadata","title":"Metadata.metadata_summary","text":"metadata_summary(x; left_pad::Int=0, l1=lpad(`•`, 3), l2=lpad('-', 5))\n\nCreates summary readout of metadata for x.\n\n\n\n\n\n","category":"function"},{"location":"#Metadata.MetaArray","page":"Metadata","title":"Metadata.MetaArray","text":"MetaArray(parent::AbstractArray, metadata)\n\nCustom AbstractArray object to store an AbstractArray parent as well as some metadata.\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.MetaRange","page":"Metadata","title":"Metadata.MetaRange","text":"MetaRange(x::AbstractRange, meta)\n\nType for storing metadata alongside a range.\n\n\n\n\n\n","category":"type"},{"location":"#Metadata.MetaUnitRange","page":"Metadata","title":"Metadata.MetaUnitRange","text":"MetaUnitRange(x::AbstractUnitRange, meta)\n\nType for storing metadata alongside a anything that is subtype of AbstractUnitRange.\n\n\n\n\n\n","category":"type"}]
}
