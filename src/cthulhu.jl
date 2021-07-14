function ci_tapir(b::Cthulhu.Bookmark)
    ci, = code_typed(b)
    return Core.Compiler.lower_tapir(b.mi, ci)
end

function ircode_tapir(b::Cthulhu.Bookmark)
    ci, = code_typed(b)
    return Core.Compiler.lower_tapir_to_ircode(b.mi, ci)
end
