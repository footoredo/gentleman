#!/bin/bash

cd gen/
echo Pandocing markdown files to epub...
for file in `ls *.markdown`
do
	pandoc $file -o $file".epub"
done
echo Finished.
