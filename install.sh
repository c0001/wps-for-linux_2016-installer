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


for cmd in dirname wc cp unlink ln cat
do
    if [[ -z $(command -v $cmd) ]]
    then
        echo -e "\e[31mCommand '${cmd}' not found which is used in this script!\e[0m"
        exit 1
    fi
done

type=$1

topdir="${HOME}"/.local

install -d "$topdir"/lib
install -d "$topdir"/bin
install -d "$topdir"/share

uninstall_log="${topdir}/wps_uninstall_$(date -u +"%Y%m%d%H%M%S")_${RANDOM}.txt"
while [[ -e "${uninstall_log}" ]]
do
    uninstall_log="${topdir}/wps_uninstall_$(date -u +"%Y%m%d%H%M%S")_${RANDOM}.txt"
done

function _mkdir_sub ()
{
    local item="$1"
    if [[ ! -e "$(dirname "${topdir}"/"$item")" ]]
    then
        mkdir -p "$(dirname "${topdir}"/"$item")"
    fi
}

set -e
count_install=0
count_install_const=$(( "$(cat "${this_src_dir}/link.txt" | wc -l )" + "$(cat "${this_src_dir}/file.txt" | wc -l)" ))

function _count_neq_error ()
{
    local type=$1
    if [[ $count_install -ne $count_install_const ]]
    then
        echo -e "\e[31m${type}: --- did do count \e[33m${count_install}\e[0m not equal const release of \e[33m${count_install_const}\e[0m !"
        exit 1
    else
        echo -e "\e[32m${type}: --- did do count \e[33m${count_install}\e[0m equal const release of \e[33m${count_install_const}\e[0m !"
    fi
}

if [[ $1 == 'install' ]]
then

    while IFS= read file
    do
        if [[ -f "${this_src_dir}"/"$file" ]]
        then
            _mkdir_sub "$file"
            cp -iv "${this_src_dir}"/"$file" "${topdir}"/"$file"
            let ++count_install
        fi
    done < "${this_src_dir}"/file.txt

    while IFS= read link
    do
        if [[ -f "${this_src_dir}"/"$link" ]]
        then
            _mkdir_sub "$file"
            # NOTE: use -a option to copy link
            cp -aiv "${this_src_dir}"/"$link" "${topdir}"/"$link"
            let ++count_install
        fi
    done < "${this_src_dir}"/link.txt

    _count_neq_error install

    # patch desktop icon
    cd "${HOME}/.local/share/applications/"
    if [[ -f wps-office-wps.desktop ]]
    then
        sed -i "s|Icon=wps-office-wpsmain|Icon=${HOME}/.local/share/icons/hicolor/256x256/apps/wps-office-wpsmain.png|g" ./wps-office-wps.desktop
    fi
    if [[ -f wps-office-wpp.desktop ]]
    then
        sed -i "s|Icon=wps-office-wppmain|Icon=${HOME}/.local/share/icons/hicolor/256x256/apps/wps-office-wppmain.png|g" ./wps-office-wpp.desktop
    fi
    if [[ -f wps-office-et.desktop ]]
    then
        sed -i "s|Icon=wps-office-etmain|Icon=${HOME}/.local/share/icons/hicolor/256x256/apps/wps-office-etmain.png|g" ./wps-office-et.desktop
    fi

elif [[ $1 == 'uninstall' ]]
then
    while IFS= read f
    do
        if [[ -f "$topdir"/"$f" ]]
        then
            rm -v "$topdir"/"$f"
            let ++count_install
        fi
    done < "${this_src_dir}"/file.txt

    while IFS= read l
    do
        if [[ -h "$topdir"/"$l" ]]
        then
            unlink "$topdir"/"$l"
            let ++count_install
        elif [[ -f "$topdir"/"$l" ]]
        then
            echo "$topdir"/"$l" >> "$uninstall_log"
        fi
    done < "${this_src_dir}"/link.txt

    if [[ -f "$uninstall_log" ]]
    then
        echo -e "\e[31mThere's some non-link file remained! please see log of \"$uninstall_log\""
        exit 1
    else
        _count_neq_error uninstall
    fi
else
    echo -e "\e[31mWrong command type $1 (please use install/uninstall)\e[0m"
    exit 1
fi
