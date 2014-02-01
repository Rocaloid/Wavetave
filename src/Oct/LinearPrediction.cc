/*
* LinearPrediction.cc
* Copyright (C) 2013 Sleepwalking
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* 1. Redistributions of source code must retain the above copyright
*    notice, this list of conditions and the following disclaimer.
* 2. Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
* 3. Neither the name ``Sleepwalking'' nor the name of any other
*    contributor may be used to endorse or promote products derived
*    from this software without specific prior written permission.
*
* CVEDSP IS PROVIDED BY Sleepwalking ``AS IS'' AND ANY EXPRESS
* OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL Sleepwalking OR ANY OTHER CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
//From CVEDSP/DSPBase/LPC.c

#include <malloc.h>
#include <octave/oct.h>
#include <stdio.h>

void FloatSet(float* Dest, float Data, int Amount)
{
    int i;
    for(i = 0; i < Amount - 7; i += 8)
    {
        Dest[i + 0] = Data;
        Dest[i + 1] = Data;
        Dest[i + 2] = Data;
        Dest[i + 3] = Data;
        Dest[i + 4] = Data;
        Dest[i + 5] = Data;
        Dest[i + 6] = Data;
        Dest[i + 7] = Data;
    }
    for(; i < Amount; i ++)
        Dest[i] = Data;
}

//Adapted from
//http://www.emptyloop.com/technotes/A%20tutorial%20on%20linear%20prediction%20and%20Levinson-Durbin.pdf
void LPCFromWave(float* Dest, float* Src, int Length, int CoefNum)
{
    int i, j;
    float E, Lambda, Tmp;
    float* R = (float*)malloc(sizeof(float) * CoefNum);
    FloatSet(R, 0, CoefNum);
    FloatSet(Dest, 0, CoefNum);

    //Auto-Correlation
    for(i = 0; i < CoefNum; i ++)
    {
        for(j = 0; j < Length; j ++)
            R[i] += Src[j] * Src[j + i];
    }

    //Initial Condition
    Dest[0] = 1;
    E = R[0];

    //Levinson-Durbin Recursion
    for(i = 0; i < CoefNum - 1; i ++)
    {
        Lambda = 0;
        for(j = 0; j <= i; j ++)
            Lambda -= Dest[j] * R[i + 1 - j];
        Lambda /= E;

        for(j = 0; j <= (i + 1) / 2; j ++)
        {
            Tmp = Dest[i + 1 - j] + Lambda * Dest[j];
            Dest[j] += Lambda * Dest[i + 1 - j];
            Dest[i + 1 - j] = Tmp;
        }

        E *= 1.0f - Lambda * Lambda;
    }
    free(R);
}

//Ret = LinearPrediction(Wave, CoefNum);
DEFUN_DLD (LinearPrediction, args, nargout, "")
{
    int i;
    NDArray Wave = args(0).array_value();
    int CoefNum = args(1).int_value();
    int WaveSize = Wave.length();

    float* TmpRet  = (float*)malloc(sizeof(float) * CoefNum);
    float* TmpWave = (float*)malloc(sizeof(float) * WaveSize * 2);
    FloatSet(TmpWave + WaveSize, 0, WaveSize);
    for(i = 0; i < WaveSize; i ++)
        TmpWave[i] = Wave(i + 1);

    LPCFromWave(TmpRet, TmpWave, WaveSize, CoefNum);

    Wave.resize1(CoefNum);
    for(i = 0; i < CoefNum; i ++)
        Wave(i + 1) = TmpRet[CoefNum - i - 1];

    free(TmpRet);
    free(TmpWave);
    return octave_value(Wave);
}

