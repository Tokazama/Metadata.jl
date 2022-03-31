# MetadataInterface

`MetadataInterface` provides a basic interface for working with metadata in Julia.
The term "metadata" is widely used across very different applications.
Therefore, the term "metadata" may imply very different things depending on the context it is used in.
Herein, "metadata" refers to any data that provides information about other data.
Although somewhat vague, this distinction is useful.
For example, let us assume `x` is an array and `m` is metadata attached to `x` and the bound instance of these two is `mx` (`Wrapper(x, m) -> xm`).
Methods like sorting, indexing, reduction, etc performed on `mx` are done with respect to `x`.
`m` may provide useful information for how to perform these methods, but it is not the focus of these methods.

The relationship between data and metadata is formalized with the concept of attributes.
Metadata can only have one attribute associating it with the data it is bound to.
However, data may have multiple attributes, each associated with metadata.

