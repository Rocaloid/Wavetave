/*  DeterministicSynth.cc
      Synthesizes the deterministic component of the sound from Amp & Freq
        matrices.
*/

#include <octave/oct.h>
#include <math.h>
#include <stdio.h>
#include <malloc.h>

//Ret = DeterministicSynth(PeakBuffer_Amp, PeakBuffer_Freq,
//                         InitialPhase, PeakNum, HopSize);
DEFUN_DLD (DeterministicSynth, args, nargout, "")
{
    NDArray PeakBuffer_Amp = args(0).array_value();
    NDArray PeakBuffer_Freq = args(1).array_value();
    NDArray InitialPhase = args(2).array_value();
    int PeakNum = args(3).int_value();
    int HopSize = args(4).int_value();
    int WinNum = PeakBuffer_Freq.rows();
    int i, j, k;

    NDArray SynthesisWave;
    SynthesisWave.resize1(HopSize * (WinNum + 10));
    int SynthIndex = 0;

    double Phase[200];
    for(i = 0; i < PeakNum; i ++)
        Phase[i] = InitialPhase(i + 1);

    //Avoid 0Hz initial transition.
    for(k = 0; k < PeakNum; k ++)
    {
        if(PeakBuffer_Freq(0, k) < 50)
        {
            //PeakBuffer_Freq(0, k) = PeakBuffer_Freq(1, k);
            PeakBuffer_Amp(0, k) = 0;
        }
    }
        
    //For each control point.
    for(i = 0; i < WinNum - 1; i ++)
    {
        //printf("> %d\n", i);
        
        //Avoid 0Hz transition.
        for(k = 0; k < PeakNum; k ++)
        {
            if(PeakBuffer_Freq(i + 1, k) < 50)
            {
                PeakBuffer_Freq(i + 1, k) = PeakBuffer_Freq(i, k);
                PeakBuffer_Amp(i + 1, k) = 0;
            }
        }
        
        //For each sample.
        for(j = 0; j < HopSize; j ++)
        {
            double TransRatio = (double)j / HopSize;
            double Accumulator = 0;
            
            //For each sinusoid.
            for(k = 0; k < PeakNum; k ++)
            {
                double PhaseIncrement = 2.0 * 3.1415926 / 44100.0 * 
                    (PeakBuffer_Freq(i, k) * (1.0 - TransRatio) + 
                     PeakBuffer_Freq(i + 1, k) * TransRatio);
                Accumulator += cos(Phase[k]) *
                    (PeakBuffer_Amp(i, k) * (1.0 - TransRatio) + 
                     PeakBuffer_Amp(i + 1, k) * TransRatio);
                Phase[k] += PhaseIncrement;
            }
            SynthesisWave(SynthIndex) = Accumulator;
            SynthIndex ++;
        }
    }

    return octave_value(SynthesisWave);
}

