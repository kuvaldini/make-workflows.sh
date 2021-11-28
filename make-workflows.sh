#!/usr/bin/env bash
set -euo pipefail


--help(){
   cat<<'END'
make-workflows:
   This script expands '*.src.yml' from $1..$[N-1] (default: script's directory)
   to $N (default:REPO_ROOT/.github/workflows) with corresponding name '*.yml'
   Main goal is to dereference YAML anchors.
   Deals only with Git cached/indexed files until --worktree passed.
   DEBUG: use option -x
   NOTE: spaces in filenames are not allowed to keep code simplicity.
END
   cat<<END
Usage:
    make-workflows.sh [--worktree] [dirs_from... [dir_to]]
    make-workflows.sh [--help]
Options:
   --worktree       List files and get contents from working tree
                    instead of git index
   -h, --help       show this help
   -x, --trace, +x, --no-trace   enable/disable bash trace
   -i, --install
   --update
   -V, --version
END
   exit
}

files_list(){
   git diff --cached --name-only --relative --diff-filter=d -- "$@"
   ## NOTE: --diff-filter=d  to exclude deleted files
}
file_contents(){
   git show $(printf ":%s " $@)
}
curl_release(){
   curl 'https://raw.githubusercontent.com/kuvaldini/make-workflows.sh/main/make-workflows.sh' -LsSf "$@"
}

while [[ $# > 0 ]] ;do
   case "$1" in
      ## List files and get contents from working tree instead of git index
      --worktree)
         files_list(){
            ls $@
         }
         file_contents(){
            cat $@
         }
         ;;
      -x|--trace)    set -x ;;
      +x|--no-trace) set +x ;;
      -h|--help|'-?') --help ;;
      -i|--install)
         install_path="${install_dir:=/usr/local/bin}/make-workflows.sh"
         touch "$install_path" 2>&- || {
            echo >&2 "Cannot touch '$install_path'. "\
            "Check if directory exists and you have enough access rights!"
            exit 1; }
         if test "" != "${BASH_SOURCE[0]:-}" ;then
            cp "${BASH_SOURCE[0]}" "$install_path"
         else
            curl_release >"$install_path"
         fi
         chmod +x "$install_path"
         exit
         ;;
      --update)
         TEMP=`mktemp`
         curl_release -o $TEMP
         chmod +x $TEMP
         if diff -q "${BASH_SOURCE[0]}" $TEMP &>/dev/null ;then
            echomsg "Already up to date."
            rm -f $TEMP
            exit
         else
            exec mv $TEMP $(readlink -f "${BASH_SOURCE[0]}")
         fi
         ;;
      -V|--version)
         echo "make-workflows.sh version 1.0.0"
         exit
         ;;
      -*)
         echo >&2 "make-workflows: ERROR: unxpected parameter"
         --help >&2
         exit 2
         ;;
      ## The last non-option argument is dir_to all previous are dirs_from
      *)
         if [[ "$1" = *' '* ]] ;then
            echo >&2 "make-workflows: ERROR: spaces in arguments are not allowed: '$1'"
            exit 1
         fi
         if [[ "$(echo ${dirs_from:-})" = '' ]] ;then
            dirs_from=$1
         else
            dirs_from+=" "${dir_to:-}
            dir_to=$1
         fi
         ;;
   esac
   shift
done

script_dir=$(dirname $(realpath "$0"))
repo_root=$(git rev-parse --show-toplevel)
dirs_from=${dirs_from:-${repo_root}/.github}
dir_to=${dir_to:-$repo_root/.github/workflows}
dir_to=$(realpath $dir_to)
readonly script_dir repo_root dirs_from dir_to

if test "${dirs_from:-}" = ""
then echo >&2 "make-workflows: ERROR: dirs_from is not set, arguments required."; exit 1
fi

edited_files=
for dir_from in $dirs_from ;do
   pushd $dir_from >/dev/null
   for f in $(files_list '*.src.yml') ;do
      out=$(echo $f | sed 's|.src.yml$|.yml|')
      wout=$dir_to/$out
      tempout=$(mktemp)
      trap "rm -f $tempout" EXIT   ## in case of error file will be removed before exit
      echo >>$tempout "## DO NOT EDIT"
      echo >>$tempout "## Generated from $f with $(basename $0)"
      echo >>$tempout ""
      ## Take cached content from index
      file_contents ./$f | yq eval 'explode(.)' - >>$tempout
      if ! diff -q $wout $tempout &>/dev/null ;then
         mv $tempout $wout
         edited_files+="'$(realpath --relative-to=$OLDPWD $wout)' "
      else
         rm -f $tempout
      fi
   done
   popd >/dev/null
done

if [[ -n "$edited_files" ]]
then echo "make-workflows: these files were edited: $edited_files"
else echo "make-workflows: everything is up to date"
fi
