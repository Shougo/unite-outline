"=============================================================================
" File    : autoload/unite/sources/outline/defaults/hatena.vim
" Author  : aereal <aereal@aereal.org>
" Updated : 2012-12-20
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Hatena annotation
" Version: 0.0.1

function! unite#sources#outline#defaults#hatena#outline_info()
  return s:outline_info
endfunction

let s:outline_info = {
      \ 'heading'  : '^\*\+',
      \ }

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': strlen(matchstr(a:heading_line, '^*\+')),
        \ 'type' : 'generic',
        \ }

  if a:which ==# 'heading'
    let heading.level = strlen(matchstr(a:heading_line, '^*\+'))
    let heading.word = substitute(heading.word, '^\*\+\s*', '', '')
    let heading.word = substitute(heading.word, '\s*\*\+\s*$', '', '')
  endif

  if heading.level > 0
    let heading.word = substitute(heading.word, '\s*<a[^>]*>\s*\%(</a>\s*\)\=$', '', '')
    return heading
  else
    return {}
  endif
endfunction
