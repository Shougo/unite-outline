"=============================================================================
" File: autoload/unite/sources/outline/defaults/haskell.vim
" Author: igrep <whosekiteneverfly@gmail.com>
" Updated: 2013-01-03
" Version: 0.1.1
" TODO:
"     - support hspec, lhs, haddock, etc.
"     - how to handle comments?
" Referred To:
"     - http://www.cs.utep.edu/cheon/cs3360/pages/haskell-syntax.html
"     - http://www.sampou.org/haskell/report-revised-j/syntax-iso.html
"     - http://www.haskell.org/haskellwiki/Keywords
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

let s:declaration = '\%(module\|data\|type\|newtype\|class\|instance\)'
"                    starts with lowercase or an parenthesis
let s:signature = '\%([a-z(].*::\)'

let s:heading = '^\%(' . s:declaration . '\|' . s:signature .'\)'

" Don't need to skip line comment.
" Because the header starts with '^'
let s:skip = { 'block': ['{-', '-}'] }

let s:outline_info = {
      \ 'heading': s:heading,
      \ 'skip': s:skip
      \ }

function! unite#sources#outline#defaults#haskell#outline_info()
  return s:outline_info
endfunction
