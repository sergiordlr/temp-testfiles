export TERM=xterm-256color;
# to get the right number of colums in your terminal just echo "Current terminal size: $(tput cols)x$(tput lines)"
# the problem is that the debug terminal doesn't set the righ columns rows
stty cols 200
# stty rows 25