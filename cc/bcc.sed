s/\.byte/db/g
s/\.word/dw/g
s/\.dword/dd/g
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
