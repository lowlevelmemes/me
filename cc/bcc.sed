s/\.byte/db/g
s/\.word/dw/g
s/\.dword/dd/g
s/\.ascii/db/g
s/br /jmp /g
s/beq /je /g
s/bne /jne /g
s/blt /jl /g
/^\!/ d
/^\.\./ d
/^\.[a-z]/ d
/^\.[G-Z]/ d
/^export/ d
s/\*//g
s/\#//g
s/\$/0x/g
