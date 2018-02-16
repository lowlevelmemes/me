s/\.byte/db/g
s/\.word/dw/g
s/\.ascii/db/g
s/br /jmp /g
s/blt /jl /g
/^\!/ d
/^\.[a-z]/ d
/^\.[G-Z]/ d
/^export/ d
s/\*//g
s/\#//g
s/\$/0x/g
s/push\t/push word\t/g
s/pop\t/pop word\t/g
