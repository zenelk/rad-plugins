alias ga='git add -A'
alias gb='git rev-parse --abbrev-ref HEAD'
alias gc='git commit'
alias gcan='git commit --amend --no-edit'
alias gcl='git clone'
alias gco='git checkout'
alias gd='git diff'
alias gdc='git diff --cached'
alias gf='git fetch --all --prune'
alias ggg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) \
- %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          \
%C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
alias gh='git rev-parse HEAD'
alias gl='git pull'
alias gp='git push'
alias gpu='git push -u origin `gb`'
alias gs='git status'
alias gu='git restore --staged'
