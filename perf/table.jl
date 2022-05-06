function print_row(c, name, ss)
    print("|", c)
    print(lpad(name, 18, c))
    for s in ss
        print(c, "|", c)
        print(lpad(s, 10, c))
    end
    println(c, "|")
end
_print(::Nothing) = ""
_print(::BenchmarkTools.Trial) = BenchmarkTools.prettytime(time(b))
function prettyprint(name, bs::BenchmarkTools.Trial)
    print_row(
        name,
        ' ',
        _print.(bs)
    )
end

function prettyprint(bs, ns)
    print_row("", ' ', ns)
    print_row("", ' ', fill("", length(ns)))
    for b in bs
        prettyprint(b[1], b[2])
    end
end
