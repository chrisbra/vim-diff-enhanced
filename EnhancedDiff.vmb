" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/EnhancedDiff.vim	[[[1
39
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
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_enhanced_diff") || &cp
    finish
elseif v:version < 704
    echohl WarningMsg
    echomsg "The EnhancedDiff Plugin needs at least a Vim version 7.4"
    echohl Normal
endif
set cpo&vim
let g:loaded_enhanced_diff = 1

" Functions {{{1
function! s:CustomDiffAlgComplete(A,L,P)
    return "myers\nminimal\ndefault\npatience\nhistogram"
endfu
" public interface {{{1
com! -nargs=1 -complete=custom,s:CustomDiffAlgComplete EnhancedDiff :let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=<args>")'|:diffupdate
com! PatienceDiff :EnhancedDiff patience
com! EnhancedDiffDisable  :set diffexpr=

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 sw=4 et fdm=marker com+=l\:\"
autoload/EnhancedDiff.vim	[[[1
167
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
        if match(diffopt, '\m\C'.i) > -1
            call add(s:diffargs, j)
        endif
    endfor

    " Add file arguments, should be last!
    call add(s:diffargs, s:ModifyPathAndCD(v:fname_in))
    call add(s:diffargs, s:ModifyPathAndCD(v:fname_new))
    " v:fname_out will be written later
endfu
function! s:Warn(msg) "{{{2
    echohl WarningMsg
    unsilent echomsg  "EnhancedDiff: ". a:msg
    echohl Normal
endfu
function! s:ModifyPathAndCD(file) "{{{2
    if has("win32") || has("win64")
	" avoid a problem with Windows and cygwins path (issue #3)
	if a:file is# '-'
	    " cd back into the previous directory
	    cd -
	    return
	endif
	let path = fnamemodify(a:file, ':p:h')
	if getcwd() isnot# path
	    exe 'sil :cd' fnameescape(path)
	endif
	return fnameescape(fnamemodify(a:file, ':p:.'))
    endif
    return fnameescape(a:file)
endfunction
function! EnhancedDiff#ConvertToNormalDiff(list) "{{{2
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
    " systemlist() was introduced with 7.4.248
    if exists("*systemlist")
	let difflist=systemlist(s:diffcmd. ' '. join(s:diffargs, ' '))
    else
	let difflist=split(system(s:diffcmd. ' '. join(s:diffargs, ' ')), "\n")
    endif
    call s:ModifyPathAndCD('-')
    if v:shell_error < 0 || v:shell_error > 1
        " An error occured
        set diffexpr=
        call s:Warn(cmd. ' Error executing "'. s:diffcmd. ' '.join(s:diffargs, ' ').'"')
        call s:Warn(difflist[0])
        return
    endif
    " if unified diff...
    " do some processing here
    if !empty(difflist) && difflist[0] !~# '\m\C^\%(\d\+\)\%(,\d\+\)\?[acd]\%(\d\+\)\%(,\d\+\)\?'
        " transform into normal diff
        let difflist=EnhancedDiff#ConvertToNormalDiff(difflist)
    endif
    call writefile(difflist, v:fname_out)
    if get(g:, 'enhanced_diff_debug', 0)
	" This is needed for the tests.
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
doc/EnhancedDiff.txt	[[[1
214
*EnhancedDiff.vim*   Enhanced Diff functions for Vim

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.3 Thu, 05 Mar 2015 08:11:46 +0100
Copyright: (©) 2015 by Christian Brabandt
           The VIM LICENSE (see |copyright|) applies to EnhancedDiffPlugin.vim
           except use EnhancedDiffPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.

============================================================================
1. Contents                                               *EnhancedDiffPlugin*
============================================================================

        1.  Contents.................................: |EnhancedDiffPlugin|
        2.  EnhancedDiff Manual......................: |EnhancedDiff-manual|
        3.  EnhancedDiff Configuration...............: |EnhancedDiff-config|
        4.  EnhancedDiff Feedback....................: |EnhancedDiff-feedback|
        5.  EnhancedDiff History.....................: |EnhancedDiff-history|

============================================================================
2. EnhancedDiffPlugin Manual                             *EnhancedDiff-manual*
============================================================================

Functionality

The EnhancedDiff plugin allows to use different diff algorithms. This can
greatly improve the use of |vimdiff| by making a diff more readable. To make
use of different diff algorithms, this plugin makes use of the git command
line tool to generate a unified diff and converts that diff to a normal "ed"
style diff (|diff-diffexpr|) to make vimdiff use that diff.

You could also use other diff tools if you like, as long as those generate a
diff in the "unified" form.

By default is disabled, which means, it uses the default diff algorithm (also
known as myers algorithm).
                                                    *EnhancedDiff-algorithms*
git supports 4 different diff algorithms. Those are:

    Algorithm       Description~
    myers           Default diff algorithm
    default         Alias for myers
    minimal         Like myers, but tries harder to minimize the resulting
                    diff
    patience        Use the patience diff algorithm
    histogram       Use the histogram diff algorithm (similar to patience but
                    slightly faster)

Note you need at least git version 1.8.2 or higher. Older versions do not
support all those algorithms.

                                                                *:EnhancedDiff*
To specify a different diff algorithm use this command: >

    :EnhancedDiff <algorithm>
<
Use any of the above algorithm for creating the diffs. You can use <Tab> to
complete the different algorithms.

                                                               *:PatienceDiff*
Use the :PatienceDiff to select the "patience" diff algorithm.

The selected diff algorithm will from then on be used for all the diffs that
will be generated in the future. If you are in diff mode (|vimdiff|) the diff
should be updated immediately.

                                                        *:EnhancedDiffDisable*
Use the :EnhancedDiffDisable command to disable this plugin.

                                                          *EnhancedDiff-vimrc*
If you want e.g. the patience diff algorithm to be the default when using the
|vimdiff| command, you need to set the 'diffexpr' option manually like this
in your |.vimrc| >

  :let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=patience")'
<
Since internally, EnhancedDiff does simply set up the 'diffexpr' option.

An alternative to this method is the following:

Create a file after/plugin/patiencediff.vim in your default runtimepath (e.g.
~/.vim/ directory on Linux, ~/vimfiles on Windows, creating missing directories,
if they do not exist yet) and put into it the following: >

  " This can't go in .vimrc, because :PatienceDiff isn't available
  if !exists(":PatienceDiff")
  " This block is optional, but will protect you from errors if you
  " uninstall vim-diff-enhanced or share your config across machines
    finish
  endif
  PatienceDiff
<

==============================================================================
3. EnhancedDiff configuration                              *EnhancedDiff-config*
==============================================================================

You can tweak the arguments for the diff generating tools using the following
variables:

g:enhanced_diff_default_git
---------------------------
Default command line arguments for git
(Default: "--no-index --no-color --no-ext-diff")

g:enhanced_diff_default_diff
----------------------------
Default command line arguments for diff
(Default: "--binary")

g:enhanced_diff_default_args
----------------------------
Default arguments for any diff command
(Default: "-U0")

g:enhanced_diff_default_<command>
---------------------------------
Default command line argument for <command> (e.g. use "hg" to specify special
arguments and you want to use hg to generate the diff)
(Default: unset)

                                                    *EnhancedDiff-custom-cmd*

Suppose you want to use a different command line tool to generate the diff.

For example, let's say you want to use mercurial to generate your diffs.
First define the g:enhanced_diff_default_hg variable and set it to
include all required arguments: >

    :let g:enhanced_diff_default_hg = '-a'

Then you define your custom command to make the next time diff mode is started
make use of mercurial: >

    :com! HgDiff :let &diffexpr='EnhancedDiff#Diff("hg diff")'

The first argument of the EnhancedDiff#Diff specifies the command to use to
generate the diff. The optional second argument specifies an optional
parameter that will be used in addition to the g:enhanced_diff_default_hg
variable. In addition to the arguments from the g:enhanced_diff_default_hg
variable, also the arguments from the g:enhanced_diff_default_args will be
used (e.g. by default the -U0 to prevent generating context lines).

Note: You need to make sure to generate either a normal style diff or a
unified style diff. A unified diff will be converted to a normal style diff so
that Vim can make use of that diff for its diff mode.

                                                    *EnhancedDiff-convert-diffs*
The EnhancedDiff plugin defines a public function
(EnhancedDiff#ConvertToNormalDiff(arg) that can be used by any plugin to
convert a diff in unified form to a diff that can be read by Vim.

arg is a |List| containing the diff as returned by git diff. Use it
like this: >

    let mydiff   = systemlist('git diff ...')
    let difflist = EnhancedDiff#ConvertToNormalDiff(mydiff)
<
If your Vim doesn't have the systemlist() function, you can manully split the
list like this: >

    let mydiff   = split(system('git diff ...'), "\n")
    let difflist = EnhancedDiff#ConvertToNormalDiff(mydiff)

Note: If you want to use the converted diff and feed it back to Vim for its
diff mode, you need to write the list back to the file |v:fname_out|
============================================================================
4. Plugin Feedback                                    *EnhancedDiff-feedback*
============================================================================

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=5121

You can also follow the development of the plugin at github:
http://github.com/chrisbra/EnhancedDiff.vim

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

============================================================================
5. EnhancedDiff History                                 *EnhancedDiff-history*
============================================================================

0.4 (unreleased) "{{{1
- documentation update
- if |systemlist()| is not available, use |system()| function (issue
  https://github.com/chrisbra/vim-diff-enhanced/issues/2 reported by agude,
  thanks!)
- cd into temporary directory before doing the diff (issue 
  https://github.com/chrisbra/vim-diff-enhanced/issues/3 reported by idbrii,
  thanks!)
- rename public commands to :EnhancedDiff prefix (issue
  https://github.com/chrisbra/vim-diff-enhanced/isseus/4 reported by justinmk,
  thanks!)

0.3: Mar 5th, 2014 "{{{1
- update diff, when in diffmode and |:CustomDiff| is used
- run test correctly, when installed via plugin manager (issue
  https://github.com/chrisbra/vim-diff-enhanced/issues/1, reported by
  advocateddrummer thanks!)
- fix small typo (noticed by Gary Johnson, thanks!)

0.2: Feb 25, 2015 "{{{1

- Updated documentation to link to the vim.org page

0.1: Feb 25, 2015 "{{{1

- Internal version

==============================================================================
Modeline: "{{{1
vim:tw=78:ts=8:ft=help:et:fdm=marker:fdl=0:norl
