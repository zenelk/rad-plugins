hist --add-ignore "gc"

alias ga='git add -A'
alias gf='git fetch --all --prune'
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gp='git push'
alias gl='git pull'
alias gpu='git push -u origin `gb`'
alias gh='git rev-parse HEAD'
alias gb='git rev-parse --abbrev-ref HEAD'
alias gc='git commit'
alias ggg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) \
- %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          \
%C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
