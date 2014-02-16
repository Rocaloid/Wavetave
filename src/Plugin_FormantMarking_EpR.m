#  Plugin_FormantMarking_EpR.m
#    Interactive interface for marking formant envelope manually with
#    Excitation plus Resonance Model.
#
#  Reference
#    Bonada, Jordi, et al. "Singing voice synthesis combining excitation plus
#    resonance and sinusoidal plus residual models." Proceedings of
#    International Computer Music Conference. 2001.

function Plugin_FormantMarking_EpR(Spectrum)
        global FFTSize;
        global SampleRate;
        figure(2);
        
        #Spectrum display range.
        global SpectrumLowerRange;
        global SpectrumUpperRange;
        global DBLowerRange;
        global DBUpperRange;
        LBound = fix(FFTSize / SampleRate * SpectrumLowerRange);
        UBound = fix(FFTSize / SampleRate * SpectrumUpperRange);
        
        printf("Plugin_FormantMarking_EpR\n");
        fflush(stdout);
        
        #Initialization
        N = 5;
        Freq      = [0   , 1200, 1800, 3300, 5000]; #Hz
        BandWidth = [300 , 400 , 300 , 700 , 500 ]; #Hz
        Amp       = [0  ,  0.5 , -7  , - 10, - 10]; #DB
        
        Button_Up   = 1009;
        Button_Down = 1011;
        Button_A = 97;
        Button_D = 100;
        Spectrum = Spectrum';
        
        #Generate Slope
        Slope = ExpDecay(25, 90, - 1, FFTSize / 2);
        #Spectrum = Spectrum - Slope;
        
        NSelect = 1;
        while(1)
                Prompt(NSelect, Freq, BandWidth, Amp);
                
                #Background spectrum
                plot(Spectrum);
                hold on;
                
                Resonance = zeros(1, FFTSize / 2);
                #Generate and overlap Klatt Filters.
                for i = 1 : N
                        ResN = KlattFilter(Freq(i), BandWidth(i),
                                           10 ^ (Amp(i) / 20),
                                           SampleRate, FFTSize);
                        Resonance += ResN;
                        plot(20 * log10(ResN), 'g');
                        text(Freq(i) / SampleRate * FFTSize, Amp(i),
                             cstrcat("X ", mat2str(fix(Freq(i))), "Hz"));
                        text(Freq(i) / SampleRate * FFTSize, Amp(i) + 2,
                             cstrcat("F", mat2str(i - 1)));
                end
                #Plot overlapped resonances.
                plot(20 * log10(Resonance), 'r');
                axis([LBound, UBound, DBLowerRange, DBUpperRange]);
                
                #Interaction
                hold off;
                [X, Y, Button] = ginput(1);
                if(Button == 1)
                        if(X < 0)
                                X = 0;
                        end
                        Freq(NSelect) = X / FFTSize * SampleRate;
                        Amp(NSelect)  = Y;
                elseif(Button == Button_D)
                        BandWidth(NSelect) += 50;
                elseif(Button == Button_A)
                        if(BandWidth(NSelect) > 50)
                                BandWidth(NSelect) -= 50;
                        end
                elseif(Button > 47 && Button < 58)
                        #Num Key
                        if(Button - 48 + 1 <= N)
                                NSelect = Button - 48 + 1;
                        end
                elseif(Button == - 1)
                        #Save
                        save("Formant.epr", "Freq", "BandWidth", "Amp", "N");
                        printf("Saved to Formant.epr.\n");
                        break;
                end
        end
        figure(1);
end

function Prompt(NSelect, Freq, BandWidth, Amp)
        clc;
        printf("Selected formant: %d\n", NSelect - 1);
        printf("  Central Frequency: %dHz\n", fix(Freq(NSelect)));
        printf("  Band Width: %dHz\n", fix(BandWidth(NSelect)));
        printf("  Relative Amplitude: %.1fDB\n\n", fix(Amp(NSelect) * 10) / 10);
        
        printf("    (0 ~ 9) Select formant.\n");
        printf("  (L-Click) Change freq & amp.\n");
        printf("        (D) Increase band width.\n");
        printf("        (A) Decrease band width.\n");
        printf("        (Q) Quit & Save.\n");
        fflush(stdout);
end

