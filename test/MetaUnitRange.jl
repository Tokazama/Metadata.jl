
x = 1:10
mx = Metadata.test_wrapper(Metadata.MetaUnitRange, x)
@test mx[1] == 1
@test mx[1:2] == [1, 2]
@test metadata(mx[1:2]) == metadata(mx)
@test @inferred(first(x)) == first(mx)
@test @inferred(step(x)) == step(mx)
@test @inferred(last(x)) == last(mx)
@test @inferred(length(mx)) == length(x)
@test ArrayInterface.known_first(mx) === ArrayInterface.known_first(x)
@test ArrayInterface.known_last(mx) === ArrayInterface.known_last(x)
@test ArrayInterface.known_step(mx) === ArrayInterface.known_step(x)
@test mx[1:2:10] == x[1:2:10]
@test mx[:] == x[:]
Metadata.test_wrapper(Metadata.MetaUnitRange, 1:10)

