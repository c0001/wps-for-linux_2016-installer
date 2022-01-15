#!/bin/bash
this_src="${BASH_SOURCE[0]}"
while [ -h "$this_src" ]; do # resolve $this_src until the file is no longer a symlink
  this_src_dir="$( cd -P "$( dirname "$this_src" )" >/dev/null && pwd )"
  this_src="$(readlink "$this_src")"

  # if $this_src was a relative symlink, we need to resolve it relative
  # to the path where the symlink file was located
  [[ $this_src != /* ]] && this_src="$this_src_dir/$this_src"
done
this_src_dir="$( cd -P "$( dirname "$this_src" )" >/dev/null && pwd )"


type=$1

topdir="${HOME}"/.local/

install -d "$topdir"/lib
install -d "$topdir"/bin
install -d "$topdir"/share


set -e
if [[ $1 == 'install' ]]
then
    cp -rv "${this_src_dir}"/lib "$topdir"/
    cp -rv "${this_src_dir}"/bin "$topdir"/
    cp -rv "${this_src_dir}"/share "$topdir"/

elif [[ $1 == 'uninstall' ]]
then
    while IFS= read f
    do
        if [[ -f "$topdir"/"$f" ]]
        then
            rm -v "$topdir"/"$f"
        fi
    done < "${this_src_dir}"/file.txt

    while IFS= read l
    do
        if [[ -h "$topdir"/"$l" ]]
        then
            unlink "$topdir"/"$l"
        fi
    done < "${this_src_dir}"/link.txt
else
    echo -e "\e[31mWrong command type $1 (please use install/uninstall)\e[0m"
    exit 1
fi
