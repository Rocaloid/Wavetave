#  Plugin_PhaseFigure.m
#    This plugin plots out the phase spectrum of a FFTSize-size fourier
#      transform at the center of the visible area.

function Plugin_PhaseFigure(Spectrum, Phase, Wave)
        global FFTSize;
        global SampleRate;

        global SpectrumLowerRange;
        global SpectrumUpperRange;

        figure(3);
        plot(Phase);
        title("Phase");
        axis([FFTSize / SampleRate * SpectrumLowerRange, FFTSize / SampleRate * SpectrumUpperRange, - pi, pi]);
        figure(1);
end

