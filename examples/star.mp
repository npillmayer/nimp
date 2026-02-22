beginfig(1)
  pair A, B, D, D, E;
  A := (1cm,0);
  B := A rotated 72;
  C := B rotated 72;
  D := C rotated 72;
  E := D rotated 72;
  pair AA, BB, CC, DD, EE;
  AA = whatever [A, C];      AA = whatever [B, D];      
  BB = whatever [B, D];      BB = whatever [C, E];      
  CC = whatever [C, E];      CC = whatever [D, A];      
  DD = whatever [D, A];      DD = whatever [E, B];      
  EE = whatever [E, B];      EE = whatever [A, C];      
  fill A--C--E--B--D--cycle withcolor .8white;
  fill AA--BB--CC--DD--EE--cycle withcolor white;
  draw A--C--E--B--D--cycle;
endfig;

% ---------------------------------------------------------------------------

beginfig("star.svg")
A, B, C, D, E: pair
let A = (1cm,0)
let B = A.rotated(72)
let C = B.rotated(72)
let D = C.rotated(72)
let E = D.rotated(72)
AA, BB, CC, DD, EE
AA = whatever[A, C]
...

fill( A--C--E--B--D--cycle ).withcolor(.8 * white)
fill( AA--BB--CC--DD--EE--cycle ).withcolor(white)
draw( A--C--E--B--D--cycle )

endfig


