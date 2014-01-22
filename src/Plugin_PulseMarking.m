#  Plugin_PulseMarkinglm
#    Dynamic display of glottal pulses.
#  Depends on Plugin_Load_PulseMarking.

function Plugin_PulseMarking(Wave)
        global Plugin_Var_Pulses;
        global ViewPos;
        global ViewWidth;
        global Length;

        #Calculate the bound of visible area.
        Left = ViewPos - ViewWidth;
        Right = ViewPos + ViewWidth;
        if(Left < 1)
                Left = 1;
        end
        if(Right > Length)
                Right = Length;
        end
        #Large observe window will be very slow.
        if(Right - Left < 5000)
                for i = Plugin_Var_Pulses
                        if(i > Left && i < Right)
                                i = fix(i - Left) + 1;
                                #The position of labels depends on signs of
                                #  the peaks.
                                if(Wave(i) > 0)
                                        text(i, + 0.2, "|");
                                else
                                        text(i, - 0.2, "|");
                                end
                        end
                end
        end
end

