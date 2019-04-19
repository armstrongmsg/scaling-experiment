#!/bin/bash

BASE_FILE="$1"
FILES_DIRECTORY="$2"

for ((i=3; i<=$#; i+=2)); do
	FILE_SIZE=${!i}
	NUMBER_OF_FILES_INDEX=$(( i + 1 ))
	NUMBER_OF_FILES=${!NUMBER_OF_FILES_INDEX}
#    next=$((i+1))
#    prev=$((i-1))
#   echo "Arg #$i='${!i}', prev='${!prev}', next='${!next}'"
	echo $FILE_SIZE
	echo $NUMBER_OF_FILES

	for j in `seq 1 $NUMBER_OF_FILES`
	do
		for s in `seq 1 $FILE_SIZE`
		do
			cat $BASE_FILE >> $FILES_DIRECTORY/words.$FILE_SIZE.$j
		done
	done
done


#FILES_DIRECTORY="test"

#WORDS="aaaaaaaaaa bbbbbbbbbb cccccccccc dddddddddd eeeeeeeeee ffffffffff gggggggggg hhhhhhhhhh iiiiiiiiii jjjjjjjjjj"


