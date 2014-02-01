#  GenCVDB.m
#    DataBase content generator.
#  Depends on various Plugins.
#
#    Not finished yet.

function Ret = GenCVDB(Path)
        addpath("../");

        global FFTSize;
        global SampleRate;
        global Window;
        global Environment;
        global OrigWave;
        global Length;

        global Plugin_Var_VOT;

        FFTSize = 2048;
        Environment = "Procedure";
        WindowFunc = @hanning;

        [OrigWave, SampleRate] = wavread(Path);
        Length = length(OrigWave);

        Plugin_VOTMarking(OrigWave);
        Plugin_Var_VOT
end

