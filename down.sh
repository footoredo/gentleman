#!/bin/bash

rm -rf gen/

echo Downloading ebook...
ruby gentleman.rb $1
echo Finished.

cd gen/
echo Pandocing markdown files to epub...
for file in ./*.markdown
do
	~/.cabal/bin/pandoc $file -o `echo $file | grep '/d+'`".epub"
done
echo Finished.
