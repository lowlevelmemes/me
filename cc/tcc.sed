/^\!/ d
/^\.[a-Z]/ d
/^export/ d
s/\*//g
s/\#//g
s/\$/0x/g
s/push\t/push word\t/g
s/pop\t/pop word\t/g
