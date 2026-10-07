@echo off
setlocal enabledelayedexpansion
title Git Tools v7.0 - Professional Edition
mode con cols=100 lines=44
chcp 936 >nul 2>&1

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
set "LOG_FILE=!SCRIPT_DIR!\git_tool.log"
set "CONFIG_FILE=!SCRIPT_DIR!\git_tool.ini"
set "CURRENT_DIR=%cd%"
set "COLOR_ENABLED=1"
set "DEBUG_MODE=0"
set "SAFE_MODE=1"
set "MAX_LOG_SIZE=2097152"
set "GIT_TIMEOUT=30"
set "BACKUP_ENABLED=1"
set "CURRENT_BRANCH="
set "AUTO_PUSH=0"
set "DEFAULT_REMOTE=origin"
set "DEFAULT_BRANCH=main"
set "CONFIRM_DANGEROUS=1"
set "LOG_LEVEL=INFO"
set "SHOW_HEADER=1"
set "AUTO_CLEAN_NUL=1"

for /f "tokens=2 delims==." %%a in ('wmic os get localdatetime /value ^| find "="') do set "CUR_DATETIME=%%a"
set "CUR_DATE=!CUR_DATETIME:~0,8!"
set "CUR_TIME=!CUR_DATETIME:~8,6!"

call :INIT_CONFIG
call :INIT_COLORS

echo ping -n 1 -w 2000 github.com >nul 2>&1
if errorlevel 1 (
    if !COLOR_ENABLED!==1 (
        echo !C_YELLOW![WARN] GitHub connection failed, some remote operations may be unavailable!C_RESET!
    ) else (
        echo [WARN] GitHub connection failed, some remote operations may be unavailable
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN![INFO] GitHub connection is normal!C_RESET!
    ) else (
        echo [INFO] GitHub connection is normal
    )
)

call :CHECK_GIT
call :CHECK_ENVIRONMENT
call :ROTATE_LOG

:MENU
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
cls
if !SHOW_HEADER!==1 (
    call :DISPLAY_HEADER
) else (
    echo.
    echo Git Tools v7.0
    echo ================================================================
    echo.
)
call :DISPLAY_MENU
call :GET_INPUT choice
if !choice! geq 1 if !choice! leq 42 (
    call :EXECUTE_OPTION !choice!
) else (
    call :PRINT_ERROR "Invalid choice, enter a number between 1-42"
    call :WAIT_KEY
)
goto MENU

:EXECUTE_OPTION
set "OPTION=%~1"
if !OPTION!==40 goto EXIT_TOOL
if !OPTION!==41 call :OPEN_CMD
if !OPTION!==42 call :OPEN_POWERSHELL
if !OPTION!==1 call :GIT_ADD_ALL
if !OPTION!==2 call :GIT_COMMIT
if !OPTION!==3 call :GIT_ADD_COMMIT
if !OPTION!==4 call :GIT_STATUS
if !OPTION!==5 call :GIT_LOG
if !OPTION!==6 call :GIT_UNSTAGE
if !OPTION!==7 call :GIT_DELETE_REPO
if !OPTION!==8 call :GIT_CHANGE_PATH
if !OPTION!==9 call :GIT_INIT
if !OPTION!==10 call :GIT_ADD_SOURCE
if !OPTION!==11 call :GIT_RESET_HARD
if !OPTION!==12 call :GIT_AMEND
if !OPTION!==13 call :GIT_DIFF
if !OPTION!==14 call :GIT_SHOW
if !OPTION!==15 call :GIT_BRANCH_CREATE
if !OPTION!==16 call :GIT_BRANCH_SWITCH
if !OPTION!==17 call :GIT_BRANCH_LIST
if !OPTION!==18 call :GIT_BRANCH_DELETE
if !OPTION!==19 call :GIT_BRANCH_MERGE
if !OPTION!==20 call :GIT_PUSH
if !OPTION!==21 call :GIT_PULL
if !OPTION!==22 call :GIT_CLONE
if !OPTION!==23 call :GIT_REMOTE_ADD
if !OPTION!==24 call :GIT_REMOTE_LIST
if !OPTION!==25 call :GIT_REMOTE_REMOVE
if !OPTION!==26 call :GIT_STASH_PUSH
if !OPTION!==27 call :GIT_STASH_POP
if !OPTION!==28 call :GIT_STASH_LIST
if !OPTION!==29 call :GIT_STASH_DROP
if !OPTION!==30 call :GIT_CLEAN
if !OPTION!==31 call :GIT_RESTORE
if !OPTION!==32 call :GIT_CONFIG
if !OPTION!==33 call :GIT_ABORT
if !OPTION!==34 call :GIT_REBASE
if !OPTION!==35 call :GIT_TAG
if !OPTION!==36 call :GIT_SUBMODULE
if !OPTION!==37 call :GIT_CHERRY_PICK
if !OPTION!==38 call :GIT_BISECT
if !OPTION!==39 call :GIT_WORKTREE
goto :EOF

:EXIT_TOOL
cls
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!Git Tools v7.0!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
    echo !C_GREEN!Exited!!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
) else (
    echo Git Tools v7.0
    echo ================================================================
    echo Exited!
    echo ================================================================
)
echo.
call :LOG_ACTION "EXIT_TOOL"
exit 0

:OPEN_CMD
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!Opening CMD...!C_RESET!
) else (
    echo Opening CMD...
)
start cmd /k "title Git CMD && cd /d "!CURRENT_DIR!" && echo Current directory: !CURRENT_DIR! && echo Git commands available && git --version"
call :LOG_ACTION "OPEN_CMD"
call :WAIT_KEY
goto MENU

:OPEN_POWERSHELL
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!Opening PowerShell...!C_RESET!
) else (
    echo Opening PowerShell...
)
start powershell -NoExit -Command "Set-Location -Path '!CURRENT_DIR!'; Write-Host 'Current directory: !CURRENT_DIR!' -ForegroundColor Yellow; Write-Host 'Git commands available' -ForegroundColor Green; git --version"
call :LOG_ACTION "OPEN_POWERSHELL"
call :WAIT_KEY
goto MENU

:INIT_COLORS
if !COLOR_ENABLED!==1 (
    set "C_RESET=[0m"
    set "C_RED=[91m"
    set "C_GREEN=[92m"
    set "C_YELLOW=[93m"
    set "C_BLUE=[94m"
    set "C_MAGENTA=[95m"
    set "C_CYAN=[96m"
    set "C_WHITE=[97m"
    set "C_BOLD=[1m"
    set "C_DIM=[2m"
) else (
    set "C_RESET="
    set "C_RED="
    set "C_GREEN="
    set "C_YELLOW="
    set "C_BLUE="
    set "C_MAGENTA="
    set "C_CYAN="
    set "C_WHITE="
    set "C_BOLD="
    set "C_DIM="
)
goto :EOF

:INIT_CONFIG
if not exist "!CONFIG_FILE!" (
    echo [DEFAULT]>>"!CONFIG_FILE!"
    echo COLOR=1>>"!CONFIG_FILE!"
    echo SAFE_MODE=1>>"!CONFIG_FILE!"
    echo BACKUP_ENABLED=1>>"!CONFIG_FILE!"
    echo AUTO_PUSH=0>>"!CONFIG_FILE!"
    echo DEFAULT_REMOTE=origin>>"!CONFIG_FILE!"
    echo DEFAULT_BRANCH=main>>"!CONFIG_FILE!"
    echo CONFIRM_DANGEROUS=1>>"!CONFIG_FILE!"
    echo LOG_LEVEL=INFO>>"!CONFIG_FILE!"
    echo SHOW_HEADER=1>>"!CONFIG_FILE!"
    echo AUTO_CLEAN_NUL=1>>"!CONFIG_FILE!"
)
for /f "tokens=1,2 delims==" %%a in ('type "!CONFIG_FILE!" 2^>nul') do (
    if "%%a"=="COLOR" set "COLOR_ENABLED=%%b"
    if "%%a"=="SAFE_MODE" set "SAFE_MODE=%%b"
    if "%%a"=="BACKUP_ENABLED" set "BACKUP_ENABLED=%%b"
    if "%%a"=="AUTO_PUSH" set "AUTO_PUSH=%%b"
    if "%%a"=="DEFAULT_REMOTE" set "DEFAULT_REMOTE=%%b"
    if "%%a"=="DEFAULT_BRANCH" set "DEFAULT_BRANCH=%%b"
    if "%%a"=="CONFIRM_DANGEROUS" set "CONFIRM_DANGEROUS=%%b"
    if "%%a"=="LOG_LEVEL" set "LOG_LEVEL=%%b"
    if "%%a"=="SHOW_HEADER" set "SHOW_HEADER=%%b"
    if "%%a"=="AUTO_CLEAN_NUL" set "AUTO_CLEAN_NUL=%%b"
)
goto :EOF

:CHECK_GIT
where git >nul 2>&1
if errorlevel 1 (
    cls
    call :PRINT_ERROR "Git is not installed or not added to the PATH environment variable"
    echo.
    if !COLOR_ENABLED!==1 (
        echo  !C_YELLOW!Visit https://git-scm.com/download/win to download and install!C_RESET!
        echo  !C_YELLOW!Reopen this tool after installation!C_RESET!
    ) else (
        echo  Visit https://git-scm.com/download/win to download and install
        echo  Reopen this tool after installation
    )
    echo.
    pause
    exit /b 1
)
for /f "tokens=1-3 delims=." %%a in ('git --version 2^>nul ^| findstr /r "[0-9]"') do (
    set "GIT_MAJOR=%%a"
    set "GIT_MINOR=%%b"
    set "GIT_PATCH=%%c"
)
if !GIT_MAJOR! lss 2 (
    call :PRINT_WARN "Git version is old, upgrade to 2.x or later"
)
goto :EOF

:CHECK_ENVIRONMENT
call :PRINT_INFO "Initializing environment..."
if !AUTO_CLEAN_NUL!==1 (
    powershell -Command "if (Test-Path '!CURRENT_DIR!\nul') { Remove-Item -Path '!CURRENT_DIR!\nul' -Force }" 2>nul
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
        call :PRINT_WARN "Removed Windows reserved device file 'nul'"
    )
)
if not exist "!LOG_FILE!" (
    echo Git Tool Log - !date! !time!>"!LOG_FILE!"
    echo ========================================>>"!LOG_FILE!"
)
echo.
if !COLOR_ENABLED!==1 (
    echo !C_CYAN!==================== Configuration Status ====================!C_RESET!
) else (
    echo ==================== Configuration Status ====================
)
if !SAFE_MODE!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  Safe Mode        : Enabled!C_RESET!
        echo !C_YELLOW!    - All operations require confirmation before execution!C_RESET!
        echo !C_YELLOW!    - Dangerous operations require YES to continue!C_RESET!
    ) else (
        echo  Safe Mode        : Enabled
        echo     - All operations require confirmation before execution
        echo     - Dangerous operations require YES to continue
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_RED!  Safe Mode        : Disabled!C_RESET!
        echo !C_RED!    - WARNING: all operations run directly and cannot be undone!!C_RESET!
    ) else (
        echo  Safe Mode        : Disabled
        echo     - WARNING: all operations run directly and cannot be undone!
    )
)
if !BACKUP_ENABLED!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  Auto Backup      : Enabled!C_RESET!
        echo !C_YELLOW!    - Stashes current work automatically before reset operations!C_RESET!
    ) else (
        echo  Auto Backup      : Enabled
        echo     - Stashes current work automatically before reset operations
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_RED!  Auto Backup      : Disabled!C_RESET!
        echo !C_RED!    - WARNING: no auto backup before reset operations, data may be lost!!C_RESET!
    ) else (
        echo  Auto Backup      : Disabled
        echo     - WARNING: no auto backup before reset operations, data may be lost!
    )
)
if !AUTO_PUSH!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  Auto Push        : Enabled!C_RESET!
        echo !C_YELLOW!    - Pushes to remote automatically after a successful commit!C_RESET!
    ) else (
        echo  Auto Push        : Enabled
        echo     - Pushes to remote automatically after a successful commit
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_DIM!  Auto Push        : Disabled!C_RESET!
    ) else (
        echo  Auto Push        : Disabled
    )
)
if !CONFIRM_DANGEROUS!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_YELLOW!  Danger Confirm   : requires YES!C_RESET!
    ) else (
        echo  Danger Confirm   : requires YES
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_YELLOW!  Danger Confirm   : just enter y!C_RESET!
    ) else (
        echo  Danger Confirm   : just enter y
    )
)
if !SHOW_HEADER!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  Show Header      : Full mode!C_RESET!
        echo !C_YELLOW!    - Shows the working directory and branch info!C_RESET!
    ) else (
        echo  Show Header      : Full mode
        echo     - Shows the working directory and branch info
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_DIM!  Show Header      : Simple mode!C_RESET!
    ) else (
        echo  Show Header      : Simple mode
    )
)
if !AUTO_CLEAN_NUL!==1 (
    if !COLOR_ENABLED!==1 (
        echo !C_GREEN!  Clean NUL Files  : Enabled!C_RESET!
        echo !C_YELLOW!    - Auto-cleans Windows reserved device files!C_RESET!
    ) else (
        echo  Clean NUL Files  : Enabled
        echo     - Auto-cleans Windows reserved device files
    )
) else (
    if !COLOR_ENABLED!==1 (
        echo !C_DIM!  Clean NUL Files  : Disabled!C_RESET!
    ) else (
        echo  Clean NUL Files  : Disabled
    )
)
if !COLOR_ENABLED!==1 (
    echo !C_CYAN!  Color Display    : Enabled!C_RESET!
    echo !C_CYAN!  Default Remote   : !DEFAULT_REMOTE!!C_RESET!
    echo !C_CYAN!  Default Branch   : !DEFAULT_BRANCH!!C_RESET!
    echo !C_CYAN!  Log Level        : !LOG_LEVEL!!C_RESET!
    echo !C_CYAN!========================================================!C_RESET!
) else (
    echo  Color Display    : Disabled
    echo  Default Remote   : !DEFAULT_REMOTE!
    echo  Default Branch   : !DEFAULT_BRANCH!
    echo  Log Level        : !LOG_LEVEL!
    echo ========================================================
)
echo.
if !COLOR_ENABLED!==1 (
    echo !C_DIM!Press any key to continue...!C_RESET!
) else (
    echo Press any key to continue...
)
pause >nul
echo.
goto :EOF

:ROTATE_LOG
if not exist "!LOG_FILE!" goto :EOF
for %%i in ("!LOG_FILE!") do set "LOG_SIZE=%%~zi"
if !LOG_SIZE! gtr !MAX_LOG_SIZE! (
    set "BACKUP_NAME=git_tool_old_!CUR_DATE!_!CUR_TIME!.log"
    if exist "!BACKUP_NAME!" del "!BACKUP_NAME!" 2>nul
    move "!LOG_FILE!" "!BACKUP_NAME!" >nul 2>&1
    echo Log rotated - !date! !time!>"!LOG_FILE!"
    call :PRINT_INFO "Log rotated: !BACKUP_NAME!"
)
goto :EOF

:DISPLAY_HEADER
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!!C_CYAN!Git Tools v7.0 - Professional Edition!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
    echo !C_BOLD!Working directory: !C_RESET!!C_YELLOW!!CURRENT_DIR!!C_RESET! !C_DIM!(!C_RESET!!C_BLUE!!CURRENT_BRANCH!!C_DIM!)!C_RESET!
    echo !C_CYAN!================================================================!C_RESET!
) else (
    echo Git Tools v7.0 - Professional Edition
    echo ================================================================
    echo Working directory: !CURRENT_DIR! (!CURRENT_BRANCH!)
    echo ================================================================
)
echo.
goto :EOF

:DISPLAY_MENU
if !COLOR_ENABLED!==1 (
    echo !C_CYAN! 1!C_RESET!. Stage all changes           !C_CYAN!22!C_RESET!. Clone remote repository
    echo !C_CYAN! 2!C_RESET!. Commit changes               !C_CYAN!23!C_RESET!. Add remote repository
    echo !C_CYAN! 3!C_RESET!. Stage all and commit         !C_CYAN!24!C_RESET!. View remote repositories
    echo !C_CYAN! 4!C_RESET!. View repository status           !C_CYAN!25!C_RESET!. Delete remote repository
    echo !C_CYAN! 5!C_RESET!. View commit log           !C_CYAN!26!C_RESET!. Stash current work
    echo !C_CYAN! 6!C_RESET!. Unstage               !C_CYAN!27!C_RESET!. Restore stashed work
    echo !C_CYAN! 7!C_RESET!. Delete local repository           !C_CYAN!28!C_RESET!. View stash list
    echo !C_CYAN! 8!C_RESET!. Change working directory           !C_CYAN!29!C_RESET!. Delete stash entry
    echo !C_CYAN! 9!C_RESET!. Initialize repository             !C_CYAN!30!C_RESET!. Clean untracked files
    echo !C_CYAN!10!C_RESET!. Recursively add source files         !C_CYAN!31!C_RESET!. Discard working-tree changes
    echo !C_CYAN!11!C_RESET!. Safe reset commit           !C_CYAN!32!C_RESET!. Configure username/email
    echo !C_CYAN!12!C_RESET!. Amend commit message           !C_CYAN!33!C_RESET!. Abort merge/rebase conflicts
    echo !C_CYAN!13!C_RESET!. View file diff           !C_CYAN!34!C_RESET!. Interactive rebase
    echo !C_CYAN!14!C_RESET!. View commit details           !C_CYAN!35!C_RESET!. Tag management
    echo !C_CYAN!15!C_RESET!. Create and switch branch         !C_CYAN!36!C_RESET!. Submodule management
    echo !C_CYAN!16!C_RESET!. Switch to existing branch           !C_CYAN!37!C_RESET!. Cherry-pick commit
    echo !C_CYAN!17!C_RESET!. View all branches           !C_CYAN!38!C_RESET!. Bisect
    echo !C_CYAN!18!C_RESET!. Delete branch               !C_CYAN!39!C_RESET!. Worktree management
    echo !C_CYAN!19!C_RESET!. Merge branch               !C_CYAN!40!C_RESET!. Exit tool
    echo !C_CYAN!20!C_RESET!. Push to remote repository         !C_CYAN!41!C_RESET!. Open CMD terminal 
    echo !C_CYAN!21!C_RESET!. Pull remote updates           !C_CYAN!42!C_RESET!. Open PowerShell
    echo !C_CYAN!================================================================!C_RESET!
) else (
    echo  1. Stage all changes           22. Clone remote repository
    echo  2. Commit changes               23. Add remote repository
    echo  3. Stage all and commit         24. View remote repositories
    echo  4. View repository status           25. Delete remote repository
    echo  5. View commit log           26. Stash current work
    echo  6. Unstage               27. Restore stashed work
    echo  7. Delete local repository           28. View stash list
    echo  8. Change working directory           29. Delete stash entry
    echo  9. Initialize repository             30. Clean untracked files
    echo 10. Recursively add source files         31. Discard working-tree changes
    echo 11. Safe reset commit           32. Configure username/email
    echo 12. Amend commit message           33. Abort merge/rebase conflicts
    echo 13. View file diff           34. Interactive rebase
    echo 14. View commit details           35. Tag management
    echo 15. Create and switch branch         36. Submodule management
    echo 16. Switch to existing branch           37. Cherry-pick commit
    echo 17. View all branches           38. Bisect
    echo 18. Delete branch               39. Worktree management
    echo 19. Merge branch               40. Exit tool
    echo 20. Push to remote repository         41. Open CMD terminal
    echo 21. Pull remote updates           42. Open PowerShell
    echo ================================================================
)
echo.
goto :EOF

:GET_INPUT
if !COLOR_ENABLED!==1 (
    set /p "%~1=!C_BOLD!!C_WHITE!Select a function [1-42]: !C_RESET!"
) else (
    set /p "%~1=Select a function [1-42]: "
)
if "!%~1!"=="" set "%~1=0"
echo !%~1!|findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 set "%~1=0"
goto :EOF

:CHECK_REPO
cd /d "!CURRENT_DIR!" 2>nul
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
)
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Current directory is not a Git repository"
    echo.
    call :PRINT_INFO "Run [9] to initialize a repository or [8] to switch to a correct directory"
    call :WAIT_KEY
    goto MENU
)
goto :EOF

:PRINT_INFO
if !COLOR_ENABLED!==1 (
    echo !C_BLUE![INFO]!C_RESET! %~1
) else (
    echo [INFO] %~1
)
goto :EOF

:PRINT_SUCCESS
if !COLOR_ENABLED!==1 (
    echo !C_GREEN![OK]!C_RESET! %~1
) else (
    echo [OK] %~1
)
goto :EOF

:PRINT_WARN
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW![WARN]!C_RESET! %~1
) else (
    echo [WARN] %~1
)
goto :EOF

:PRINT_ERROR
if !COLOR_ENABLED!==1 (
    echo !C_RED![ERROR]!C_RESET! %~1
) else (
    echo [ERROR] %~1
)
goto :EOF

:WAIT_KEY
echo.
if !COLOR_ENABLED!==1 (
    echo !C_DIM!Press any key to continue...!C_RESET!
) else (
    echo Press any key to continue...
)
pause >nul
goto :EOF

:LOG_ACTION
if "!LOG_LEVEL!"=="DEBUG" (
    echo !date! !time! - %~1 >> "!LOG_FILE!" 2>nul
) else if "!LOG_LEVEL!"=="INFO" (
    echo !date! !time! - %~1 >> "!LOG_FILE!" 2>nul
)
goto :EOF

:CONFIRM_ACTION
if !SAFE_MODE!==1 (
    if !COLOR_ENABLED!==1 (
        set /p "confirm=!C_YELLOW!Confirm this operation? [y/N]: !C_RESET!"
    ) else (
        set /p "confirm=Confirm this operation? [y/N]: "
    )
    if /i not "!confirm!"=="y" if /i not "!confirm!"=="yes" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
)
goto :EOF

:CONFIRM_DANGEROUS
if !SAFE_MODE!==1 (
    if !CONFIRM_DANGEROUS!==1 (
        if !COLOR_ENABLED!==1 (
            set /p "confirm=!C_RED!Dangerous operation! Enter YES to continue, anything else cancels: !C_RESET!"
        ) else (
            set /p "confirm=Dangerous operation! Enter YES to continue, anything else cancels: "
        )
        if /i not "!confirm!"=="YES" if /i not "!confirm!"=="y" (
            call :PRINT_WARN "Operation cancelled"
            call :WAIT_KEY
            goto MENU
        )
    ) else (
        if !COLOR_ENABLED!==1 (
            set /p "confirm=!C_YELLOW!Confirm? [y/N]: !C_RESET!"
        ) else (
            set /p "confirm=Confirm? [y/N]: "
        )
        if /i not "!confirm!"=="y" if /i not "!confirm!"=="yes" (
            call :PRINT_WARN "Operation cancelled"
            call :WAIT_KEY
            goto MENU
        )
    )
)
goto :EOF

:GIT_ADD_ALL
call :CHECK_REPO
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
    git ls-files --cached | findstr /x "nul" >nul
    if not errorlevel 1 (
        git rm --cached -f --ignore-unmatch nul 2>nul
    )
)
git status --porcelain 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "No changes detected"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_INFO "Adding all changes..."
git add . 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Add failed"
    call :LOG_ACTION "ADD_ALL_FAILED"
) else (
    call :PRINT_SUCCESS "All changes added"
    call :LOG_ACTION "ADD_ALL_SUCCESS"
)
call :WAIT_KEY
goto MENU

:GIT_COMMIT
call :CHECK_REPO
git diff --cached --name-only 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Staging area is empty, add files first"
    call :WAIT_KEY
    goto MENU
)
set "commit_msg="
if !COLOR_ENABLED!==1 (
    echo Enter commit message (multi-line supported, empty line to end): 
) else (
    echo !C_CYAN!Enter commit message (multi-line supported, empty line to end): !C_RESET!
)
set "commit_msg="
:COMMIT_MSG_LOOP
set "line="
set /p "line="
if "!line!"=="" goto :COMMIT_MSG_DONE
set "commit_msg=!commit_msg!!line! "
goto :COMMIT_MSG_LOOP
:COMMIT_MSG_DONE
if "!commit_msg!"=="" set "commit_msg=Update code !date!"
if !COLOR_ENABLED!==1 (
    echo !C_BLUE!Commit message: !C_RESET!!commit_msg!
) else (
    echo Commit message: !commit_msg!
)
git commit -m "!commit_msg!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Commit failed"
    call :LOG_ACTION "COMMIT_FAILED"
) else (
    call :PRINT_SUCCESS "Commit successful"
    git log --oneline -1 2>nul
    call :LOG_ACTION "COMMIT_SUCCESS: !commit_msg!"
    if !AUTO_PUSH!==1 (
        call :PRINT_INFO "Auto-pushing..."
        git push 2>&1
    )
)
call :WAIT_KEY
goto MENU

:GIT_ADD_COMMIT
call :CHECK_REPO
if !AUTO_CLEAN_NUL!==1 (
    if exist "!CURRENT_DIR!\nul" (
        attrib -r -h -s "!CURRENT_DIR!\nul" 2>nul
        del /f /q "!CURRENT_DIR!\nul" 2>nul
        rmdir /s /q "!CURRENT_DIR!\nul" 2>nul
    )
    git ls-files --cached | findstr /x "nul" >nul
    if not errorlevel 1 (
        git rm --cached -f --ignore-unmatch nul 2>nul
    )
)
git status --porcelain 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "No changes detected"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_INFO "Adding and committing..."
git add . 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Add failed"
    call :WAIT_KEY
    goto MENU
)
set "commit_msg="
if !COLOR_ENABLED!==1 (
    set /p "commit_msg=Enter commit message: "
) else (
    set /p "commit_msg=!C_CYAN!Enter commit message: !C_RESET!"
)
if "!commit_msg!"=="" set "commit_msg=Batch commit !date!"
git commit -m "!commit_msg!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Commit failed"
    call :LOG_ACTION "ADD_COMMIT_FAILED"
) else (
    call :PRINT_SUCCESS "Commit successful"
    git log --oneline -1 2>nul
    call :LOG_ACTION "ADD_COMMIT_SUCCESS: !commit_msg!"
    if !AUTO_PUSH!==1 (
        call :PRINT_INFO "Auto-pushing..."
        git push 2>&1
    )
)
call :WAIT_KEY
goto MENU

:GIT_STATUS
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Repository status: !C_RESET!
) else (
    echo Repository status: 
)
echo.
git status 2>&1
call :WAIT_KEY
goto MENU

:GIT_LOG
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Commit history (latest 20): !C_RESET!
) else (
    echo Commit history (latest 20): 
)
echo.
git log --oneline --graph --decorate --all -20 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Detailed log (latest 10): !C_RESET!
    git log --pretty=format:"!C_CYAN!%%h!C_RESET! !C_GREEN!%%ad!C_RESET! !C_YELLOW!%%an!C_RESET!%%n%%s%%n" --date=short -10 2>&1
) else (
    echo Detailed log (latest 10): 
    git log --pretty=format:"%%h %%ad %%an%%n%%s%%n" --date=short -10 2>&1
)
call :WAIT_KEY
goto MENU

:GIT_UNSTAGE
call :CHECK_REPO
git diff --cached --name-only 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "Staging area is empty"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
call :PRINT_INFO "Unstaging..."
git reset 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Discard failed"
    call :LOG_ACTION "UNSTAGE_FAILED"
) else (
    call :PRINT_SUCCESS "Unstaged"
    call :LOG_ACTION "UNSTAGE_SUCCESS"
)
call :WAIT_KEY
goto MENU

:GIT_DELETE_REPO
call :PRINT_ERROR "This will permanently delete the entire Git repository"
call :CONFIRM_DANGEROUS
cd /d "!CURRENT_DIR!" 2>nul
if not exist ".git" (
    call :PRINT_WARN "Current directory is not a Git repository"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_INFO "Deleting Git repository..."
call :LOG_ACTION "DELETE_REPO_START"
rmdir /s /q ".git" 2>nul
if not exist ".git" (
    call :PRINT_SUCCESS "Git repository deleted"
    if exist ".gitignore" (
        del /f /q ".gitignore" 2>nul
        call :PRINT_INFO ".gitignore deleted"
    )
    call :LOG_ACTION "DELETE_REPO_SUCCESS"
) else (
    call :PRINT_ERROR "Deletion failed, trying force delete..."
    takeown /f ".git" /r /d y >nul 2>&1
    icacls ".git" /grant administrators:F /t >nul 2>&1
    rmdir /s /q ".git" 2>nul
    if not exist ".git" (
        call :PRINT_SUCCESS "Git repository force-deleted"
        call :LOG_ACTION "DELETE_REPO_FORCED"
    ) else (
        call :PRINT_ERROR "Deletion failed, manually delete the .git folder"
    )
)
call :WAIT_KEY
goto MENU

:GIT_CHANGE_PATH
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Current path: !C_RESET!!CURRENT_DIR!
) else (
    echo Current path: !CURRENT_DIR!
)
set "new_path="
if !COLOR_ENABLED!==1 (
    set /p "new_path=!C_CYAN!Enter new path: !C_RESET!"
) else (
    set /p "new_path=Enter new path: "
)
if "!new_path!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
set "new_path=!new_path:"=!"
if not exist "!new_path!\" (
    call :PRINT_ERROR "Path does not exist"
    call :WAIT_KEY
    goto MENU
)
cd /d "!new_path!" 2>nul
if errorlevel 1 (
    call :PRINT_ERROR "Cannot switch to the directory"
    call :WAIT_KEY
    goto MENU
)
set "CURRENT_DIR=!new_path!"
call :PRINT_SUCCESS "Switched to: !CURRENT_DIR!"
call :LOG_ACTION "CHANGE_PATH: !CURRENT_DIR!"
call :WAIT_KEY
goto MENU

:GIT_INIT
cd /d "!CURRENT_DIR!" 2>nul
if exist ".git" (
    call :PRINT_WARN "Current directory is already a Git repository"
    if !COLOR_ENABLED!==1 (
        set /p "confirm=!C_YELLOW!Reinitialize? [y/N]: !C_RESET!"
    ) else (
        set /p "confirm=Reinitialize? [y/N]: "
    )
    if /i not "!confirm!"=="y" if /i not "!confirm!"=="yes" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    call :PRINT_INFO "Deleting old repository..."
    rmdir /s /q ".git" 2>nul
    if exist ".git" (
        call :PRINT_ERROR "Deletion failed"
        call :WAIT_KEY
        goto MENU
    )
)
call :PRINT_INFO "Initializing Git repository..."
git init --initial-branch=!DEFAULT_BRANCH! 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Initialization failed"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_SUCCESS "Git repository initialized"
call :CREATE_GITIGNORE
git add ".gitignore" 2>nul
call :PRINT_INFO ".gitignore added to the staging area"
call :LOG_ACTION "INIT_REPO"
call :WAIT_KEY
goto MENU

:CREATE_GITIGNORE
if exist ".gitignore" goto :EOF
(
echo # ========== Operating System
echo Thumbs.db
echo ehthumbs.db
echo Desktop.ini
echo .DS_Store
echo .Spotlight-V100
echo .Trashes
echo nul
echo /nul
echo CON
echo PRN
echo AUX
echo LPT1
echo LPT2
echo LPT3
echo LPT4
echo LPT5
echo LPT6
echo LPT7
echo LPT8 
echo COM1
echo COM2
echo COM3
echo COM4
echo COM5
echo COM6
echo COM7
echo COM8
echo COM9
echo.
echo # ========== IDE and Editors
echo .vscode/
echo .idea/
echo .vs/
echo *.swp
echo *.swo
echo *~
echo *.bak
echo *.tmp
echo .project
echo .classpath
echo .settings/
echo.
echo # ========== Build Artifacts
echo *.exe
echo *.dll
echo *.so
echo *.dylib
echo *.class
echo *.o
echo *.obj
echo *.pdb
echo *.pyc
echo *.pyo
echo __pycache__/
echo *.jar
echo *.war
echo *.ear
echo target/
echo build/
echo dist/
echo out/
echo bin/
echo.
echo # ========== Log Files
echo *.log
echo logs/
echo *.pid
echo.
echo # ========== Archives
echo *.zip
echo *.rar
echo *.7z
echo *.tar
echo *.gz
echo *.bz2
echo *.xz
echo.
echo # ========== Dependencies
echo node_modules/
echo .pnpm-store/
echo vendor/
echo packages/
echo *.egg-info/
echo .mypy_cache/
echo .pytest_cache/
echo .coverage
echo htmlcov/
echo.
echo # ========== Environment Config
echo .env
echo .env.local
echo .env.*.local
echo .env.production
echo .env.development
echo *.local
echo.
echo # ========== Database
echo *.db
echo *.sqlite
echo *.sqlite3
echo.
echo # ========== Cache
echo .cache/
echo *.cache
echo *.min.js
echo *.min.css
echo *.map
echo.
echo # ========== System Files
echo .fuse_hidden*
echo .directory
echo .lock-wscript
echo .npm/
echo .yarn/
echo package-lock.json
echo yarn.lock
echo pnpm-lock.yaml
) > .gitignore
goto :EOF

:GIT_ADD_SOURCE
call :CHECK_REPO
call :PRINT_INFO "Scanning source code files..."
set "SOURCE_EXTS=.c .cpp .cc .cxx .h .hpp .hxx .java .py .pyw .js .ts .jsx .tsx .go .rs .rb .php .html .htm .css .scss .less .vue .svelte .xml .json .yaml .yml .toml .ini .cfg .conf .sh .bash .zsh .fish .ps1 .pl .pm .lua .r .m .swift .kt .kts .dart .erl .hrl .ex .exs .clj .cljs .edn .scala .sbt .groovy .gradle .lisp .cl .el .sql .prisma .proto .md .markdown .txt .rst .adoc .asciidoc .org .tex .latex .bib"
set "FILE_COUNT=0"
set "ADD_COUNT=0"
set "TEMP_FILE=!SCRIPT_DIR!\temp_filelist.txt"
if exist "!TEMP_FILE!" del "!TEMP_FILE!" 2>nul
for %%e in (%SOURCE_EXTS%) do (
    dir /s /b "*%%e" 2>nul >> "!TEMP_FILE!"
)
if not exist "!TEMP_FILE!" (
    call :PRINT_WARN "No source code files found"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%f in ('find /c /v "" ^< "!TEMP_FILE!"') do set "FILE_COUNT=%%f"
if !FILE_COUNT!==0 (
    call :PRINT_WARN "No source code files found"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_SUCCESS "Found !FILE_COUNT! source code file(s)"
echo.
if !COLOR_ENABLED!==1 (
    echo !C_DIM!Adding files...!C_RESET!
) else (
    echo Adding files...
)
set "DISPLAY_COUNT=0"
for /f "delims=" %%i in ('type "!TEMP_FILE!"') do (
    if !DISPLAY_COUNT! lss 20 (
        set /a DISPLAY_COUNT+=1
        echo   !DISPLAY_COUNT!. %%~nxi
    )
    git add "%%~i" 2>nul
    set /a ADD_COUNT+=1
    if !ADD_COUNT!==100 (
        set /a ADD_COUNT=0
        if !COLOR_ENABLED!==1 (
            echo !C_DIM!.!C_RESET!
        ) else (
            echo .
        )
    )
)
del "!TEMP_FILE!" 2>nul
call :PRINT_SUCCESS "Added !FILE_COUNT! source code file(s)"
if exist ".gitignore" (
    git add ".gitignore" 2>nul
    call :PRINT_INFO ".gitignore added to the staging area"
)
call :LOG_ACTION "ADD_SOURCE: !FILE_COUNT! files"
call :WAIT_KEY
goto MENU

:GIT_RESET_HARD
call :CHECK_REPO
git log -1 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "No commit history"
    call :WAIT_KEY
    goto MENU
)
call :PRINT_WARN "This will discard all uncommitted changes"
if !BACKUP_ENABLED!==1 (
    git stash push -m "auto_backup_!CUR_DATE!_!CUR_TIME!" 2>nul
    if errorlevel 1 (
        call :PRINT_WARN "No changes to back up"
    ) else (
        call :PRINT_INFO "Current work auto-backed up"
    )
) else (
    call :PRINT_WARN "Auto backup is disabled, cannot restore"
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Recent commits: !C_RESET!
) else (
    echo Recent commits: 
)
git log --oneline --decorate -10 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!Enter the commit ID to reset to (first 7 chars): !C_RESET!"
) else (
    set /p "commit_hash=Enter the commit ID to reset to (first 7 chars): "
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
git cat-file -t "!commit_hash!" 2>nul | findstr "commit" >nul
if errorlevel 1 (
    call :PRINT_ERROR "Commit ID does not exist"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_DANGEROUS
call :PRINT_INFO "Resetting to !commit_hash!..."
git reset --hard "!commit_hash!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Reset failed"
    call :LOG_ACTION "RESET_FAILED: !commit_hash!"
) else (
    call :PRINT_SUCCESS "Reset to !commit_hash!"
    git log --oneline -5 2>&1
    call :LOG_ACTION "RESET_SUCCESS: !commit_hash!"
)
call :WAIT_KEY
goto MENU

:GIT_AMEND
call :CHECK_REPO
git log -1 2>nul | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "No commit history"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Recent commits: !C_RESET!
) else (
    echo Recent commits: 
)
git log --oneline --decorate -10 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!Enter the commit ID to amend (first 7 chars): !C_RESET!"
) else (
    set /p "commit_hash=Enter the commit ID to amend (first 7 chars): "
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
git cat-file -t "!commit_hash!" 2>nul | findstr "commit" >nul
if errorlevel 1 (
    call :PRINT_ERROR "Commit ID does not exist"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git log --format=%%s -n 1 "!commit_hash!" 2^>nul') do set "OLD_MSG=%%i"
if !COLOR_ENABLED!==1 (
    echo !C_BLUE!Current message: !C_RESET!!OLD_MSG!
) else (
    echo Current message: !OLD_MSG!
)
set "new_msg="
if !COLOR_ENABLED!==1 (
    set /p "new_msg=!C_CYAN!Enter new message: !C_RESET!"
) else (
    set /p "new_msg=Enter new message: "
)
if "!new_msg!"=="" (
    call :PRINT_WARN "Message cannot be empty"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set "HEAD_HASH=%%i"
if "!HEAD_HASH:~0,7!"=="!commit_hash!" (
    git commit --amend -m "!new_msg!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Modification failed"
    ) else (
        call :PRINT_SUCCESS "Commit message amended"
        call :LOG_ACTION "AMEND_SUCCESS: !commit_hash!"
    )
) else (
    call :PRINT_WARN "Amending historical commits may rewrite history"
    call :CONFIRM_DANGEROUS
    for /f "delims=" %%i in ('git rev-list --count HEAD 2^>nul') do set "COMMIT_COUNT=%%i"
    if !COMMIT_COUNT! lss 5 (
        set "REBASE_RANGE=HEAD~!COMMIT_COUNT!"
    ) else (
        set "REBASE_RANGE=HEAD~5"
    )
    git rebase -i !REBASE_RANGE! 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Rebase failed, handle it manually"
    ) else (
        call :PRINT_SUCCESS "Commit modified"
        call :LOG_ACTION "AMEND_REBASE: !commit_hash!"
    )
)
call :WAIT_KEY
goto MENU

:GIT_DIFF
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Diff view: !C_RESET!
    echo !C_CYAN!1!C_RESET!. Working tree vs Staging
    echo !C_CYAN!2!C_RESET!. Staging vs HEAD
    echo !C_CYAN!3!C_RESET!. Working tree vs HEAD
    echo !C_CYAN!4!C_RESET!. Between two commits
    echo !C_CYAN!5!C_RESET!. Branch differences
) else (
    echo Diff view: 
    echo 1. Working tree vs Staging
    echo 2. Staging vs HEAD
    echo 3. Working tree vs HEAD
    echo 4. Between two commits
    echo 5. Branch differences
)
set /p "diff_choice=Select [1-5]: "
if "!diff_choice!"=="1" git diff 2>&1
if "!diff_choice!"=="2" git diff --cached 2>&1
if "!diff_choice!"=="3" git diff HEAD 2>&1
if "!diff_choice!"=="4" (
    git log --oneline -10 2>&1
    if !COLOR_ENABLED!==1 (
        set /p "commit1=!C_CYAN!First commit ID: !C_RESET!"
        set /p "commit2=!C_CYAN!Second commit ID: !C_RESET!"
    ) else (
        set /p "commit1=First commit ID: "
        set /p "commit2=Second commit ID: "
    )
    git diff "!commit1!" "!commit2!" 2>&1
)
if "!diff_choice!"=="5" (
    git branch 2>&1
    if !COLOR_ENABLED!==1 (
        set /p "branch1=!C_CYAN!First branch: !C_RESET!"
        set /p "branch2=!C_CYAN!Second branch: !C_RESET!"
    ) else (
        set /p "branch1=First branch: "
        set /p "branch2=Second branch: "
    )
    git diff "!branch1!" "!branch2!" 2>&1
)
call :WAIT_KEY
goto MENU

:GIT_SHOW
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Commit details view: !C_RESET!
) else (
    echo Commit details view: 
)
git log --oneline -15 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!Enter commit ID: !C_RESET!"
) else (
    set /p "commit_hash=Enter commit ID: "
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
git show "!commit_hash!" --stat 2>&1
if !COLOR_ENABLED!==1 (
    echo !C_DIM!Press any key to view the full diff...!C_RESET!
) else (
    echo Press any key to view the full diff...
)
pause >nul
git show "!commit_hash!" 2>&1 | more
call :WAIT_KEY
goto MENU

:GIT_BRANCH_CREATE
call :CHECK_REPO
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!Enter new branch name: !C_RESET!"
) else (
    set /p "branch_name=Enter new branch name: "
)
if "!branch_name!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
git branch "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Failed to create branch"
    call :WAIT_KEY
    goto MENU
)
git switch "!branch_name!" 2>&1
if errorlevel 1 (
    git checkout "!branch_name!" 2>&1
)
if errorlevel 1 (
    call :PRINT_ERROR "Failed to switch branch"
) else (
    call :PRINT_SUCCESS "Created and switched to branch: !branch_name!"
    call :LOG_ACTION "BRANCH_CREATE: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_BRANCH_SWITCH
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Local branches: !C_RESET!
) else (
    echo Local branches: 
)
git branch 2>&1
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Remote branches: !C_RESET!
) else (
    echo Remote branches: 
)
git branch -r 2>&1
echo.
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!Enter the branch name to switch to: !C_RESET!"
) else (
    set /p "branch_name=Enter the branch name to switch to: "
)
if "!branch_name!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
git switch "!branch_name!" 2>&1
if errorlevel 1 (
    git checkout "!branch_name!" 2>&1
)
if errorlevel 1 (
    call :PRINT_ERROR "Failed to switch branch"
) else (
    call :PRINT_SUCCESS "Switched to branch: !branch_name!"
    call :LOG_ACTION "BRANCH_SWITCH: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_BRANCH_LIST
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Local branches: !C_RESET!
) else (
    echo Local branches: 
)
git branch -v 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Remote branches: !C_RESET!
) else (
    echo Remote branches: 
)
git branch -r -v 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!All branches: !C_RESET!
) else (
    echo All branches: 
)
git branch -a -v 2>&1
call :WAIT_KEY
goto MENU

:GIT_BRANCH_DELETE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Existing branches: !C_RESET!
) else (
    echo Existing branches: 
)
git branch 2>&1
echo.
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!Enter the branch name to delete: !C_RESET!"
) else (
    set /p "branch_name=Enter the branch name to delete: "
)
if "!branch_name!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
if "!branch_name!"=="!CURRENT_BRANCH!" (
    call :PRINT_ERROR "Cannot delete the current branch"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. Safe delete (merged)!C_RESET!
    echo !C_RED!2. Force delete (unmerged)!C_RESET!
) else (
    echo 1. Safe delete (merged)
    echo 2. Force delete (unmerged)
)
set /p "del_choice=Select [1-2]: "
if "!del_choice!"=="1" (
    git branch -d "!branch_name!" 2>&1
) else if "!del_choice!"=="2" (
    call :CONFIRM_DANGEROUS
    git branch -D "!branch_name!" 2>&1
) else (
    call :PRINT_ERROR "Invalid option"
    call :WAIT_KEY
    goto MENU
)
if errorlevel 1 (
    call :PRINT_ERROR "Failed to delete branch"
) else (
    call :PRINT_SUCCESS "Branch deleted: !branch_name!"
    call :LOG_ACTION "BRANCH_DELETE: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_BRANCH_MERGE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Current branch: !C_RESET!
) else (
    echo Current branch: 
)
git branch --show-current 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Available branches: !C_RESET!
) else (
    echo Available branches: 
)
git branch 2>&1
echo.
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!Enter the branch to merge: !C_RESET!"
) else (
    set /p "branch_name=Enter the branch to merge: "
)
if "!branch_name!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%i"
if "!branch_name!"=="!CURRENT_BRANCH!" (
    call :PRINT_WARN "Cannot merge itself"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
call :PRINT_INFO "Merging !branch_name!..."
git merge --no-ff "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Merge failed, resolve the conflicts"
    call :PRINT_INFO "After resolving conflicts run git add . and git commit"
    call :LOG_ACTION "MERGE_FAILED: !branch_name!"
) else (
    call :PRINT_SUCCESS "Merge successful"
    call :LOG_ACTION "MERGE_SUCCESS: !branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_PUSH
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Remote repository: !C_RESET!
) else (
    echo Remote repository: 
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Remote name (default !DEFAULT_REMOTE!): !C_RESET!"
) else (
    set /p "remote_name=Remote name (default !DEFAULT_REMOTE!): "
)
if "!remote_name!"=="" set "remote_name=!DEFAULT_REMOTE!"
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!Branch name (default current): !C_RESET!"
) else (
    set /p "branch_name=Branch name (default current): "
)
if "!branch_name!"=="" (
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "branch_name=%%i"
)
call :CONFIRM_ACTION
call :PRINT_INFO "Pushing to !remote_name!/!branch_name!..."
git push -u "!remote_name!" "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Push failed, pull updates first"
    call :LOG_ACTION "PUSH_FAILED"
) else (
    call :PRINT_SUCCESS "Push successful"
    call :LOG_ACTION "PUSH_SUCCESS: !remote_name!/!branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_PULL
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Remote repository: !C_RESET!
) else (
    echo Remote repository: 
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Remote name (default !DEFAULT_REMOTE!): !C_RESET!"
) else (
    set /p "remote_name=Remote name (default !DEFAULT_REMOTE!): "
)
if "!remote_name!"=="" set "remote_name=!DEFAULT_REMOTE!"
set "branch_name="
if !COLOR_ENABLED!==1 (
    set /p "branch_name=!C_CYAN!Branch name (default current): !C_RESET!"
) else (
    set /p "branch_name=Branch name (default current): "
)
if "!branch_name!"=="" (
    for /f "delims=" %%i in ('git branch --show-current 2^>nul') do set "branch_name=%%i"
)
call :PRINT_INFO "Pulling !remote_name!/!branch_name!..."
git pull --rebase "!remote_name!" "!branch_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Pull failed, resolve the conflicts"
    call :LOG_ACTION "PULL_FAILED"
) else (
    call :PRINT_SUCCESS "Pull successful"
    call :LOG_ACTION "PULL_SUCCESS: !remote_name!/!branch_name!"
)
call :WAIT_KEY
goto MENU

:GIT_CLONE
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Current path: !C_RESET!!CURRENT_DIR!
) else (
    echo Current path: !CURRENT_DIR!
)
set "repo_url="
if !COLOR_ENABLED!==1 (
    set /p "repo_url=!C_CYAN!Remote repository URL: !C_RESET!"
) else (
    set /p "repo_url=Remote repository URL: "
)
if "!repo_url!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
set "folder_name="
if !COLOR_ENABLED!==1 (
    set /p "folder_name=!C_CYAN!Target folder name (Enter to auto-name): !C_RESET!"
) else (
    set /p "folder_name=Target folder name (Enter to auto-name): "
)
if "!folder_name!"=="" (
    set "folder_name=!repo_url:.git=!"
    for /f "delims=/" %%a in ("!folder_name!") do set "folder_name=%%a"
)
call :PRINT_INFO "Cloning repository..."
git clone --progress "!repo_url!" "!folder_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Clone failed"
    call :LOG_ACTION "CLONE_FAILED: !repo_url!"
) else (
    call :PRINT_SUCCESS "Clone successful"
    cd /d "!folder_name!" 2>nul
    set "CURRENT_DIR=!cd!"
    call :LOG_ACTION "CLONE_SUCCESS: !repo_url!"
)
call :WAIT_KEY
goto MENU

:GIT_REMOTE_ADD
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Current remote repositories: !C_RESET!
) else (
    echo Current remote repositories: 
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Remote repository name: !C_RESET!"
) else (
    set /p "remote_name=Remote repository name: "
)
if "!remote_name!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
set "remote_url="
if !COLOR_ENABLED!==1 (
    set /p "remote_url=!C_CYAN!Remote repository URL: !C_RESET!"
) else (
    set /p "remote_url=Remote repository URL: "
)
if "!remote_url!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
git remote add "!remote_name!" "!remote_url!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Add failed, a remote with the same name may already exist"
) else (
    call :PRINT_SUCCESS "Remote repository added: !remote_name!"
    call :LOG_ACTION "REMOTE_ADD: !remote_name!"
)
call :WAIT_KEY
goto MENU

:GIT_REMOTE_LIST
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Remote repository list: !C_RESET!
) else (
    echo Remote repository list: 
)
git remote -v 2>&1
echo.
set "REMOTE_COUNT=0"
for /f "delims=" %%i in ('git remote') do (
    set /a REMOTE_COUNT+=1
    echo.
    if !COLOR_ENABLED!==1 (
        echo !C_CYAN![%%i]!C_RESET!
    ) else (
        echo [%%i]
    )
    git remote show %%i 2>&1
)
if !REMOTE_COUNT!==0 (
    call :PRINT_WARN "No remote repositories configured"
)
call :WAIT_KEY
goto MENU

:GIT_REMOTE_REMOVE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Current remote repositories: !C_RESET!
) else (
    echo Current remote repositories: 
)
git remote -v 2>&1
echo.
set "remote_name="
if !COLOR_ENABLED!==1 (
    set /p "remote_name=!C_CYAN!Remote repository name to delete: !C_RESET!"
) else (
    set /p "remote_name=Remote repository name to delete: "
)
if "!remote_name!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_DANGEROUS
git remote remove "!remote_name!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Deletion failed"
) else (
    call :PRINT_SUCCESS "Remote repository deleted: !remote_name!"
    call :LOG_ACTION "REMOTE_REMOVE: !remote_name!"
)
call :WAIT_KEY
goto MENU

:GIT_STASH_PUSH
call :CHECK_REPO
set "stash_msg="
if !COLOR_ENABLED!==1 (
    set /p "stash_msg=!C_CYAN!Stash description (Enter for default): !C_RESET!"
) else (
    set /p "stash_msg=Stash description (Enter for default): "
)
if "!stash_msg!"=="" set "stash_msg=stash !date! !time!"
git stash push -m "!stash_msg!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Stash failed"
) else (
    call :PRINT_SUCCESS "Work stashed"
    call :LOG_ACTION "STASH_PUSH: !stash_msg!"
)
call :WAIT_KEY
goto MENU

:GIT_STASH_POP
call :CHECK_REPO
git stash list 2>&1 | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "No stashed work"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Stash list: !C_RESET!
) else (
    echo Stash list: 
)
git stash list 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. Restore latest and delete!C_RESET!
    echo !C_YELLOW!2. Restore latest and keep!C_RESET!
    echo !C_YELLOW!3. Restore a specific stash!C_RESET!
) else (
    echo 1. Restore latest and delete
    echo 2. Restore latest and keep
    echo 3. Restore a specific stash
)
set /p "pop_choice=Select [1-3]: "
if "!pop_choice!"=="1" (
    git stash pop 2>&1
) else if "!pop_choice!"=="2" (
    git stash apply 2>&1
) else if "!pop_choice!"=="3" (
    set "stash_index="
    if !COLOR_ENABLED!==1 (
        set /p "stash_index=!C_CYAN!Stash index (enter a number, e.g. 0): !C_RESET!"
    ) else (
        set /p "stash_index=Stash index (enter a number, e.g. 0): "
    )
    if "!stash_index!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    git stash pop stash@^^{!stash_index!^} 2>&1
) else (
    call :PRINT_ERROR "Invalid option"
    call :WAIT_KEY
    goto MENU
)
if errorlevel 1 (
    call :PRINT_ERROR "Restore failed, conflicts may exist"
) else (
    call :PRINT_SUCCESS "Work restored"
    call :LOG_ACTION "STASH_POP"
)
call :WAIT_KEY
goto MENU

:GIT_STASH_LIST
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Stash list: !C_RESET!
) else (
    echo Stash list: 
)
git stash list 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Stash details: !C_RESET!
) else (
    echo Stash details: 
)
git stash show -p 2>&1 | more
call :WAIT_KEY
goto MENU

:GIT_STASH_DROP
call :CHECK_REPO
git stash list 2>&1 | findstr . >nul
if errorlevel 1 (
    call :PRINT_WARN "No stashed work"
    call :WAIT_KEY
    goto MENU
)
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Stash list: !C_RESET!
) else (
    echo Stash list: 
)
git stash list 2>&1
echo.
set "stash_index="
if !COLOR_ENABLED!==1 (
    set /p "stash_index=!C_CYAN!Stash index to delete (enter a number, leave empty for latest): !C_RESET!"
) else (
    set /p "stash_index=Stash index to delete (enter a number, leave empty for latest): "
)
call :CONFIRM_ACTION
if "!stash_index!"=="" (
    git stash drop 2>&1
) else (
    git stash drop stash@^^{!stash_index!^} 2>&1
)
if errorlevel 1 (
    call :PRINT_ERROR "Deletion failed"
) else (
    call :PRINT_SUCCESS "Stash deleted"
    call :LOG_ACTION "STASH_DROP"
)
call :WAIT_KEY
goto MENU

:GIT_CLEAN
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Untracked files: !C_RESET!
) else (
    echo Untracked files: 
)
git ls-files --others --exclude-standard 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. Preview (show only)!C_RESET!
    echo !C_YELLOW!2. Delete untracked files!C_RESET!
    echo !C_YELLOW!3. Delete all untracked (incl. ignored)!C_RESET!
    echo !C_YELLOW!4. Delete untracked directories!C_RESET!
) else (
    echo 1. Preview (show only)
    echo 2. Delete untracked files
    echo 3. Delete all untracked (incl. ignored)
    echo 4. Delete untracked directories
)
set /p "clean_choice=Select [1-4]: "
if "!clean_choice!"=="1" git clean -n 2>&1
if "!clean_choice!"=="2" (
    call :CONFIRM_ACTION
    git clean -f 2>&1
    call :LOG_ACTION "CLEAN_FILES"
)
if "!clean_choice!"=="3" (
    call :CONFIRM_DANGEROUS
    git clean -fx 2>&1
    call :LOG_ACTION "CLEAN_ALL"
)
if "!clean_choice!"=="4" (
    call :CONFIRM_DANGEROUS
    git clean -fd 2>&1
    call :LOG_ACTION "CLEAN_DIRS"
)
call :WAIT_KEY
goto MENU

:GIT_RESTORE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Modified files: !C_RESET!
) else (
    echo Modified files: 
)
git status --porcelain 2>&1
echo.
if !COLOR_ENABLED!==1 (
    echo !C_YELLOW!1. Discard a single file!C_RESET!
    echo !C_YELLOW!2. Discard all changes!C_RESET!
    echo !C_YELLOW!3. Discard all changes (incl. new)!C_RESET!
) else (
    echo 1. Discard a single file
    echo 2. Discard all changes
    echo 3. Discard all changes (incl. new)
)
set /p "restore_choice=Select [1-3]: "
if "!restore_choice!"=="1" (
    set "file_path="
    if !COLOR_ENABLED!==1 (
        set /p "file_path=!C_CYAN!File path: !C_RESET!"
    ) else (
        set /p "file_path=File path: "
    )
    if "!file_path!"=="" (
        call :PRINT_WARN "Operation cancelled"
    ) else (
        git restore "!file_path!" 2>&1
        if errorlevel 1 (
            git checkout -- "!file_path!" 2>&1
        )
        if errorlevel 1 (
            call :PRINT_ERROR "Discard failed"
        ) else (
            call :PRINT_SUCCESS "Discarded: !file_path!"
        )
    )
)
if "!restore_choice!"=="2" (
    call :CONFIRM_ACTION
    git restore . 2>&1
    if errorlevel 1 (
        git checkout -- . 2>&1
    )
    call :PRINT_SUCCESS "All changes discarded"
    call :LOG_ACTION "RESTORE_ALL"
)
if "!restore_choice!"=="3" (
    call :CONFIRM_DANGEROUS
    git clean -fd 2>&1
    git restore . 2>&1
    if errorlevel 1 (
        git checkout -- . 2>&1
    )
    call :PRINT_SUCCESS "All changes discarded"
    call :LOG_ACTION "RESTORE_ALL_INCL_NEW"
)
call :WAIT_KEY
goto MENU

:GIT_CONFIG
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Git configuration management: !C_RESET!
    echo !C_CYAN!1!C_RESET!. Set username
    echo !C_CYAN!2!C_RESET!. Set email
    echo !C_CYAN!3!C_RESET!. Set default editor
    echo !C_CYAN!4!C_RESET!. View global config
    echo !C_CYAN!5!C_RESET!. View local config
    echo !C_CYAN!6!C_RESET!. Reset config
) else (
    echo Git configuration management: 
    echo 1. Set username
    echo 2. Set email
    echo 3. Set default editor
    echo 4. View global config
    echo 5. View local config
    echo 6. Reset config
)
set /p "cfg_choice=Select [1-6]: "
if "!cfg_choice!"=="1" (
    set "git_user="
    if !COLOR_ENABLED!==1 (
        set /p "git_user=!C_CYAN!Username: !C_RESET!"
    ) else (
        set /p "git_user=Username: "
    )
    if not "!git_user!"=="" (
        git config --global user.name "!git_user!"
        call :PRINT_SUCCESS "Username set"
        call :LOG_ACTION "CONFIG_USER: !git_user!"
    )
)
if "!cfg_choice!"=="2" (
    set "git_mail="
    if !COLOR_ENABLED!==1 (
        set /p "git_mail=!C_CYAN!Email: !C_RESET!"
    ) else (
        set /p "git_mail=Email: "
    )
    if not "!git_mail!"=="" (
        git config --global user.email "!git_mail!"
        call :PRINT_SUCCESS "Email set"
        call :LOG_ACTION "CONFIG_EMAIL: !git_mail!"
    )
)
if "!cfg_choice!"=="3" (
    set "git_editor="
    if !COLOR_ENABLED!==1 (
        set /p "git_editor=!C_CYAN!Editor command (e.g. vim, code): !C_RESET!"
    ) else (
        set /p "git_editor=Editor command (e.g. vim, code): "
    )
    if not "!git_editor!"=="" (
        git config --global core.editor "!git_editor!"
        call :PRINT_SUCCESS "Editor set"
    )
)
if "!cfg_choice!"=="4" git config --global --list
if "!cfg_choice!"=="5" git config --local --list
if "!cfg_choice!"=="6" (
    call :CONFIRM_DANGEROUS
    git config --global --unset-all user.name 2>nul
    git config --global --unset-all user.email 2>nul
    call :PRINT_SUCCESS "Config reset"
)
call :WAIT_KEY
goto MENU

:GIT_ABORT
call :CHECK_REPO
git merge --abort 2>nul
git rebase --abort 2>nul
git cherry-pick --abort 2>nul
call :PRINT_SUCCESS "All conflict operations aborted"
call :LOG_ACTION "ABORT_CONFLICT"
call :WAIT_KEY
goto MENU

:GIT_REBASE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Interactive rebase: !C_RESET!
) else (
    echo Interactive rebase: 
)
git log --oneline -10 2>&1
echo.
set "base_commit="
if !COLOR_ENABLED!==1 (
    set /p "base_commit=!C_CYAN!Commit to start rebasing from (first 7 chars): !C_RESET!"
) else (
    set /p "base_commit=Commit to start rebasing from (first 7 chars): "
)
if "!base_commit!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
call :PRINT_INFO "Starting interactive rebase..."
git rebase -i "!base_commit!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Rebase failed, resolve conflicts or run [33] to abort"
    call :LOG_ACTION "REBASE_FAILED"
) else (
    call :PRINT_SUCCESS "Rebase successful"
    call :LOG_ACTION "REBASE_SUCCESS"
)
call :WAIT_KEY
goto MENU

:GIT_TAG
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Tag management: !C_RESET!
    echo !C_CYAN!1!C_RESET!. View tags
    echo !C_CYAN!2!C_RESET!. Create tag
    echo !C_CYAN!3!C_RESET!. Delete tag
    echo !C_CYAN!4!C_RESET!. Push tags to remote
) else (
    echo Tag management: 
    echo 1. View tags
    echo 2. Create tag
    echo 3. Delete tag
    echo 4. Push tags to remote
)
set /p "tag_choice=Select [1-4]: "
if "!tag_choice!"=="1" git tag -l 2>&1
if "!tag_choice!"=="2" (
    set "tag_name="
    if !COLOR_ENABLED!==1 (
        set /p "tag_name=!C_CYAN!Tag name: !C_RESET!"
    ) else (
        set /p "tag_name=Tag name: "
    )
    if "!tag_name!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    set "tag_msg="
    if !COLOR_ENABLED!==1 (
        set /p "tag_msg=!C_CYAN!Tag message: !C_RESET!"
    ) else (
        set /p "tag_msg=Tag message: "
    )
    git tag -a "!tag_name!" -m "!tag_msg!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Failed to create tag"
    ) else (
        call :PRINT_SUCCESS "Tag created: !tag_name!"
        call :LOG_ACTION "TAG_CREATE: !tag_name!"
    )
)
if "!tag_choice!"=="3" (
    set "tag_name="
    if !COLOR_ENABLED!==1 (
        set /p "tag_name=!C_CYAN!Tag to delete: !C_RESET!"
    ) else (
        set /p "tag_name=Tag to delete: "
    )
    if "!tag_name!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    call :CONFIRM_ACTION
    git tag -d "!tag_name!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Deletion failed"
    ) else (
        call :PRINT_SUCCESS "Tag deleted"
        call :LOG_ACTION "TAG_DELETE: !tag_name!"
    )
)
if "!tag_choice!"=="4" (
    set "tag_name="
    if !COLOR_ENABLED!==1 (
        set /p "tag_name=!C_CYAN!Tag to push (leave empty to push all): !C_RESET!"
    ) else (
        set /p "tag_name=Tag to push (leave empty to push all): "
    )
    if "!tag_name!"=="" (
        git push --tags 2>&1
    ) else (
        git push origin "!tag_name!" 2>&1
    )
    if errorlevel 1 (
        call :PRINT_ERROR "Push failed"
    ) else (
        call :PRINT_SUCCESS "Tag pushed"
        call :LOG_ACTION "TAG_PUSH: !tag_name!"
    )
)
call :WAIT_KEY
goto MENU

:GIT_SUBMODULE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Submodule management: !C_RESET!
    echo !C_CYAN!1!C_RESET!. View submodules
    echo !C_CYAN!2!C_RESET!. Add submodule
    echo !C_CYAN!3!C_RESET!. Update submodule
    echo !C_CYAN!4!C_RESET!. Initialize submodule
) else (
    echo Submodule management: 
    echo 1. View submodules
    echo 2. Add submodule
    echo 3. Update submodule
    echo 4. Initialize submodule
)
set /p "sub_choice=Select [1-4]: "
if "!sub_choice!"=="1" git submodule status 2>&1
if "!sub_choice!"=="2" (
    set "sub_url="
    if !COLOR_ENABLED!==1 (
        set /p "sub_url=!C_CYAN!Submodule URL: !C_RESET!"
    ) else (
        set /p "sub_url=Submodule URL: "
    )
    if "!sub_url!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    set "sub_path="
    if !COLOR_ENABLED!==1 (
        set /p "sub_path=!C_CYAN!Local path: !C_RESET!"
    ) else (
        set /p "sub_path=Local path: "
    )
    if "!sub_path!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    git submodule add "!sub_url!" "!sub_path!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Add failed"
    ) else (
        call :PRINT_SUCCESS "Submodule added"
        call :LOG_ACTION "SUBMODULE_ADD: !sub_url!"
    )
)
if "!sub_choice!"=="3" git submodule update --remote 2>&1
if "!sub_choice!"=="4" git submodule init 2>&1
call :WAIT_KEY
goto MENU

:GIT_CHERRY_PICK
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Cherry-pick commit: !C_RESET!
) else (
    echo Cherry-pick commit: 
)
git log --oneline -15 2>&1
echo.
set "commit_hash="
if !COLOR_ENABLED!==1 (
    set /p "commit_hash=!C_CYAN!Commit ID to cherry-pick: !C_RESET!"
) else (
    set /p "commit_hash=Commit ID to cherry-pick: "
)
if "!commit_hash!"=="" (
    call :PRINT_WARN "Operation cancelled"
    call :WAIT_KEY
    goto MENU
)
call :CONFIRM_ACTION
git cherry-pick "!commit_hash!" 2>&1
if errorlevel 1 (
    call :PRINT_ERROR "Cherry-pick failed, resolve the conflicts"
    call :LOG_ACTION "CHERRY_PICK_FAILED: !commit_hash!"
) else (
    call :PRINT_SUCCESS "Cherry-pick successful"
    call :LOG_ACTION "CHERRY_PICK_SUCCESS: !commit_hash!"
)
call :WAIT_KEY
goto MENU

:GIT_BISECT
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Bisect: !C_RESET!
    echo !C_CYAN!1!C_RESET!. Start bisect
    echo !C_CYAN!2!C_RESET!. Mark as bad
    echo !C_CYAN!3!C_RESET!. Mark as good
    echo !C_CYAN!4!C_RESET!. Reset bisect
) else (
    echo Bisect: 
    echo 1. Start bisect
    echo 2. Mark as bad
    echo 3. Mark as good
    echo 4. Reset bisect
)
set /p "bisect_choice=Select [1-4]: "
if "!bisect_choice!"=="1" (
    set "bad_commit="
    if !COLOR_ENABLED!==1 (
        set /p "bad_commit=!C_CYAN!Bad commit ID: !C_RESET!"
    ) else (
        set /p "bad_commit=Bad commit ID: "
    )
    if "!bad_commit!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    set "good_commit="
    if !COLOR_ENABLED!==1 (
        set /p "good_commit=!C_CYAN!Good commit ID: !C_RESET!"
    ) else (
        set /p "good_commit=Good commit ID: "
    )
    if "!good_commit!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    git bisect start "!bad_commit!" "!good_commit!" 2>&1
    call :PRINT_INFO "Bisect started, mark good/bad after testing"
)
if "!bisect_choice!"=="2" (
    git bisect bad 2>&1
    call :PRINT_INFO "Marked as bad"
)
if "!bisect_choice!"=="3" (
    git bisect good 2>&1
    call :PRINT_INFO "Marked as good"
)
if "!bisect_choice!"=="4" (
    git bisect reset 2>&1
    call :PRINT_SUCCESS "Bisect reset"
)
call :WAIT_KEY
goto MENU

:GIT_WORKTREE
call :CHECK_REPO
if !COLOR_ENABLED!==1 (
    echo !C_BOLD!Worktree management: !C_RESET!
    echo !C_CYAN!1!C_RESET!. View worktree list
    echo !C_CYAN!2!C_RESET!. Add worktree
    echo !C_CYAN!3!C_RESET!. Delete worktree
) else (
    echo Worktree management: 
    echo 1. View worktree list
    echo 2. Add worktree
    echo 3. Delete worktree
)
set /p "worktree_choice=Select [1-3]: "
if "!worktree_choice!"=="1" git worktree list 2>&1
if "!worktree_choice!"=="2" (
    set "worktree_path="
    if !COLOR_ENABLED!==1 (
        set /p "worktree_path=!C_CYAN!Worktree path: !C_RESET!"
    ) else (
        set /p "worktree_path=Worktree path: "
    )
    if "!worktree_path!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    set "worktree_branch="
    if !COLOR_ENABLED!==1 (
        set /p "worktree_branch=!C_CYAN!Branch name: !C_RESET!"
    ) else (
        set /p "worktree_branch=Branch name: "
    )
    if "!worktree_branch!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    git worktree add "!worktree_path!" "!worktree_branch!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Add failed"
    ) else (
        call :PRINT_SUCCESS "Worktree added"
        call :LOG_ACTION "WORKTREE_ADD: !worktree_path!"
    )
)
if "!worktree_choice!"=="3" (
    set "worktree_path="
    if !COLOR_ENABLED!==1 (
        set /p "worktree_path=!C_CYAN!Worktree path to delete: !C_RESET!"
    ) else (
        set /p "worktree_path=Worktree path to delete: "
    )
    if "!worktree_path!"=="" (
        call :PRINT_WARN "Operation cancelled"
        call :WAIT_KEY
        goto MENU
    )
    call :CONFIRM_ACTION
    git worktree remove "!worktree_path!" 2>&1
    if errorlevel 1 (
        call :PRINT_ERROR "Deletion failed"
    ) else (
        call :PRINT_SUCCESS "Worktree deleted"
        call :LOG_ACTION "WORKTREE_REMOVE: !worktree_path!"
    )
)
call :WAIT_KEY
goto MENU