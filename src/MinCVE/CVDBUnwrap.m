#  CVDBUnwrap.m
#    Interger to float conversion snippet.

global CVDB_Residual;
global CVDB_Sinusoid_Magn;
global CVDB_Sinusoid_Freq;
global CVDB_Wave;
CVDB_Residual = double(CVDB_Residual - 60) / 12;
CVDB_Sinusoid_Magn = double(CVDB_Sinusoid_Magn) / 1000;
CVDB_Sinusoid_Freq = double(CVDB_Sinusoid_Freq) / 6;
CVDB_Wave = double(CVDB_Wave) / 32767;

