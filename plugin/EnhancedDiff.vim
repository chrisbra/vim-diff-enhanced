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
com! -nargs=1 -complete=custom,s:CustomDiffAlgComplete CustomDiff :let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=<args>")'|:diffupdate
com! PatienceDiff :CustomDiff patience
com! -nargs=? DisableEnhancedDiff  :set diffexpr=

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 sw=4 et fdm=marker com+=l\:\"
