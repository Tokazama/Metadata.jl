
io = IOBuffer()
mio = Metadata.test_wrapper(Metadata.MetaIO, io)

@test position(mio) == 0
@test !isreadonly(mio)
@test isreadable(mio)
@test iswritable(mio)
@test isopen(mio)
@test !ismarked(mio)

s = sizeof(Int)
write(mio, 1)
@test position(mio) == s
seek(mio, 0)
@test read(mio, Int) == 1
seek(mio, 0)
write(mio, [1, 2])
write(mio, view([1 , 2], :))
write(mio, [1,2]')
seek(mio, 0)
@test read!(mio, Vector{Int}(undef, 2)) == [1, 2]
skip(mio, s)
@test position(mio) == 3s
mark(mio)
@test ismarked(mio)
seek(mio, 0)
@test reset(mio) == 3s
@test position(mio) == 3s
mark(mio)
@test ismarked(mio)
unmark(mio)
@test !ismarked(mio)
seekend(mio)
@test eof(mio)
close(mio)
@test !isopen(mio)

