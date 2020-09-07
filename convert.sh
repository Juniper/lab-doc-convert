#!/bin/bash
#
# Name: juniper-lab-doc-convert v1.5
#
# Juniper Copyright: Copyright (c) [2018-2020], Juniper Networks, Inc. All rights reserved.
#
# Notice and Disclaimer: This code is licensed to you under the Creative Commons Attribution Share Alike 3.0 (the "License").
# You may not use this code except in compliance with the License. This code is not an official Juniper product.
# You can obtain a copy of the License at http://spdx.org/licenses/CC-BY-SA-3.0
#
# Third-Party Code: This code may depend on other components under separate copyright notice and license terms.
# Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.
#
 
set -e

echo Your container args are: "$@"
echo

if [[ "$*" == *new* ]]
then
  rm -Rf build/*
  rm -Rf source/*
  rm -Rf Makefile*
  echo 'Please answer the first question about "Separate source and build directories" with YES'
  sphinx-quickstart
  # change conf.py for us for theme and hidden_code_block
  sed -i 's/release =/version =/g' source/conf.py
  sed -i 's/alabaster/sphinx_rtd_theme/g' source/conf.py
  
  cp -r ./newproject/source/* ./source
  # rewrite index.rst to our optimum
  cp source/index.rst source/index.rst.original
  sed -i '1,/.. toctree::/!d' source/index.rst
  echo '   :maxdepth: 4' >>source/index.rst
  echo '   :numbered:' >>source/index.rst
  echo '   :caption: Contents:' >>source/index.rst
  echo '' >>source/index.rst
  echo '   readme' >>source/index.rst
fi

# this will use only the last .dcox file, but for now only one file is supported anyway
for file in *.docx; do
  # ignore local working copy starting with ~
  if ! [[ $file =~ ^~ ]]; then
    WORDDOC=$file
  fi
done
if [ -z "$WORDDOC" ]; then
  echo "no word doc (*.docx) found in current directory"
  exit 1
fi
FILENAME="${WORDDOC%.*}"

if [[ "$*" == *old* ]]
then
  echo 'OVERRIDE dynamic Tag generation to save time AT YOUR OWN RISK'
else
  echo
  echo generate tags that are collision free with the text inside word ...

  pandoc -f docx -t html ./$WORDDOC >build/collision-check.html
  cp /dev/null build/dynamic-tags.txt
  num=1
  while [ $num -le 18 ]; do
  num=$(expr $num + 1)
  while :; do
    NEWTAG='_0_'$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)'_0_'
    COLLISION=$(cat build/collision-check.html | grep $NEWTAG | wc -l)
    if [ $COLLISION -eq 0 ]; then
      break
    fi
  done
  echo $NEWTAG >> build/dynamic-tags.txt
  done
fi

cat build/dynamic-tags.txt

echo
echo read the dynamic tags into the 18 global variables ...

TAGGREENS=`sed -n '1p' build/dynamic-tags.txt`
TAGGREENE=`sed -n '2p' build/dynamic-tags.txt`
TAGREDS=`sed -n '3p' build/dynamic-tags.txt`
TAGREDE=`sed -n '4p' build/dynamic-tags.txt`
TAGPURPLES=`sed -n '5p' build/dynamic-tags.txt`
TAGPURPLEE=`sed -n '6p' build/dynamic-tags.txt`
TAGFONT8S=`sed -n '7p' build/dynamic-tags.txt`
TAGFONT8E=`sed -n '8p' build/dynamic-tags.txt`
TAGFONT6S=`sed -n '9p' build/dynamic-tags.txt`
TAGFONT6E=`sed -n '10p' build/dynamic-tags.txt`
TAGFONT4S=`sed -n '11p' build/dynamic-tags.txt`
TAGFONT4E=`sed -n '12p' build/dynamic-tags.txt`
TAGWARNS=`sed -n '13p' build/dynamic-tags.txt`
TAGWARNE=`sed -n '14p' build/dynamic-tags.txt`
TAGNOTES=`sed -n '15p' build/dynamic-tags.txt`
TAGNOTEE=`sed -n '16p' build/dynamic-tags.txt`
TAGINLINES=`sed -n '17p' build/dynamic-tags.txt`
TAGINLINEE=`sed -n '18p' build/dynamic-tags.txt`

echo
echo create your own dynamic translation map using the variables ...

cat <<EOF >build/mymap.txt
p[style-name='header'] => p:fresh
p[style-name='Body Text'] => p:fresh
p[style-name='No Spacing'] => pre.sourcecode:separator('\n')
p[style-name='CLI10'] => pre.sourcecode:separator('\n')
EOF

echo "p[style-name='CLI8'] => pre.sourcecode:separator('\n') > "$TAGFONT8S >> build/mymap.txt
echo "p[style-name='CLI6'] => pre.sourcecode:separator('\n') > "$TAGFONT6S >> build/mymap.txt
echo "p[style-name='CLI4'] => pre.sourcecode:separator('\n') > "$TAGFONT4S >> build/mymap.txt
echo "p[style-name='2Note'] => "$TAGNOTES >> build/mymap.txt
echo "p[style-name='3Warning'] => "$TAGWARNS >> build/mymap.txt
echo "p[style-name='CLI10green'] => pre.sourcecode:separator('\n') > "$TAGGREENS >> build/mymap.txt
echo "p[style-name='CLI10red'] => pre.sourcecode:separator('\n') > "$TAGREDS >> build/mymap.txt
echo "p[style-name='CLI10purple'] => pre.sourcecode:separator('\n') > "$TAGPURPLES >> build/mymap.txt
echo "r[style-name='CLI10green Char'] => "$TAGGREENS >> build/mymap.txt
echo "r[style-name='CLI10red Char'] => "$TAGREDS >> build/mymap.txt
echo "r[style-name='CLI10purple Char'] => "$TAGPURPLES >> build/mymap.txt
echo "r[style-name='CLIinline Char'] => "$TAGINLINES >> build/mymap.txt
cat build/mymap.txt

echo
echo removing old images from source folder ...
rm -f source/*.x-emf
mv source/UnhideButton.png source/UnhideButton.png.save
rm -f source/*.png
mv source/UnhideButton.png.save source/UnhideButton.png

echo
echo running mammoth ...
mammoth --output-format html --style-map build/mymap.txt --output-dir source ./$WORDDOC
mv source/${FILENAME}.html source/index.html

echo
echo save the color termination points via relabel them else the pandoc conversion will throw them away ...
echo 1/7 Processes
sed -i 's/<\/'$TAGREDS'>/<'$TAGREDE'>/g' source/index.html
echo 2/7 Processes
sed -i 's/<\/'$TAGGREENS'>/<'$TAGGREENE'>/g' source/index.html
echo 3/7 Processes
sed -i 's/<\/'$TAGPURPLES'>/<'$TAGPURPLEE'>/g' source/index.html
echo 4/7 Processes
sed -i 's/<\/'$TAGINLINES'>/<'$TAGINLINEE'>/g' source/index.html
echo 5/7 Processes
sed -i 's/<\/'$TAGFONT8S'>/<'$TAGFONT8E'>/g' source/index.html
echo 6/7 Processes
sed -i 's/<\/'$TAGFONT6S'>/<'$TAGFONT6E'>/g' source/index.html
echo 7/7 Processes
sed -i 's/<\/'$TAGFONT4S'>/<'$TAGFONT4E'>/g' source/index.html


pandoc -f html -t rst --columns=1000 source/index.html >source/readme.rst

echo
echo Pre-Process to disable syntax highlight, insert notes and warnings
echo 1/3 Processes
sed -i 's/.. code:: sourcecode/.. code-block:: none/g' source/readme.rst
echo 2/3 Processes
sed -i 's/<'$TAGNOTES'>/.. note:: /g' source/readme.rst
echo 3/3 Processes
sed -i 's/<'$TAGWARNS'>/.. warning:: /g' source/readme.rst

echo
echo Patch the beginning of a font4-Block to make the entire section hidden ...

cat <<EOF >build/replace_smallfont_start.py
f = open("source/readme.rst",'r', encoding="latin-1") # open file with read permissions
filedata = f.read() # read contents
f.close() # closes file
EOF

echo 'filedata = filedata.replace(".. code-block:: none\n\n   <'$TAGFONT4S'>", ".. raw:: html\n\n   <details>\n   <summary><img src="+chr(0x22)+"UnhideButton.png"+chr(0x22)+"></summary>\n\n.. code-block:: none\n\n   ")' >>build/replace_smallfont_start.py

cat <<EOF >>build/replace_smallfont_start.py
f = open("build/readme.rst",'w', encoding="latin-1") # open the same (or another) file with write permissions
f.write(filedata) # update it replacing the previous strings
f.close() # closes the file
EOF

echo
echo Patch the ending of a font4-Block to make the entire section hidden ...

cat <<EOF >build/replace_smallfont_end.py
f = open("source/readme.rst",'r', encoding="latin-1") # open file with read permissions
filedata = f.read() # read contents
f.close() # closes file
EOF

echo 'filedata = filedata.replace("<'$TAGFONT4E'>\n\n", "\n\n.. raw:: html\n\n   </details>\n\n")' >>build/replace_smallfont_end.py

cat <<EOF >>build/replace_smallfont_end.py
f = open("build/readme.rst",'w', encoding="latin-1") # open the same (or another) file with write permissions
f.write(filedata) # update it replacing the previous strings
f.close() # closes the file
EOF


echo 1/3 Processes
python3 build/replace_smallfont_start.py
mv build/readme.rst source/readme.rst

echo 2/3 Processes
python3 build/replace_smallfont_end.py

echo 3/4 Processes
sed -i 's/<'$TAGFONT4S'>//g' build/readme.rst
echo 4/4 Processes
sed -i 's/<'$TAGFONT4E'>//g' build/readme.rst

mv build/readme.rst source/readme.rst


#
# Extract Embedded Files and craft an URL for download
#
cp $WORDDOC build/AAA.docx
rm -f build/new-apporder.txt
touch build/new-apporder.txt
oleobj build/AAA.docx > build/tmp.txt || :
cat build/tmp.txt | grep 'Filename = "' >> build/new-apporder.txt || :
sed -i 's/"//g' build/new-apporder.txt
sed -i 's/Filename = //g' build/new-apporder.txt
echo Detected OLE-objects:
cat build/new-apporder.txt
echo

# check if there are changes
NUM=`cat build/new-apporder.txt | wc -l`
if [[ $NUM -gt 1 ]]; then
  OLDNUM=`cat build/apporder.txt | wc -l`
  if [[ $NUM -eq $OLDNUM ]]; then
    echo 'No change of the number of ole-object from last time'
    echo 'We assume to have to use the existing apporder.txt'
  else
    mv build/new-apporder.txt build/apporder.txt
  fi
else
  mv build/new-apporder.txt build/apporder.txt 
fi

#
# Change the file apporder.txt accordingly if this is not the case before you continue.
# I you have no embedded Files in you document you can ingnore this.
#

while IFS= read -r line
do
  echo "File detected:"$line
  runme="mv build/AAA.docx_"$line" source/"$line
  eval $runme
  echo $runme
done < <(cat build/apporder.txt)

# these are the EMF-Pictures from the embedded objects we need to replace
ls -1 -tr source/*.x-emf | sed 's/\// /g' | awk '{ print $2 }' > build/filelist.txt
cat build/filelist.txt


# Map Pictures to Files and insert URL
num=0
while IFS= read -r line
do
  num=$(expr $num + 1)
  app="sed -n '"$num"p' build/apporder.txt"
  echo "Build script:"$app
  myapp=`eval $app`
  echo "App to use:"$myapp
  myfile=`echo $line|awk '{print $1}'`
  loc=`cat source/readme.rst | grep -in ${myfile} | head -n 1 | sed 's/|/ /g' | awk '{ print $2 }'`
  echo "Attach after which image:"$loc
  runme="cat source/readme.rst | grep -in '|"$loc"|' | head -n 1 | sed 's/:/ /g' | awk '{ print \$1 }'"
  echo $runme
  toline=`eval $runme`
  echo "Image line in rst is:"$toline
  runme="sed -e '"$toline"i**DOWNLOAD**\n\`"$myapp" <"$myapp">\\\`__\n\n' -i source/readme.rst"
  echo $runme
  eval $runme
  echo "done"
done < <(cat build/filelist.txt)

echo
echo building our static html pages ...
make html

cp source/UnhideButton.png build/html

echo
echo convert CLI-labels to color codes in html
echo 1/8 Processes
sed -i 's/&lt;'$TAGGREENS'&gt;/<font color="green"><b>/g' build/html/readme.html
echo 2/8 Processes
sed -i 's/&lt;'$TAGGREENE'&gt;/<\/font color="green"><\/b>/g' build/html/readme.html
echo 3/8 Processes
sed -i 's/&lt;'$TAGREDS'&gt;/<font color="red"><b>/g' build/html/readme.html
echo 4/8 Processes
sed -i 's/&lt;'$TAGREDE'&gt;/<\/font color="red"><\/b>/g' build/html/readme.html
echo 5/8 Processes
sed -i 's/&lt;'$TAGPURPLES'&gt;/<font color="purple"><b>/g' build/html/readme.html
echo 6/8 Processes
sed -i 's/&lt;'$TAGPURPLEE'&gt;/<\/font color="purple"><\/b>/g' build/html/readme.html
echo 7/8 Processes
sed -i 's/&lt;'$TAGINLINES'&gt;/<font color="black" face="Courier New"><b><span style="background-color:lightgray;">/g' build/html/readme.html
echo 8/8 Processes
sed -i 's/&lt;'$TAGINLINEE'&gt;/<\/span><\/b><\/font>/g' build/html/readme.html

echo
echo just revoke the small font labels for now as the used readthedoc theme is small enough
echo 1/6 Processes
sed -i 's/&lt;'$TAGFONT8S'&gt;//g' build/html/readme.html
echo 2/6 Processes
sed -i 's/&lt;'$TAGFONT8E'&gt;//g' build/html/readme.html
echo 3/6 Processes
sed -i 's/&lt;'$TAGFONT6S'&gt;//g' build/html/readme.html
echo 4/6 Processes
sed -i 's/&lt;'$TAGFONT6E'&gt;//g' build/html/readme.html
echo 5/6 Processes
sed -i 's/&lt;'$TAGFONT4S'&gt;//g' build/html/readme.html
echo 6/6 Processes
sed -i 's/&lt;'$TAGFONT4E'&gt;//g' build/html/readme.html

echo
echo also remove the labels in the stored *.rst files ...
echo 1/14 Processes
sed -i 's/<'$TAGGREENS'>//g' build/html/_sources/readme.rst.txt
echo 2/14 Processes
sed -i 's/<'$TAGGREENE'>//g' build/html/_sources/readme.rst.txt
echo 3/14 Processes
sed -i 's/<'$TAGREDS'>//g' build/html/_sources/readme.rst.txt
echo 4/14 Processes
sed -i 's/<'$TAGREDE'>//g' build/html/_sources/readme.rst.txt
echo 5/14 Processes
sed -i 's/<'$TAGPURPLES'>//g' build/html/_sources/readme.rst.txt
echo 6/14 Processes
sed -i 's/<'$TAGPURPLEE'>//g' build/html/_sources/readme.rst.txt
echo 7/14 Processes
sed -i 's/<'$TAGFONT8S'>//g' build/html/_sources/readme.rst.txt
echo 8/14 Processes
sed -i 's/<'$TAGFONT8E'>//g' build/html/_sources/readme.rst.txt
echo 9/14 Processes
sed -i 's/<'$TAGFONT6S'>//g' build/html/_sources/readme.rst.txt
echo 10/14 Processes
sed -i 's/<'$TAGFONT6E'>//g' build/html/_sources/readme.rst.txt
echo 11/14 Processes
sed -i 's/<'$TAGFONT4S'>//g' build/html/_sources/readme.rst.txt
echo 12/14 Processes
sed -i 's/<'$TAGFONT4E'>//g' build/html/_sources/readme.rst.txt
echo 13/14 Processes
sed -i 's/<'$TAGINLINES'>//g' build/html/_sources/readme.rst.txt
echo 14/14 Processes
sed -i 's/<'$TAGINLINEE'>//g' build/html/_sources/readme.rst.txt

echo
echo prepare distribution package with word and html-files in a *.zip ...
mkdir -p build/distribute/readthedocs-html-version
cp $WORDDOC build/distribute
cp -R build/html/* build/distribute/readthedocs-html-version
cp source/UnhideButton.png build/distribute/readthedocs-html-version

while IFS= read -r line
do
  echo "File detected:"$line
  runme="cp source/"$line" build/distribute/readthedocs-html-version"
  eval $runme
  echo $runme
done < <(cat build/apporder.txt)

cd build/distribute; zip -r $FILENAME.zip * ; cd - >/dev/null
mv build/distribute/$FILENAME.zip .
echo

echo "static html pages in build/html:"
ls build/html/

echo
echo -n "Your distribution zip file:"
ls $FILENAME.zip

echo
if [[ $NUM -gt 1 ]]; then
  echo 'You have more then one possible embedded OLE-Objects in Word'
  echo 'They are currently applied in the following order below'
  cat build/apporder.txt
  echo
  echo 'If that is NOT the order in which they really appear in Word then'
  echo 'change the order accordingly in the File: build/apporder.txt and run this again'
fi

if [[ "$*" == *new* ]]
then
  echo 'As this is a new Project we have auto-generated the reStructuredText welcome and index-Page for you.'
  echo 'If you want to edit that to expand or change what is displayed edit the File: source/index.rst'
fi 
