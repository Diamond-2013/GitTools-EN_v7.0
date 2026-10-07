#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/git_tool.log"
CONFIG_FILE="$SCRIPT_DIR/git_tool.ini"
CURRENT_DIR="$(pwd)"

COLOR_ENABLED=1
DEBUG_MODE=0
SAFE_MODE=1
MAX_LOG_SIZE=2097152
GIT_TIMEOUT=30
BACKUP_ENABLED=1
CURRENT_BRANCH=""
AUTO_PUSH=0
DEFAULT_REMOTE=origin
DEFAULT_BRANCH=main
CONFIRM_DANGEROUS=1
LOG_LEVEL=INFO
SHOW_HEADER=1
AUTO_CLEAN_NUL=1

CUR_DATE="$(date +%Y%m%d)"
CUR_TIME="$(date +%H%M%S)"

C_RESET=$'\e[0m'
C_RED=$'\e[91m'
C_GREEN=$'\e[92m'
C_YELLOW=$'\e[93m'
C_BLUE=$'\e[94m'
C_MAGENTA=$'\e[95m'
C_CYAN=$'\e[96m'
C_WHITE=$'\e[97m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[2m'

init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<'EOF'
[DEFAULT]
COLOR=1
SAFE_MODE=1
BACKUP_ENABLED=1
AUTO_PUSH=0
DEFAULT_REMOTE=origin
DEFAULT_BRANCH=main
CONFIRM_DANGEROUS=1
LOG_LEVEL=INFO
SHOW_HEADER=1
AUTO_CLEAN_NUL=1
EOF
    fi
    while IFS='=' read -r key val; do
        key="${key//[$'\r\n']/}"; val="${val//[$'\r\n']/}"
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# || "$key" =~ ^\[ ]] && continue
        case "$key" in
            COLOR)            COLOR_ENABLED=$val ;;
            SAFE_MODE)        SAFE_MODE=$val ;;
            BACKUP_ENABLED)   BACKUP_ENABLED=$val ;;
            AUTO_PUSH)        AUTO_PUSH=$val ;;
            DEFAULT_REMOTE)   DEFAULT_REMOTE=$val ;;
            DEFAULT_BRANCH)   DEFAULT_BRANCH=$val ;;
            CONFIRM_DANGEROUS) CONFIRM_DANGEROUS=$val ;;
            LOG_LEVEL)        LOG_LEVEL=$val ;;
            SHOW_HEADER)      SHOW_HEADER=$val ;;
            AUTO_CLEAN_NUL)   AUTO_CLEAN_NUL=$val ;;
        esac
    done < "$CONFIG_FILE"
}

init_colors() {
    if [[ "$COLOR_ENABLED" != "1" ]]; then
        C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
        C_MAGENTA=""; C_CYAN=""; C_WHITE=""; C_BOLD=""; C_DIM=""
    fi
}

check_git() {
    if ! command -v git >/dev/null 2>&1; then
        cls
        print_error "Git is not installed or not in the PATH environment variable"
        echo
        print_yellow " Install it with a package manager, e.g. sudo apt install git"
        print_yellow " Or see the official site: https://git-scm.com/download/linux"
        echo
        read -r -p "Press any key to exit..."
        exit 1
    fi
    local ver
    ver="$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -n1)"
    local major="${ver%%.*}"
    if [[ "${major:-0}" -lt 2 ]]; then
        print_warn "Git version is too old, use 2.x or later"
    fi
}

check_environment() {
    print_info "Checking environment..."
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Git Tool Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"
        echo "========================================" >> "$LOG_FILE"
    fi
    echo
    print_cyan "==================== Environment Status ===================="
    if [[ "$SAFE_MODE" == "1" ]]; then
        print_green "  Safe Mode        : Enabled"
        print_yellow "    - All operations require confirmation before execution"
        print_yellow "    - Dangerous operations require YES to continue"
    else
        print_red "  Safe Mode        : Disabled"
        print_red "    - WARNING: all operations run directly, no protection!"
    fi
    if [[ "$BACKUP_ENABLED" == "1" ]]; then
        print_green "  Auto Backup      : Enabled"
        print_yellow "    - Stashes current changes before dangerous operations"
    else
        print_red "  Auto Backup      : Disabled"
        print_red "    - WARNING: no auto backup before dangerous operations, data may be lost!"
    fi
    if [[ "$AUTO_PUSH" == "1" ]]; then
        print_green "  Auto Push        : Enabled"
        print_yellow "    - Pushes to remote after a successful commit"
    else
        print_dim "  Auto Push        : Disabled"
    fi
    if [[ "$CONFIRM_DANGEROUS" == "1" ]]; then
        print_yellow "  Danger Confirm   : requires YES"
    else
        print_yellow "  Danger Confirm   : just enter y"
    fi
    if [[ "$SHOW_HEADER" == "1" ]]; then
        print_green "  Show Header      : Full mode"
        print_yellow "    - Shows the current directory and branch info"
    else
        print_dim "  Show Header      : Simple mode"
    fi
    if [[ "$AUTO_CLEAN_NUL" == "1" ]]; then
        print_green "  Clean NUL Files  : Enabled"
        print_yellow "    - Auto-cleans Windows device files (no issue on Linux)"
    else
        print_dim "  Clean NUL Files  : Disabled"
    fi
    print_cyan "  Color Display        : $([ "$COLOR_ENABLED" == "1" ] && echo Enabled || echo Disabled)"
    print_cyan "  Default Remote   : $DEFAULT_REMOTE"
    print_cyan "  Default Branch   : $DEFAULT_BRANCH"
    print_cyan "  Log Level        : $LOG_LEVEL"
    print_cyan "===================================================="
    echo
    print_dim "Press any key to continue..."
    read -r -n 1 -s
    echo
}

rotate_log() {
    [[ ! -f "$LOG_FILE" ]] && return
    local size
    size="$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)"
    if [[ "$size" -gt "$MAX_LOG_SIZE" ]]; then
        local backup_name="git_tool_old_${CUR_DATE}_${CUR_TIME}.log"
        [[ -f "$backup_name" ]] && rm -f "$backup_name"
        mv "$LOG_FILE" "$backup_name" 2>/dev/null
        echo "Log rotated - $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"
        print_info "Log rotated: $backup_name"
    fi
}

display_header() {
    echo
    if [[ "$SHOW_HEADER" == "1" ]]; then
        CURRENT_BRANCH="$(git branch --show-current 2>/dev/null)"
        print_bold_cyan "Git Tools v7.0 - Professional Edition"
        print_cyan "================================================================"
        echo -n "${C_BOLD}Current directory: ${C_RESET}${C_YELLOW}$CURRENT_DIR${C_RESET} ${C_DIM}(${C_RESET}${C_BLUE}$CURRENT_BRANCH${C_DIM})${C_RESET}"
        echo
        print_cyan "================================================================"
    else
        echo "Git Tools v7.0"
        echo "================================================================"
    fi
    echo
}

display_menu() {
    print_menu_item " 1" "Stage all changes"     "21" "Pull remote updates"
    print_menu_item " 2" "Commit changes"           "22" "Clone remote repository"
    print_menu_item " 3" "Stage all and commit"     "23" "Add remote repository"
    print_menu_item " 4" "View repository status"       "24" "View remote repositories"
    print_menu_item " 5" "View commit log"       "25" "Delete remote repository"
    print_menu_item " 6" "Unstage"           "26" "Stash current changes"
    print_menu_item " 7" "Delete local repository"       "27" "Restore stashed work"
    print_menu_item " 8" "Change working directory"       "28" "View stash list"
    print_menu_item " 9" "Initialize repository"         "29" "Delete stash entry"
    print_menu_item "10" "Recursively add source files"     "30" "Clean untracked files"
    print_menu_item "11" "Hard reset commit"       "31" "Restore all changes"
    print_menu_item "12" "Amend commit message"       "32" "Set user configuration"
    print_menu_item "13" "View file diff"       "33" "Abort merge/rebase conflicts"
    print_menu_item "14" "View commit contents"       "34" "Interactive rebase"
    print_menu_item "15" "Create and switch branch"     "35" "Tag management"
    print_menu_item "16" "Switch to existing branch"     "36" "Submodule management"
    print_menu_item "17" "View all branches"       "37" "Cherry-pick commit"
    print_menu_item "18" "Delete branch"           "38" "Bisect"
    print_menu_item "19" "Merge branch"           "39" "Worktree management"
    print_menu_item "20" "Push to remote repository"     "40" "Exit tool"
    print_cyan "================================================================"
    echo
}

print_menu_item() {
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        printf "%s%3s%s. %-14s    %s%3s%s. %s\n" \
            "$C_CYAN" "$1" "$C_RESET" "$2" "$C_CYAN" "$3" "$C_RESET" "$4"
    else
        printf "%3s. %-14s    %3s. %s\n" "$1" "$2" "$3" "$4"
    fi
}

get_input() {
    local prompt="$1"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_BOLD}${C_WHITE}$prompt${C_RESET}" choice
    else
        read -r -p "$prompt" choice
    fi
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        choice=0
    fi
}

check_repo() {
    cd "$CURRENT_DIR" 2>/dev/null || { print_error "Cannot enter directory $CURRENT_DIR"; return 1; }
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Current directory is not a Git repository"
        echo
        print_info "Run [9] to initialize a repository or [8] to switch to a correct directory"
        wait_key
        return 1
    fi
    return 0
}

cls() {
    [[ -n "$TERM" ]] && command clear 2>/dev/null
}

print_info()    { echo "${C_BLUE}[INFO]${C_RESET} $1"; }
print_success() { echo "${C_GREEN}[OK]${C_RESET} $1"; }
print_warn()    { echo "${C_YELLOW}[WARN]${C_RESET} $1"; }
print_error()   { echo "${C_RED}[ERROR]${C_RESET} $1"; }
print_green()   { echo "${C_GREEN}$1${C_RESET}"; }
print_yellow()  { echo "${C_YELLOW}$1${C_RESET}"; }
print_red()     { echo "${C_RED}$1${C_RESET}"; }
print_cyan()    { echo "${C_CYAN}$1${C_RESET}"; }
print_dim()     { echo "${C_DIM}$1${C_RESET}"; }
print_bold_cyan() { echo "${C_BOLD}${C_CYAN}$1${C_RESET}"; }
print_bold()    { echo "${C_BOLD}$1${C_RESET}"; }

wait_key() {
    echo
    print_dim "Press any key to return to the menu..."
    read -r -n 1 -s
    echo
}

log_action() {
    if [[ "$LOG_LEVEL" == "INFO" || "$LOG_LEVEL" == "DEBUG" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" 2>/dev/null
    fi
}

confirm_action() {
    [[ "$SAFE_MODE" != "1" ]] && return 0
    local confirm
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_YELLOW}Confirm this operation? [y/N]: ${C_RESET}" confirm
    else
        read -r -p "Confirm this operation? [y/N]: " confirm
    fi
    case "${confirm,,}" in
        y|yes) return 0 ;;
        *) print_warn "Operation cancelled"; wait_key; return 1 ;;
    esac
}

confirm_dangerous() {
    [[ "$SAFE_MODE" != "1" ]] && return 0
    local confirm
    if [[ "$CONFIRM_DANGEROUS" == "1" ]]; then
        if [[ "$COLOR_ENABLED" == "1" ]]; then
            read -r -p "${C_RED}Dangerous operation! Enter YES to continue, otherwise cancel: ${C_RESET}" confirm
        else
            read -r -p "Dangerous operation! Enter YES to continue, otherwise cancel: " confirm
        fi
        case "${confirm^^}" in
            YES|Y) return 0 ;;
            *) print_warn "Operation cancelled"; wait_key; return 1 ;;
        esac
    else
        if [[ "$COLOR_ENABLED" == "1" ]]; then
            read -r -p "${C_YELLOW}Confirm? [y/N]: ${C_RESET}" confirm
        else
            read -r -p "Confirm? [y/N]: " confirm
        fi
        case "${confirm,,}" in
            y|yes) return 0 ;;
            *) print_warn "Operation cancelled"; wait_key; return 1 ;;
        esac
    fi
}

read_commit_message() {
    local msg=""
    while :; do
        local line
        read -r line
        [[ -z "$line" ]] && break
        msg="$msg$line "
    done
    echo "${msg% }"
}

git_add_all() {
    check_repo || return
    if git status --porcelain 2>/dev/null | grep -q .; then
        :
    else
        print_warn "No changes detected"
        wait_key; return
    fi
    print_info "Adding all changes..."
    if git add . 2>&1; then
        print_success "All changes added"
        log_action "ADD_ALL_SUCCESS"
    else
        print_error "Add failed"
        log_action "ADD_ALL_FAILED"
    fi
    wait_key
}

git_commit() {
    check_repo || return
    if ! git diff --cached --name-only 2>/dev/null | grep -q .; then
        print_warn "Staging area is empty, add files first"
        wait_key; return
    fi
    print_cyan "Enter commit message (multi-line supported, input an empty line to end)"
    local commit_msg
    commit_msg="$(read_commit_message)"
    if [[ -z "$commit_msg" ]]; then
        commit_msg="Auto commit $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    print_info "Commit message: $commit_msg"
    if git commit -m "$commit_msg" 2>&1; then
        print_success "Commit successful"
        git log --oneline -1 2>/dev/null
        log_action "COMMIT_SUCCESS: $commit_msg"
        if [[ "$AUTO_PUSH" == "1" ]]; then
            print_info "Auto-pushing..."
            git push 2>&1
        fi
    else
        print_error "Commit failed"
        log_action "COMMIT_FAILED"
    fi
    wait_key
}

git_add_commit() {
    check_repo || return
    if ! git status --porcelain 2>/dev/null | grep -q .; then
        print_warn "No changes detected"
        wait_key; return
    fi
    print_info "Adding and committing..."
    if ! git add . 2>&1; then
        print_error "Add failed"
        wait_key; return
    fi
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter commit message: ${C_RESET}" commit_msg
    else
        read -r -p "Enter commit message: " commit_msg
    fi
    [[ -z "$commit_msg" ]] && commit_msg="Quick commit $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$commit_msg" 2>&1; then
        print_success "Commit successful"
        git log --oneline -1 2>/dev/null
        log_action "ADD_COMMIT_SUCCESS: $commit_msg"
        if [[ "$AUTO_PUSH" == "1" ]]; then
            print_info "Auto-pushing..."
            git push 2>&1
        fi
    else
        print_error "Commit failed"
        log_action "ADD_COMMIT_FAILED"
    fi
    wait_key
}

git_status() {
    check_repo || return
    print_bold "Repository status: "
    echo
    git status 2>&1
    wait_key
}

git_log() {
    check_repo || return
    print_bold "Commit history (latest 20): "
    echo
    git log --oneline --graph --decorate --all -20 2>&1
    echo
    print_bold "Detailed log (latest 10): "
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        git log --pretty=format:"${C_CYAN}%h${C_RESET} ${C_GREEN}%ad${C_RESET} ${C_YELLOW}%an${C_RESET}%n%s%n" --date=short -10 2>&1
    else
        git log --pretty=format:"%h %ad %an%n%s%n" --date=short -10 2>&1
    fi
    wait_key
}

git_unstage() {
    check_repo || return
    if ! git diff --cached --name-only 2>/dev/null | grep -q .; then
        print_warn "Staging area is empty"
        wait_key; return
    fi
    confirm_action || return
    print_info "Unstaging..."
    if git reset 2>&1; then
        print_success "Unstaged"
        log_action "UNSTAGE_SUCCESS"
    else
        print_error "Unstage failed"
        log_action "UNSTAGE_FAILED"
    fi
    wait_key
}

git_delete_repo() {
    print_error "This will delete the entire Git repository"
    confirm_dangerous || return
    cd "$CURRENT_DIR" 2>/dev/null || return
    if [[ ! -d ".git" ]]; then
        print_warn "Current directory is not a Git repository"
        wait_key; return
    fi
    print_info "Deleting Git repository..."
    log_action "DELETE_REPO_START"
    rm -rf ".git" 2>/dev/null
    if [[ ! -d ".git" ]]; then
        print_success "Git repository deleted"
        if [[ -f ".gitignore" ]]; then
            rm -f ".gitignore"
            print_info ".gitignore deleted"
        fi
        log_action "DELETE_REPO_SUCCESS"
    else
        print_error "Deletion failed, manually delete the .git directory"
        log_action "DELETE_REPO_FORCED"
    fi
    wait_key
}

git_change_path() {
    print_bold "Current path: $CURRENT_DIR"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter new path: ${C_RESET}" new_path
    else
        read -r -p "Enter new path: " new_path
    fi
    if [[ -z "$new_path" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if [[ ! -d "$new_path" ]]; then
        print_error "Path does not exist"
        wait_key; return
    fi
    if cd "$new_path" 2>/dev/null; then
        CURRENT_DIR="$(pwd)"
        print_success "Switched to: $CURRENT_DIR"
        log_action "CHANGE_PATH: $CURRENT_DIR"
    else
        print_error "Cannot switch to that directory"
    fi
    wait_key
}

git_init() {
    cd "$CURRENT_DIR" 2>/dev/null || return
    if [[ -d ".git" ]]; then
        print_warn "Current directory is already a Git repository"
        local confirm
        if [[ "$COLOR_ENABLED" == "1" ]]; then
            read -r -p "${C_YELLOW}Reinitialize? [y/N]: ${C_RESET}" confirm
        else
            read -r -p "Reinitialize? [y/N]: " confirm
        fi
        case "${confirm,,}" in
            y|yes) ;;
            *) print_warn "Operation cancelled"; wait_key; return ;;
        esac
        print_info "Deleting old repository..."
        rm -rf ".git" 2>/dev/null
        if [[ -d ".git" ]]; then
            print_error "Deletion failed"
            wait_key; return
        fi
    fi
    print_info "Initializing Git repository..."
    if git init --initial-branch="$DEFAULT_BRANCH" 2>&1; then
        :
    elif git init 2>&1; then
        print_warn "Current Git does not support --initial-branch, using the default branch name"
    else
        print_error "Initialization failed"
        wait_key; return
    fi
    print_success "Git repository initialized"
    create_gitignore
    git add ".gitignore" 2>/dev/null
    print_info ".gitignore added to the staging area"
    log_action "INIT_REPO"
    wait_key
}

create_gitignore() {
    [[ -f ".gitignore" ]] && return
    cat > .gitignore <<'EOF'
# ========== Operating System
Thumbs.db
ehthumbs.db
Desktop.ini
.DS_Store
.Spotlight-V100
.Trashes
nul
/nul
CON
PRN
AUX
LPT1
LPT2
LPT3
LPT4
LPT5
LPT6
LPT7
LPT8
COM1
COM2
COM3
COM4
COM5
COM6
COM7
COM8
COM9

# ========== IDE and Editors
.vscode/
.idea/
.vs/
*.swp
*.swo
*~
*.bak
*.tmp
.project
.classpath
.settings/

# ========== Build Artifacts
*.exe
*.dll
*.so
*.dylib
*.class
*.o
*.obj
*.pdb
*.pyc
*.pyo
__pycache__/
*.jar
*.war
*.ear
target/
build/
dist/
out/
bin/

# ========== Log Files
*.log
logs/
*.pid

# ========== Archives
*.zip
*.rar
*.7z
*.tar
*.gz
*.bz2
*.xz

# ========== Dependencies
node_modules/
.pnpm-store/
vendor/
packages/
*.egg-info/
.mypy_cache/
.pytest_cache/
.coverage
htmlcov/

# ========== Environment Config
.env
.env.local
.env.*.local
.env.production
.env.development
*.local

# ========== Database
*.db
*.sqlite
*.sqlite3

# ========== Cache
.cache/
*.cache
*.min.js
*.min.css
*.map

# ========== System Files
.fuse_hidden*
.directory
.lock-wscript
.npm/
.yarn/
package-lock.json
yarn.lock
pnpm-lock.yaml
EOF
}

git_add_source() {
    check_repo || return
    print_info "Scanning source code files..."
    local SOURCE_EXTS="c cpp cc cxx h hpp hxx java py pyw js ts jsx tsx go rs rb php html htm css scss less vue svelte xml json yaml yml toml ini cfg conf sh bash zsh fish ps1 pl pm lua r m swift kt kts dart erl hrl ex exs clj cljs edn scala sbt groovy gradle lisp cl el sql prisma proto md markdown txt rst adoc asciidoc org tex latex bib"
    local expr=()
    for ext in $SOURCE_EXTS; do
        expr+=( -name "*.$ext" -o )
    done
    unset 'expr[${#expr[@]}-1]'
    local tmpfile="$SCRIPT_DIR/temp_filelist.txt"
    : > "$tmpfile"
    find . -type f \( "${expr[@]}" \) 2>/dev/null | sed 's|^\./||' > "$tmpfile"
    if [[ ! -s "$tmpfile" ]]; then
        print_warn "No source code files found"
        rm -f "$tmpfile"
        wait_key; return
    fi
    local file_count
    file_count="$(wc -l < "$tmpfile")"
    print_success "Found $file_count source code file(s)"
    echo
    print_dim "Adding files..."
    local display_count=0 add_count=0 line
    while IFS= read -r line; do
        if [[ "$display_count" -lt 20 ]]; then
            display_count=$((display_count+1))
            echo "  $display_count. $(basename "$line")"
        fi
        git add "$line" 2>/dev/null
        add_count=$((add_count+1))
        if [[ "$add_count" -eq 100 ]]; then
            add_count=0
            print_dim "."
        fi
    done < "$tmpfile"
    rm -f "$tmpfile"
    print_success "Added $file_count source code file(s)"
    if [[ -f ".gitignore" ]]; then
        git add ".gitignore" 2>/dev/null
        print_info ".gitignore added to the staging area"
    fi
    log_action "ADD_SOURCE: $file_count files"
    wait_key
}

git_reset_hard() {
    check_repo || return
    if ! git log -1 >/dev/null 2>&1; then
        print_warn "No commit history"
        wait_key; return
    fi
    print_warn "This will discard all uncommitted changes"
    if [[ "$BACKUP_ENABLED" == "1" ]]; then
        if git stash push -m "auto_backup_${CUR_DATE}_${CUR_TIME}" 2>/dev/null; then
            print_info "Current changes auto-backed up"
        else
            print_warn "No changes to back up"
        fi
    else
        print_warn "Auto backup is disabled, cannot restore"
    fi
    print_bold "Recent commits: "
    git log --oneline --decorate -10 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter the commit ID to reset to (first 7 chars): ${C_RESET}" commit_hash
    else
        read -r -p "Enter the commit ID to reset to (first 7 chars): " commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if ! git cat-file -t "$commit_hash" 2>/dev/null | grep -q "commit"; then
        print_error "Invalid commit ID"
        wait_key; return
    fi
    confirm_dangerous || return
    print_info "Resetting to $commit_hash..."
    if git reset --hard "$commit_hash" 2>&1; then
        print_success "Reset to $commit_hash"
        git log --oneline -5 2>&1
        log_action "RESET_SUCCESS: $commit_hash"
    else
        print_error "Reset failed"
        log_action "RESET_FAILED: $commit_hash"
    fi
    wait_key
}

git_amend() {
    check_repo || return
    if ! git log -1 >/dev/null 2>&1; then
        print_warn "No commit history"
        wait_key; return
    fi
    print_bold "Recent commits: "
    git log --oneline --decorate -10 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter the commit ID to amend (first 7 chars): ${C_RESET}" commit_hash
    else
        read -r -p "Enter the commit ID to amend (first 7 chars): " commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if ! git cat-file -t "$commit_hash" 2>/dev/null | grep -q "commit"; then
        print_error "Invalid commit ID"
        wait_key; return
    fi
    local old_msg new_msg head_hash
    old_msg="$(git log --format=%s -n 1 "$commit_hash" 2>/dev/null)"
    print_info "Current message: $old_msg"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter new message: ${C_RESET}" new_msg
    else
        read -r -p "Enter new message: " new_msg
    fi
    if [[ -z "$new_msg" ]]; then
        print_warn "Message cannot be empty"
        wait_key; return
    fi
    head_hash="$(git rev-parse HEAD 2>/dev/null)"
    if [[ "${head_hash:0:7}" == "$commit_hash" ]]; then
        if git commit --amend -m "$new_msg" 2>&1; then
            print_success "Commit message amended"
            log_action "AMEND_SUCCESS: $commit_hash"
        else
            print_error "Modification failed"
        fi
    else
        print_warn "Amending historical commits requires rewriting history"
        confirm_dangerous || return
        local commit_count
        commit_count="$(git rev-list --count HEAD 2>/dev/null)"
        local rebase_range
        if [[ "$commit_count" -lt 5 ]]; then
            rebase_range="HEAD~$commit_count"
        else
            rebase_range="HEAD~5"
        fi
        if git rebase -i "$rebase_range" 2>&1; then
            print_success "Commit modified"
            log_action "AMEND_REBASE: $commit_hash"
        else
            print_error "Rebase failed, handle it manually"
        fi
    fi
    wait_key
}

git_diff() {
    check_repo || return
    print_bold "Diff view: "
    echo "1. Working tree vs Staging"
    echo "2. Staging vs HEAD"
    echo "3. Working tree vs HEAD"
    echo "4. Between two commits"
    echo "5. Between branches"
    read -r -p "Select [1-5]: " diff_choice
    case "$diff_choice" in
        1) git diff 2>&1 ;;
        2) git diff --cached 2>&1 ;;
        3) git diff HEAD 2>&1 ;;
        4)
            git log --oneline -10 2>&1
            read -r -p "First commit ID: " commit1
            read -r -p "Second commit ID: " commit2
            git diff "$commit1" "$commit2" 2>&1
            ;;
        5)
            git branch 2>&1
            read -r -p "First branch name: " branch1
            read -r -p "Second branch name: " branch2
            git diff "$branch1" "$branch2" 2>&1
            ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_show() {
    check_repo || return
    print_bold "Commit contents view: "
    git log --oneline -15 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter commit ID: ${C_RESET}" commit_hash
    else
        read -r -p "Enter commit ID: " commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    git show "$commit_hash" --stat 2>&1
    print_dim "Press any key to view the full contents..."
    read -r -n 1 -s
    echo
    git show "$commit_hash" 2>&1 | "${PAGER:-less -R}"
    wait_key
}

git_branch_create() {
    check_repo || return
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter new branch name: ${C_RESET}" branch_name
    else
        read -r -p "Enter new branch name: " branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if ! git branch "$branch_name" 2>&1; then
        print_error "Failed to create branch"
        wait_key; return
    fi
    if git switch "$branch_name" 2>&1; then
        :
    elif git checkout "$branch_name" 2>&1; then
        :
    else
        print_error "Failed to switch branch"
        wait_key; return
    fi
    print_success "Created and switched to branch: $branch_name"
    log_action "BRANCH_CREATE: $branch_name"
    wait_key
}

git_branch_switch() {
    check_repo || return
    print_bold "Local branches: "
    git branch 2>&1
    print_bold "Remote branches: "
    git branch -r 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter the branch name to switch to: ${C_RESET}" branch_name
    else
        read -r -p "Enter the branch name to switch to: " branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if git switch "$branch_name" 2>&1; then
        :
    elif git checkout "$branch_name" 2>&1; then
        :
    else
        print_error "Failed to switch branch"
        wait_key; return
    fi
    print_success "Switched to branch: $branch_name"
    log_action "BRANCH_SWITCH: $branch_name"
    wait_key
}

git_branch_list() {
    check_repo || return
    print_bold "Local branches: "
    git branch -v 2>&1
    echo
    print_bold "Remote branches: "
    git branch -r -v 2>&1
    echo
    print_bold "All branches: "
    git branch -a -v 2>&1
    wait_key
}

git_branch_delete() {
    check_repo || return
    print_bold "All branches: "
    git branch 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter the branch name to delete: ${C_RESET}" branch_name
    else
        read -r -p "Enter the branch name to delete: " branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    local current
    current="$(git branch --show-current 2>/dev/null)"
    if [[ "$branch_name" == "$current" ]]; then
        print_error "Cannot delete the current branch"
        wait_key; return
    fi
    print_yellow "1. Safe delete (merged)"
    print_red "2. Force delete (unmerged)"
    read -r -p "Select [1-2]: " del_choice
    case "$del_choice" in
        1) git branch -d "$branch_name" 2>&1 ;;
        2)
            confirm_dangerous || return
            git branch -D "$branch_name" 2>&1
            ;;
        *) print_error "Invalid choice"; wait_key; return ;;
    esac
    if [[ $? -eq 0 ]]; then
        print_success "Branch deleted: $branch_name"
        log_action "BRANCH_DELETE: $branch_name"
    else
        print_error "Failed to delete branch"
    fi
    wait_key
}

git_branch_merge() {
    check_repo || return
    print_bold "Current branch: "
    git branch --show-current 2>&1
    echo
    print_bold "Available branches: "
    git branch 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Enter the branch name to merge: ${C_RESET}" branch_name
    else
        read -r -p "Enter the branch name to merge: " branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    local current
    current="$(git branch --show-current 2>/dev/null)"
    if [[ "$branch_name" == "$current" ]]; then
        print_warn "Cannot merge itself"
        wait_key; return
    fi
    confirm_action || return
    print_info "Merging $branch_name..."
    if git merge --no-ff "$branch_name" 2>&1; then
        print_success "Merge successful"
        log_action "MERGE_SUCCESS: $branch_name"
    else
        print_error "Merge failed, conflicts may exist"
        print_info "After resolving conflicts run git add . and git commit"
        log_action "MERGE_FAILED: $branch_name"
    fi
    wait_key
}

git_push() {
    check_repo || return
    print_bold "Remote repository: "
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Remote name (default $DEFAULT_REMOTE), press Enter to confirm: ${C_RESET}" remote_name
    else
        read -r -p "Remote name (default $DEFAULT_REMOTE), press Enter to confirm: " remote_name
    fi
    [[ -z "$remote_name" ]] && remote_name="$DEFAULT_REMOTE"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Branch name (default current branch), press Enter to confirm: ${C_RESET}" branch_name
    else
        read -r -p "Branch name (default current branch), press Enter to confirm: " branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        branch_name="$(git branch --show-current 2>/dev/null)"
    fi
    confirm_action || return
    print_info "Pushing to $remote_name/$branch_name..."
    if git push -u "$remote_name" "$branch_name" 2>&1; then
        print_success "Push successful"
        log_action "PUSH_SUCCESS: $remote_name/$branch_name"
    else
        print_error "Push failed, check the network"
        log_action "PUSH_FAILED"
    fi
    wait_key
}

git_pull() {
    check_repo || return
    print_bold "Remote repository: "
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Remote name (default $DEFAULT_REMOTE), press Enter to confirm: ${C_RESET}" remote_name
    else
        read -r -p "Remote name (default $DEFAULT_REMOTE), press Enter to confirm: " remote_name
    fi
    [[ -z "$remote_name" ]] && remote_name="$DEFAULT_REMOTE"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Branch name (default current branch), press Enter to confirm: ${C_RESET}" branch_name
    else
        read -r -p "Branch name (default current branch), press Enter to confirm: " branch_name
    fi
    if [[ -z "$branch_name" ]]; then
        branch_name="$(git branch --show-current 2>/dev/null)"
    fi
    print_info "Pulling $remote_name/$branch_name..."
    if git pull --rebase "$remote_name" "$branch_name" 2>&1; then
        print_success "Pull successful"
        log_action "PULL_SUCCESS: $remote_name/$branch_name"
    else
        print_error "Pull failed, conflicts may exist"
        log_action "PULL_FAILED"
    fi
    wait_key
}

git_clone() {
    print_bold "Current path: $CURRENT_DIR"
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Remote repository URL: ${C_RESET}" repo_url
    else
        read -r -p "Remote repository URL: " repo_url
    fi
    if [[ -z "$repo_url" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Target folder name (Enter to auto-name): ${C_RESET}" folder_name
    else
        read -r -p "Target folder name (Enter to auto-name): " folder_name
    fi
    if [[ -z "$folder_name" ]]; then
        folder_name="$(basename "$repo_url" .git)"
        folder_name="${folder_name%.git}"
    fi
    print_info "Cloning repository..."
    if git clone --progress "$repo_url" "$folder_name" 2>&1; then
        print_success "Clone successful"
        cd "$folder_name" 2>/dev/null && CURRENT_DIR="$(pwd)"
        log_action "CLONE_SUCCESS: $repo_url"
    else
        print_error "Clone failed"
        log_action "CLONE_FAILED: $repo_url"
    fi
    wait_key
}

git_remote_add() {
    check_repo || return
    print_bold "Current remote repositories: "
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Remote repository name: ${C_RESET}" remote_name
    else
        read -r -p "Remote repository name: " remote_name
    fi
    if [[ -z "$remote_name" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Remote repository URL: ${C_RESET}" remote_url
    else
        read -r -p "Remote repository URL: " remote_url
    fi
    if [[ -z "$remote_url" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    if git remote add "$remote_name" "$remote_url" 2>&1; then
        print_success "Remote repository added: $remote_name"
        log_action "REMOTE_ADD: $remote_name"
    else
        print_error "Add failed, a remote with the same name may exist"
    fi
    wait_key
}

git_remote_list() {
    check_repo || return
    print_bold "Remote repository list: "
    git remote -v 2>&1
    echo
    local remote_count=0 name
    for name in $(git remote); do
        remote_count=$((remote_count+1))
        echo
        print_cyan "[$name]"
        git remote show "$name" 2>&1
    done
    if [[ "$remote_count" -eq 0 ]]; then
        print_warn "No remote repositories configured"
    fi
    wait_key
}

git_remote_remove() {
    check_repo || return
    print_bold "Current remote repositories: "
    git remote -v 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Remote repository name to delete: ${C_RESET}" remote_name
    else
        read -r -p "Remote repository name to delete: " remote_name
    fi
    if [[ -z "$remote_name" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    confirm_dangerous || return
    if git remote remove "$remote_name" 2>&1; then
        print_success "Remote repository deleted: $remote_name"
        log_action "REMOTE_REMOVE: $remote_name"
    else
        print_error "Deletion failed"
    fi
    wait_key
}

git_stash_push() {
    check_repo || return
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Stash description (Enter for default): ${C_RESET}" stash_msg
    else
        read -r -p "Stash description (Enter for default): " stash_msg
    fi
    [[ -z "$stash_msg" ]] && stash_msg="stash $(date '+%Y-%m-%d %H:%M:%S')"
    if git stash push -m "$stash_msg" 2>&1; then
        print_success "Changes stashed"
        log_action "STASH_PUSH: $stash_msg"
    else
        print_error "Stash failed"
    fi
    wait_key
}

git_stash_pop() {
    check_repo || return
    if ! git stash list 2>/dev/null | grep -q .; then
        print_warn "No stashed work"
        wait_key; return
    fi
    print_bold "Stash list: "
    git stash list 2>&1
    echo
    print_yellow "1. Restore latest and delete"
    print_yellow "2. Restore latest but keep"
    print_yellow "3. Restore a specific stash"
    read -r -p "Select [1-3]: " pop_choice
    case "$pop_choice" in
        1) git stash pop 2>&1 ;;
        2) git stash apply 2>&1 ;;
        3)
            if [[ "$COLOR_ENABLED" == "1" ]]; then
                read -r -p "${C_CYAN}Stash index (e.g. 0): ${C_RESET}" stash_index
            else
                read -r -p "Stash index (e.g. 0): " stash_index
            fi
            if [[ -z "$stash_index" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            git stash pop "stash@{$stash_index}" 2>&1
            ;;
        *) print_error "Invalid choice"; wait_key; return ;;
    esac
    if [[ $? -eq 0 ]]; then
        print_success "Stash restored"
        log_action "STASH_POP"
    else
        print_error "Restore failed, conflicts may exist"
    fi
    wait_key
}

git_stash_list() {
    check_repo || return
    print_bold "Stash list: "
    git stash list 2>&1
    echo
    print_bold "Stash contents: "
    git stash show -p 2>&1 | "${PAGER:-less -R}"
    wait_key
}

git_stash_drop() {
    check_repo || return
    if ! git stash list 2>/dev/null | grep -q .; then
        print_warn "No stashed work"
        wait_key; return
    fi
    print_bold "Stash list: "
    git stash list 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Stash index to delete (Enter deletes latest): ${C_RESET}" stash_index
    else
        read -r -p "Stash index to delete (Enter deletes latest): " stash_index
    fi
    confirm_action || return
    if [[ -z "$stash_index" ]]; then
        git stash drop 2>&1
    else
        git stash drop "stash@{$stash_index}" 2>&1
    fi
    if [[ $? -eq 0 ]]; then
        print_success "Stash entry deleted"
        log_action "STASH_DROP"
    else
        print_error "Deletion failed"
    fi
    wait_key
}

git_clean() {
    check_repo || return
    print_bold "Untracked files: "
    git ls-files --others --exclude-standard 2>&1
    echo
    print_yellow "1. Preview files to clean"
    print_yellow "2. Delete untracked files"
    print_yellow "3. Delete all untracked (incl. ignored files)"
    print_yellow "4. Delete untracked directories"
    read -r -p "Select [1-4]: " clean_choice
    case "$clean_choice" in
        1) git clean -n 2>&1 ;;
        2)
            confirm_action || return
            git clean -f 2>&1
            log_action "CLEAN_FILES"
            ;;
        3)
            confirm_dangerous || return
            git clean -fx 2>&1
            log_action "CLEAN_ALL"
            ;;
        4)
            confirm_dangerous || return
            git clean -fd 2>&1
            log_action "CLEAN_DIRS"
            ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_restore() {
    check_repo || return
    print_bold "Modified files: "
    git status --porcelain 2>&1
    echo
    print_yellow "1. Restore a specific file"
    print_yellow "2. Restore all changes"
    print_yellow "3. Restore all changes (incl. new)"
    read -r -p "Select [1-3]: " restore_choice
    case "$restore_choice" in
        1)
            if [[ "$COLOR_ENABLED" == "1" ]]; then
                read -r -p "${C_CYAN}File path: ${C_RESET}" file_path
            else
                read -r -p "File path: " file_path
            fi
            if [[ -z "$file_path" ]]; then
                print_warn "Operation cancelled"
            else
                if git restore "$file_path" 2>&1; then
                    :
                elif git checkout -- "$file_path" 2>&1; then
                    :
                else
                    print_error "Restore failed"
                fi
                print_success "Restored: $file_path"
            fi
            ;;
        2)
            confirm_action || return
            git restore . 2>&1 || git checkout -- . 2>&1
            print_success "All changes restored"
            log_action "RESTORE_ALL"
            ;;
        3)
            confirm_dangerous || return
            git clean -fd 2>&1
            git restore . 2>&1 || git checkout -- . 2>&1
            print_success "All changes restored (incl. new)"
            log_action "RESTORE_ALL_INCL_NEW"
            ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_config() {
    check_repo || return
    print_bold "Git configuration management: "
    echo "1. Set username"
    echo "2. Set email"
    echo "3. Set default editor"
    echo "4. View global config"
    echo "5. View local config"
    echo "6. Clear config"
    read -r -p "Select [1-6]: " cfg_choice
    case "$cfg_choice" in
        1)
            read -r -p "Username: " git_user
            if [[ -n "$git_user" ]]; then
                git config --global user.name "$git_user"
                print_success "Username set"
                log_action "CONFIG_USER: $git_user"
            fi
            ;;
        2)
            read -r -p "Email: " git_mail
            if [[ -n "$git_mail" ]]; then
                git config --global user.email "$git_mail"
                print_success "Email set"
                log_action "CONFIG_EMAIL: $git_mail"
            fi
            ;;
        3)
            read -r -p "Editor command (e.g. vim, code): " git_editor
            if [[ -n "$git_editor" ]]; then
                git config --global core.editor "$git_editor"
                print_success "Editor set"
            fi
            ;;
        4) git config --global --list ;;
        5) git config --local --list ;;
        6)
            confirm_dangerous || return
            git config --global --unset-all user.name 2>/dev/null
            git config --global --unset-all user.email 2>/dev/null
            print_success "Config cleared"
            ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_abort() {
    check_repo || return
    git merge --abort 2>/dev/null
    git rebase --abort 2>/dev/null
    git cherry-pick --abort 2>/dev/null
    print_success "All conflict operations aborted"
    log_action "ABORT_CONFLICT"
    wait_key
}

git_rebase() {
    check_repo || return
    print_bold "Interactive rebase: "
    git log --oneline -10 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Commit to start rebasing from (first 7 chars): ${C_RESET}" base_commit
    else
        read -r -p "Commit to start rebasing from (first 7 chars): " base_commit
    fi
    if [[ -z "$base_commit" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    confirm_action || return
    print_info "Running interactive rebase..."
    if git rebase -i "$base_commit" 2>&1; then
        print_success "Rebase successful"
        log_action "REBASE_SUCCESS"
    else
        print_error "Rebase failed, run [33] to abort if there are conflicts"
        log_action "REBASE_FAILED"
    fi
    wait_key
}

git_tag() {
    check_repo || return
    print_bold "Tag management: "
    echo "1. View tags"
    echo "2. Create tag"
    echo "3. Delete tag"
    echo "4. Push tags to remote"
    read -r -p "Select [1-4]: " tag_choice
    case "$tag_choice" in
        1) git tag -l 2>&1 ;;
        2)
            read -r -p "Tag name: " tag_name
            if [[ -z "$tag_name" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            read -r -p "Tag message: " tag_msg
            if git tag -a "$tag_name" -m "$tag_msg" 2>&1; then
                print_success "Tag created: $tag_name"
                log_action "TAG_CREATE: $tag_name"
            else
                print_error "Failed to create tag"
            fi
            ;;
        3)
            read -r -p "Tag name to delete: " tag_name
            if [[ -z "$tag_name" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            confirm_action || return
            if git tag -d "$tag_name" 2>&1; then
                print_success "Tag deleted"
                log_action "TAG_DELETE: $tag_name"
            else
                print_error "Deletion failed"
            fi
            ;;
        4)
            read -r -p "Tag name to push (Enter pushes all): " tag_name
            if [[ -z "$tag_name" ]]; then
                git push --tags 2>&1
            else
                git push origin "$tag_name" 2>&1
            fi
            if [[ $? -eq 0 ]]; then
                print_success "Tag pushed"
                log_action "TAG_PUSH: $tag_name"
            else
                print_error "Push failed"
            fi
            ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_submodule() {
    check_repo || return
    print_bold "Submodule management: "
    echo "1. View submodules"
    echo "2. Add submodule"
    echo "3. Update submodule"
    echo "4. Initialize submodule"
    read -r -p "Select [1-4]: " sub_choice
    case "$sub_choice" in
        1) git submodule status 2>&1 ;;
        2)
            read -r -p "Submodule URL: " sub_url
            if [[ -z "$sub_url" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            read -r -p "Target path: " sub_path
            if [[ -z "$sub_path" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            if git submodule add "$sub_url" "$sub_path" 2>&1; then
                print_success "Submodule added"
                log_action "SUBMODULE_ADD: $sub_url"
            else
                print_error "Add failed"
            fi
            ;;
        3) git submodule update --remote 2>&1 ;;
        4) git submodule init 2>&1 ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_cherry_pick() {
    check_repo || return
    print_bold "Cherry-pick commit: "
    git log --oneline -15 2>&1
    echo
    if [[ "$COLOR_ENABLED" == "1" ]]; then
        read -r -p "${C_CYAN}Commit ID to cherry-pick: ${C_RESET}" commit_hash
    else
        read -r -p "Commit ID to cherry-pick: " commit_hash
    fi
    if [[ -z "$commit_hash" ]]; then
        print_warn "Operation cancelled"
        wait_key; return
    fi
    confirm_action || return
    if git cherry-pick "$commit_hash" 2>&1; then
        print_success "Cherry-pick successful"
        log_action "CHERRY_PICK_SUCCESS: $commit_hash"
    else
        print_error "Cherry-pick failed, conflicts may exist"
        log_action "CHERRY_PICK_FAILED: $commit_hash"
    fi
    wait_key
}

git_bisect() {
    check_repo || return
    print_bold "Bisect: "
    echo "1. Start bisect"
    echo "2. Mark as bad"
    echo "3. Mark as good"
    echo "4. End bisect"
    read -r -p "Select [1-4]: " bisect_choice
    case "$bisect_choice" in
        1)
            read -r -p "Bad commit ID: " bad_commit
            if [[ -z "$bad_commit" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            read -r -p "Good commit ID: " good_commit
            if [[ -z "$good_commit" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            git bisect start "$bad_commit" "$good_commit" 2>&1
            print_info "Bisect started, mark good/bad after testing"
            ;;
        2) git bisect bad 2>&1; print_info "Marked as bad" ;;
        3) git bisect good 2>&1; print_info "Marked as good" ;;
        4) git bisect reset 2>&1; print_success "Bisect ended" ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

git_worktree() {
    check_repo || return
    print_bold "Worktree management: "
    echo "1. View worktree list"
    echo "2. Add worktree"
    echo "3. Delete worktree"
    read -r -p "Select [1-3]: " worktree_choice
    case "$worktree_choice" in
        1) git worktree list 2>&1 ;;
        2)
            read -r -p "Worktree path: " worktree_path
            if [[ -z "$worktree_path" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            read -r -p "Branch name: " worktree_branch
            if [[ -z "$worktree_branch" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            if git worktree add "$worktree_path" "$worktree_branch" 2>&1; then
                print_success "Worktree added"
                log_action "WORKTREE_ADD: $worktree_path"
            else
                print_error "Add failed"
            fi
            ;;
        3)
            read -r -p "Worktree path to delete: " worktree_path
            if [[ -z "$worktree_path" ]]; then
                print_warn "Operation cancelled"
                wait_key; return
            fi
            confirm_action || return
            if git worktree remove "$worktree_path" 2>&1; then
                print_success "Worktree deleted"
                log_action "WORKTREE_REMOVE: $worktree_path"
            else
                print_error "Deletion failed"
            fi
            ;;
        *) print_error "Invalid choice" ;;
    esac
    wait_key
}

exit_tool() {
    cls
    echo
    print_bold_cyan "Git Tools v7.0"
    print_cyan "================================================================"
    print_green "Thank you for using, goodbye!"
    print_cyan "================================================================"
    echo
    log_action "EXIT_TOOL"
    exit 0
}

menu() {
    while :; do
        CURRENT_BRANCH="$(git branch --show-current 2>/dev/null)"
        cls
        if [[ "$SHOW_HEADER" == "1" ]]; then
            display_header
        else
            echo
            echo "Git Tools v7.0"
            echo "================================================================"
            echo
        fi
        display_menu

        get_input "Select an operation [1-40]: "
        case "$choice" in
            1)  git_add_all ;;
            2)  git_commit ;;
            3)  git_add_commit ;;
            4)  git_status ;;
            5)  git_log ;;
            6)  git_unstage ;;
            7)  git_delete_repo ;;
            8)  git_change_path ;;
            9)  git_init ;;
            10) git_add_source ;;
            11) git_reset_hard ;;
            12) git_amend ;;
            13) git_diff ;;
            14) git_show ;;
            15) git_branch_create ;;
            16) git_branch_switch ;;
            17) git_branch_list ;;
            18) git_branch_delete ;;
            19) git_branch_merge ;;
            20) git_push ;;
            21) git_pull ;;
            22) git_clone ;;
            23) git_remote_add ;;
            24) git_remote_list ;;
            25) git_remote_remove ;;
            26) git_stash_push ;;
            27) git_stash_pop ;;
            28) git_stash_list ;;
            29) git_stash_drop ;;
            30) git_clean ;;
            31) git_restore ;;
            32) git_config ;;
            33) git_abort ;;
            34) git_rebase ;;
            35) git_tag ;;
            36) git_submodule ;;
            37) git_cherry_pick ;;
            38) git_bisect ;;
            39) git_worktree ;;
            40) exit_tool ;;
            *)  print_error "Invalid option, enter a number between 1-40"
                wait_key ;;
        esac
    done
}

init_config
init_colors

if ping -c 1 -W 2 github.com >/dev/null 2>&1; then
    print_green "[INFO] GitHub connection is normal"
else
    print_yellow "[WARN] GitHub connection failed, remote operations may not work"
fi

check_git
check_environment
rotate_log
menu
# (Note: content generated by AI)
#（注：内容由AI生成）
