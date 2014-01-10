function [ret]=Plugin_Freq2Pitch(freq)
  ret=69+12*log2(freq/440)
end

%	C C#(Db) D D#(Eb) E F F#(Gb) G G#(Ab) A A#(Bb) B
function [ret]=Plugin_Pitch2Shierlv(pitch)
  shierlv=["C";"C#(Db)";"D";"D#(Eb)";"E";"F";"F#(Gb)";"G";"G#(Ab)";"A";"A#(Bb)";"B";]
  s=fix(pitch/12)
  d=pitch-s*12
  id=round(d)+1
  ret=strcat(shierlv(id,:),mat2str(s-1),"    error:",mat2str(-((id-d-1)*100)),"%")
end