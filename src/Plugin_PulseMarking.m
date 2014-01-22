function Plugin_VOTMarking(Wave)
	global Plugin_Var_Pulses;
	global ViewPos;
	global ViewWidth;
	global Length;
	Left = ViewPos - ViewWidth;
	Right = ViewPos + ViewWidth;
	if(Left < 1)
		Left = 1;
	end
	if(Right > Length)
		Right = Length;
	end
	if(Right - Left < 5000)
	for i = Plugin_Var_Pulses
		if(i > Left && i < Right)
			i = fix(i - Left) + 1;
			if(Wave(i) > 0)
				text(i, + 0.2, "|");
			else
				text(i, - 0.2, "|");
			end
		end
	end
	end
end

