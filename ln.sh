#/bin/bash

function link()
{
SRC="`pwd`/$1"
DST="$HOME/$2"

if [ -h $DST ] ; then
  echo "symbolic link $DST exists, removing"
  rm $DST
fi

if [ -f "$DST" -o -d "$DST" ] ; then
  if [ -f "$DST" ] ; then
    echo "file $DST exists, remove it first"
  else
    echo "directory $DST exists, remove it first"
  fi
else
  ln -s "$SRC" "$DST"
fi
}

link vim/vimfiles .vim
link vim/_vimrc .vimrc
link mutt .mutt
link mailcap .mailcap
link bin bin

