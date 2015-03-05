" EnhancedDiff.vim - Enhanced Diff functions for Vim
" -------------------------------------------------------------
" Version: 0.3
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 05 Mar 2015 08:11:46 +0100
" Script: http://www.vim.org/scripts/script.php?script_id=5121
" Copyright:   (c) 2009-2015 by Christian Brabandt
"          The VIM LICENSE applies to EnhancedDifff.vim
"          (see |copyright|) except use "EnhancedDiff.vim"
"          instead of "Vim".
"          No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 5121 3 :AutoInstall: EnhancedDiff.vim
function! s:DiffInit(...) "{{{2
    let s:diffcmd=exists("a:1") ? a:1 : 'diff'
    let s:diffargs=[]
    let diffopt=split(&diffopt, ',')
    let special_args = {'icase': '-i', 'iwhite': '-b'}
    let git_default = get(g:, 'enhanced_diff_default_git',
        \ '--no-index --no-color --no-ext-diff')
    let diff_default = get(g:, 'enhanced_diff_default_diff', '--binary')
    let default_args = (exists("a:2") ? a:2 : ''). ' '.
        \ get(g:, 'enhanced_diff_default_args', '-U0') 

    if !executable(split(s:diffcmd)[0])
        throw "no executable"
    "else
        " Try to use git diff command, allows for more customizations
        "if split(s:diffcmd)[0] is# 'git' && !exists("s:git_version")
        "    let s:git_version = substitute(split(system('git --version'))[-1], '\.', '', 'g') + 0
        "endif
    endif
    let s:diffargs += split(default_args)
    if exists("{s:diffcmd}_default")
        let s:diffargs += split({s:diffcmd}_default)
    endif

    for [i,j] in items(special_args)
        if match(diffopt, i) > -1
            call add(s:diffargs, j)
        endif
    endfor

    " Add file arguments, should be last!
    call add(s:diffargs, v:fname_in)
    call add(s:diffargs, v:fname_new)
    " v:fname_out will be written later
endfu
function! s:Warn(msg) "{{{2
    echohl WarningMsg
    unsilent echomsg  "EnhancedDiff: ". a:msg
    echohl Normal
endfu
function! s:ConvertToNormalDiff(list) "{{{2
    " Convert unified diff into normal diff
    let result=[]
    let start=1
    let hunk_start = '^@@ -\(\d\+\)\%(,\(\d\+\)\)\? +\(\d\+\)\%(,\(\d\+\)\)\? @@.*$'
    let last = ''
    for line in a:list
        if start && line !~# '^@@'
            continue
        else
            let start=0
        endif
        if line =~? '^+'
            if last is# 'old'
                call add(result, '---')
                let last='new'
            endif
            call add(result, substitute(line, '^+', '> ', ''))
        elseif line =~? '^-'
            let last='old'
            call add(result, substitute(line, '^-', '< ', ''))
	elseif line =~? '^ ' " skip context lines
	    continue
        elseif line =~? hunk_start
            let list = matchlist(line, hunk_start)
            let old_start = list[1] + 0
            let old_len   = list[2] + 0
            let new_start = list[3] + 0
            let new_len   = list[4] + 0
            let action    = 'c'
            let before_end= ''
            let after_end = ''
            let last = ''

            if list[2] is# '0'
                let action = 'a'
            elseif list[4] is# '0'
                let action = 'd'
            endif

            if (old_len)
                let before_end = printf(',%s', old_start + old_len - 1)
            endif
            if (new_len)
                let after_end  = printf(',%s', new_start + new_len - 1)
            endif
            call add(result, old_start.before_end.action.new_start.after_end)
        endif
    endfor
    return result
endfunction
function! EnhancedDiff#Diff(...) "{{{2
    let cmd=(exists("a:1") ? a:1 : '')
    let arg=(exists("a:2") ? a:2 : '')
    try
        call s:DiffInit(cmd, arg)
    catch
        " no-op
        " error occured, reset diffexpr
        set diffexpr=
        call s:Warn(cmd. ' not found in path, aborting!')
        return
    endtry
    let difflist=systemlist(s:diffcmd. ' '. join(s:diffargs, ' '))
    if v:shell_error < 0 || v:shell_error > 1
        " An error occured
        set diffexpr=
        call s:Warn(cmd. ' Error executing "'. s:diffcmd. ' '.join(s:diffargs, ' ').'"')
        call s:Warn(difflist[0])
        return
    endif
    " if unified diff...
    " do some processing here
    if !empty(difflist) && difflist[0] !~# '^\%(\d\+\)\%(,\d\+\)\?[acd]\%(\d\+\)\%(,\d\+\)\?'
        " transform into normal diff
        let difflist=s:ConvertToNormalDiff(difflist)
    endif
    call writefile(difflist, v:fname_out)
    if get(g:, 'enhanced_diff_debug', 0)
        call writefile(difflist, 'EnhancedDiff_normal.txt')
        " Also write default diff
        let opt = "-a --binary "
        if &diffopt =~ "icase"
            let opt .= "-i "
        endif
        if &diffopt =~ "iwhite"
            let opt .=  "-b "
        endif
        silent execute "!diff " . opt . v:fname_in . " " . v:fname_new .  " > EnhancedDiff_default.txt"
    endif
endfunction
