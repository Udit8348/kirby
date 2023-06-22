python3 ../SCASM2/SCASM2.py $1
# slice file ending from asm file
f=${1::-4}
# create file ending
end=".mif"
# cat via smoosh
f=$f$end

code $f