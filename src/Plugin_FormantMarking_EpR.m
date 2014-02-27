#  Plugin_FormantMarking_EpR.m
#    Interactive interface for marking formant envelope manually with
#    Excitation plus Resonance Model.
#
#  Reference
#    Bonada, Jordi, et al. "Singing voice synthesis combining excitation plus
#    resonance and sinusoidal plus residual models." Proceedings of
#    International Computer Music Conference. 2001.
#
#  Depends on KlattFilter, Plugin_F0Marking_ByPhase and
#    Plugin_HarmonicMarking_Naive.

function Plugin_FormantMarking_EpR(Spectrum)
        global FFTSize;
        global SampleRate;
        global Environment;
        
        #This plugin is also used by MinCVE/EpRFit.
        if(strcmp(Environment, "Visual"))
                figure(2);
        end
        
        #Spectrum display range.
        global SpectrumLowerRange;
        global SpectrumUpperRange;
        global DBLowerRange;
        global DBUpperRange;
        LBound = fix(FFTSize / SampleRate * SpectrumLowerRange);
        UBound = fix(FFTSize / SampleRate * SpectrumUpperRange);
        
        #Shared parameters.
        global Plugin_Var_EpR_N;
        global Plugin_Var_EpR_Freq;
        global Plugin_Var_EpR_BandWidth;
        global Plugin_Var_EpR_Amp;
        global Plugin_Var_EpR_ANT1;
        global Plugin_Var_EpR_ANT2;
        
        printf("Plugin_FormantMarking_EpR\n");
        fflush(stdout);
        
        #Initialization
        N = Plugin_Var_EpR_N;
        Freq = Plugin_Var_EpR_Freq;
        BandWidth = Plugin_Var_EpR_BandWidth;
        Amp = Plugin_Var_EpR_Amp;
        ANT1 = Plugin_Var_EpR_ANT1;
        ANT2 = Plugin_Var_EpR_ANT2;
        
        Button_Up   = 1009;
        Button_Down = 1011;
        Button_A = 97;
        Button_D = 100;
        Button_LB = 91;
        Button_RB = 93;
        Spectrum = Spectrum';
        
        #Normalize (disabled)
        #Strength = sum(10 .^ (Spectrum(1 : 100) / 20));
        #Factor = 100 / Strength;
        #Spectrum *= Factor;
        
        #Linear decay slope (disabled)
        #global SpectrumUpperRange;
        #global Plugin_Var_Harmonics_Freq;
        #global Plugin_Var_Harmonics_Magn;
        #SpectrumUpperRange_ = SpectrumUpperRange;
        #SpectrumUpperRange  = 5000;
        #Plugin_HarmonicMarking_Naive(Spectrum);
        #SpectrumUpperRange  = SpectrumUpperRange_;
        #Coef = polyfit(Plugin_Var_Harmonics_Freq,
        #               Plugin_Var_Harmonics_Magn, 1);
        
        #Pre-emphasis slope (0.1DB/bin for fft-2048).
        Coef(1) = - 0.1;
        Coef(2) = 0;
        Slope = Coef(2) + (1 : length(Spectrum)) * Coef(1);
        Spectrum = Spectrum - Slope;
        
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
                
                #Center of Anti-resonances
                ANT1Pos = fix(ANT1.Freq / SampleRate * FFTSize);
                ANT2Pos = fix(ANT2.Freq / SampleRate * FFTSize);
                #Original spectral amplitude
                Amp1 = Resonance(ANT1Pos);
                Amp2 = Resonance(ANT2Pos);
                #New linear amplitude
                Magn1 = 10 ^ ((20 * log10(Amp1) - ANT1.Amp) / 20);
                Magn2 = 10 ^ ((20 * log10(Amp2) - ANT2.Amp) / 20);
                #Klatt Filter linear amplitude
                KAmp1 = 1 - Magn1 / Amp1;
                KAmp2 = 1 - Magn2 / Amp2;
                
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
                        BandWidth(NSelect) *= 1.2;
                elseif(Button == Button_A)
                        BandWidth(NSelect) /= 1.2;
                        #if(BandWidth(NSelect) > 50)
                        #        BandWidth(NSelect) -= 50;
                        #end
                elseif(Button > 47 && Button < 58)
                        #Num Key
                        if(Button - 48 + 1 <= N)
                                NSelect = Button - 48 + 1;
                        end
                elseif(Button == - 1)
                        #Save
                        if(strcmp(Environment, "Visual"))
                                save("Formant.epr", "Freq", "BandWidth",
                                     "Amp", "Coef", "N");
	                        print(strcat("/tmp/EpR/", "Filter.jpg"));
                                printf("Saved to Formant.epr.\n");
                        end
                        break;
                end
        end
        #This plugin is also used by MinCVE/EpRFit.
        if(strcmp(Environment, "Visual"))
                figure(1);
        end
        
        #Dump back
        Plugin_Var_EpR_N = N;
        Plugin_Var_EpR_Freq = Freq;
        Plugin_Var_EpR_BandWidth = BandWidth;
        Plugin_Var_EpR_Amp = Amp;
        Plugin_Var_EpR_ANT1 = ANT1;
        Plugin_Var_EpR_ANT2 = ANT2;
end

function Prompt(NSelect, Freq, BandWidth, Amp)
        #clc;
        printf("Selected formant: %d\n", NSelect - 1);
        printf("  Central Frequency: %dHz\n", fix(Freq(NSelect)));
        printf("  Band Width: %dHz\n", fix(BandWidth(NSelect)));
        printf("  Relative Amplitude: %.1fDB\n\n",
            fix(Amp(NSelect) * 10) / 10);
        
        printf("    (0 ~ 9) Select formant.\n");
        printf("  (L-Click) Change freq & amp.\n");
        printf("        (D) Increase band width.\n");
        printf("        (A) Decrease band width.\n");
        printf("        (Q) Quit & Save.\n");
        fflush(stdout);
end

