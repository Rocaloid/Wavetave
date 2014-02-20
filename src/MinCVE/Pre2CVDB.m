#  Pre2CVDB.m
#    Shortcut for Preprocess then Wpp2CVDB.

function Pre2CVDB(Path, Name)
        Preprocess(Path, Name);
        Wpp2CVDB(Name);
end

