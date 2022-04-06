


tm = attach_metadata((1,2.0), :foo)
@test tm == (1,2.0)
@test @inferred(Base.tail((1,2.0))) == (2.0,)
@test @inferred(Base.front((1,2.0))) == @inferred(Base.front((1,2.0))) == (1.0,)

