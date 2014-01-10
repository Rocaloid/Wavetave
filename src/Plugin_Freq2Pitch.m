function FreqToPitch(freq)
  FreqToPitch=69+12*log2(freq/440)
end

%	C C#(Db) D D#(Eb) E F F#(Gb) G G#(Ab) A A#(Bb) B
function pp(pitch)
  shierlv=["C";"C#(Db)";"D";"D#(Eb)";"E";"F";"F#(Gb)";"G";"G#(Ab)";"A";"A#(Bb)";"B";]
  s=fix(pitch/12)
  d=pitch-s*12
  id=round(d)+1
  pp=strcat(shierlv(id,:),mat2str(s-1),"    error:",mat2str(-((id-d-1)*100)),"%")
end