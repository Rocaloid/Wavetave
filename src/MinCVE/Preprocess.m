#  Preprocess.m
#    Normalize and store under Data/

#  We have two ways to normalize:
#    Uncomment lines ending with [1] to enable spectrum-sum normalization.
#    Uncomment lines ending with [2] to enable max peak normalization.

#  Depends on STFTAnalysis, STFTSynthesis, Plugin_VOTMarking.

function Preprocess(Path, Name)
        global FFTSize;
        global HopSize;
        global Window;
        global SampleRate;
        
        addpath('../');
        addpath('../Oct');
        addpath('../Util');
        
        #Initialization
        [Wave, SampleRate] = wavread(Path);
        FFTSize = 2048;
        HopSize = 512;
        Window = hamming(FFTSize)';
        
        #Spectrum content under this freq is sumed as normalization factor.
        UpperFreq = 1000;
        #Target magnitude.
        TargetMagn = 0.7;
        
        UpperBin = fix(UpperFreq * FFTSize / SampleRate);
        
        #STFT Frame generation & Getting normalization factor.
        global Plugin_Var_VOT;
        Plugin_VOTMarking(Wave);
        CFrames = STFTAnalysis(Wave, Window, FFTSize, HopSize);
        
        #10 frames after VOT should be stable.
        MidFrame = fix(Plugin_Var_VOT / HopSize + 10);
        #VoiceFrame = abs(CFrames(MidFrame, : )); #[1]
        VoiceFrame = real(ifft(CFrames(MidFrame, : ))); #[2]
        #Magnitude = sum(VoiceFrame(1 : UpperBin)); #[1]
        Magnitude = max(VoiceFrame ./ Window); #[2]
        
        MagnFactor = TargetMagn / Magnitude;
        
        #The separated amplification of frames before VOT is for conservation
        #  of the voice onset envelope.
        for i = 1 : MidFrame
                CFrames(i, : ) *= MagnFactor;
        end
        for i = MidFrame + 1 : rows(CFrames)
                VoiceFrame = real(ifft(CFrames(i, : ))); #[2]
                Magnitude = max(VoiceFrame ./ Window); #[2]
                #Magnitude = sum(abs(CFrames(i, : )(1 : UpperBin))); #[1]
                MagnFactor = TargetMagn / Magnitude;
                CFrames(i, : ) *= MagnFactor;
        end
        
        NewWave = STFTSynthesis(CFrames, Window, FFTSize, HopSize);
        wavwrite(NewWave, SampleRate, strcat("Data/", Name, ".wpp"));
end

