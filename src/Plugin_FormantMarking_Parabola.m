#  Plugin_FormantMarking_Parabola.m
#    Interactive interface for marking formant envelope manually with piecewise
#    parabola functions.

function Plugin_FormantMarking_Parabola()
        global FFTSize;
        figure(2);
        hold on;
        
        PeakY = zeros(10, 1);
        PeakX = zeros(10, 1);
        ValleyX = zeros(10, 1);
        ValleyY = zeros(10, 1);
        N = 4;
        
        Env = zeros(FFTSize, 1);
        
        #Peak0
        [X, Y] = GetMouseClick();
        X = 0;
        PeakY(1) = Y;
        text(X, Y, '\^');
        printf("Peak0: %f, %f\n", X, Y);
        fflush(stdout);
        
        #Three formants
        for i = 1 : N
                #Valley i
                [X, Y] = GetMouseClick();
                ValleyY(i) = Y;
                ValleyX(i) = X;
                text(X, Y, '\_');
                printf("Valley%d: %f, %f\n", i - 1, X, Y);
                fflush(stdout);
                
                #Peak i + 1
                [X, Y] = GetMouseClick();
                PeakY(i + 1) = Y;
                PeakX(i + 1) = X;
                text(X, Y, '\^');
                printf("Peak%d: %f, %f\n", i, X, Y);
                fflush(stdout);
                
                Env = ParabolaToArray(Env, PeakX(i), PeakY(i),
                                           ValleyX(i), ValleyY(i),
                                           PeakX(i + 1), PeakY(i + 1));
                plot(Env(1 : fix(PeakX(i + 1))));
        end
        
        save("Formant.fmt", "PeakY", "PeakX", "ValleyY", "ValleyX", "N");
        printf("Saved.\n");
        fflush(stdout);
        
        Env = ParabolaInterpolate(PeakX, PeakY, ValleyX, ValleyY, 
                                  4, 300, - 12, FFTSize);
        plot(Env);
        
        [X, Y] = GetMouseClick();
        hold off;
        figure(1);
end

function [a0, a1, a2] = GenQuadratic(x0, y0, x1, y1, x2, y2)
	o = x0 ^ 2 - x1 ^ 2;
	p = x1 ^ 2 - x2 ^ 2;
	m = x0 - x1;
	n = x1 - x2;
	u = y0 - y1;
	v = y1 - y2;

	a0 = (v * m - n * u) / (m * p - n * o);
	a1 = (u - a0 * o) / m;
	a2 = y0 - a1 * x0 - a0 * (x0 ^ 2);
end

function Ret = ParabolaToArray(Arr, P0X, P0Y, VX, VY, P1X, P1Y)
	if P0X < 1
		P0X = 1;
	end
	[a0, a1, a2] = GenQuadratic(P0X, P0Y, VX, VY, P1X, P1Y);
	Ret = Arr;
	for i = fix(P0X) : fix(P1X)
		Ret(i) = a0 * (i ^ 2) + a1 * i + a2;
	end
end

function [X, Y] = GetMouseClick()
        do
                [X, Y, Button] = ginput(1);
        until(Button == 1);
end

