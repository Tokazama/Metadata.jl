


tm = attach_metadata((1,2.0), :foo)

@test length(tm) == 2
@test tm[:] == tm
@test tm == (1,2.0)
@test () == @inferred(empty(tm))
@test @inferred(Base.tail(tm)) == (2.0,)
@test @inferred(Base.front(tm)) == @inferred(Base.front((1,2.0))) == (1.0,)

t1, state = iterate(tm)
@test t1 == tm[1]

t2, state = iterate(tm, state)
@test t2 == get(tm, 2, nothing)
@test get(tm, 3, nothing) === nothing

