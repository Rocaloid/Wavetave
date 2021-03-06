#{
    Title: Plugin_Freq2Pitch
    
    Converts frequency to pitch and displays.
    
    Function: Plugin_Freq2Pitch
    
    Parameters:
    
        None.

    Input Global Variables:
        
        <FFTSize>
        
        <SampleRate>
            
        <Plugin_Var_F0_Exact>

    Output Global Variables:
    
        None.
    
    Dependency:
    
        Plugin_F0Marking_ByPhase
#}
function Plugin_Freq2Pitch()
        global FFTSize;
        global SampleRate;
        global Plugin_Var_F0_Exact;
        F0 = Plugin_Var_F0_Exact;

        #When data is valid
        if(F0 > 5)
                Pitch = 69 + 12 * log2(F0 / 440);
                Str = Pitch2Shierlv(Pitch);
                disp(Str)
        end
        fflush(stdout);
end

#        C C#(Db) D D#(Eb) E F F#(Gb) G G#(Ab) A A#(Bb) B
function Ret = Pitch2Shierlv(Pitch)
        Shierlv = ["C"; "C#(Db)"; "D"; "D#(Eb)"; "E"; "F"; "F#(Gb)"; "G";
                   "G#(Ab)"; "A"; "A#(Bb)"; "B";];
        s = fix(round(Pitch) / 12);
        id = mod(round(Pitch), 12) + 1;
        Ret = strcat(Shierlv(id, :), mat2str(s - 1));
end

