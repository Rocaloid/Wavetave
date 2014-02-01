#  Plugin_UnvoicedDetection.m
#    Finds the start of the unvoiced part of a given vocal signal.
#
#  The Algorithm
#    It's all about a threshold.
#

function Plugin_UnvoicedDetection(Wave)
        global SampleRate;
        global Environment;
        global Plugin_Var_Unvoiced;

        Threshold = 0.0005;
        PartLength = length(Wave);
        Plugin_Var_Unvoiced = 0;
        for i = 1 : PartLength
                if(abs(Wave(i)) > Threshold)
                        Plugin_Var_Unvoiced = i;
                        break;
                end
        end
        if(Plugin_Var_Unvoiced != 0 && strcmp(Environment, "Visual"))
                text(Plugin_Var_Unvoiced, 0, "x Unvoiced");
        end
end

