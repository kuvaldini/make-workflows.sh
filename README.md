make-workflows.sh for GitHub Actions
====================================

GitHub Workflow description in YAML does not support anchors.
There are several workarounds => anyway they come to building-editing workflow yaml from source.
So I suggest yet another one `make-workflows.sh` based on YAML tool [`yq`](https://github.com/mikefarah/yq) version 4.

### USAGE
0. Put your workflows to `.github/*.src.yml`
1. Put `make-workflows.sh` to directory `.github/`
2. (recommended) `pre-commit install`  
   <sub>(altenative optional) Copy or link `pre-commit-hook.sh` to `.git/hooks/pre-commit`  
   Like `ln -s ../../.github/pre-commit-hook.sh .git/hooks/pre-commit`</sub>

```
$ ./make-workflows.sh --help
make-workflows:
    This script expands '*.src.yml' from $1..$[N-1] (default: script's directory)
    to $N (default:REPO_ROOT/.github/workflows) with corresponding name '*.yml'
    Main goal is to dereference YAML anchors.
    Deals only with Git cached/indexed files until --no-git-index passed.
    DEBUG: use option -x
    NOTE: spaces in filenames are not allowed to keep code simplicity.
Usage:
    make-workflows.sh [--worktree] [dirs_from... [dir_to]]
    make-workflows.sh [--help]
Options:
    --no-git-index|--worktree   List files and get contents from working tree
                                instead of git index
    -h, --help       show this help
    -x, --trace
    +x, --no-trace   enable/disable bash trace
```

### Using pre-commit
There is a nice tool [pre-commit](https://pre-commit.com) to do checks and some actions just before commit. The tool is called by Git pre-commit hook.

Making workflows is better being automated – just 
```sh
$ pre-commit install
```
and add next sample to `.pre-commit-config.yaml`
```yaml
repos:
- repo: local
  hooks:
  - id: make-workflows
    name: Make GitHub workflows from *.src.yml
    entry: bash -c '.github/make-workflows.sh && git add .github/workflows'
    language: system
    files: '.github/.*\.src\.ya?ml'
    pass_filenames: false
```


### Links
1. https://stackoverflow.com/questions/67368724/share-same-steps-for-different-github-actions-jobs
2. https://github.community/t/support-for-yaml-anchors/16128/60
3. https://github.com/mithro/actions-includes
4. https://github.com/allejo/gha-workflows
5. this repo https://github.com/kuvaldini/make-workflows.sh

## License
Authored by [Kuvaldini](https://github.com/kuvaldini), 2021.  
Please keep links to the source code [this repo](https://github.com/kuvaldini/make-workflows.sh)
