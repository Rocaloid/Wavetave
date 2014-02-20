#  Wpp2CVDB.m
#    Shortcut for GenCVDB on Data/*.wpp.

function Wpp2CVDB(Name)
        GenCVDB(strcat("Data/", Name, ".wpp"), Name);
end

