"=============================================================================
" File    : autoload/unite/sources/outline/defaults/perl.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Perl
" Version: 0.1.0

function! unite#sources#outline#defaults#perl#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('sh', 'heading-1'),
      \ 'heading'  : '^\%(\s*\%(sub\s\+\h\|subtest\s\+["'']\?\h\|\%(package\|BEGIN\|CHECK\|INIT\|END\)\>\)\|__\%(DATA\|END\)__$\)',
      \
      \ 'skip': {
      \   'header': s:Util.shared_pattern('sh', 'header'),
      \   'block' : ['^=\%(cut\)\@!\w\+', '^=cut'],
      \ },
      \
      \ 'highlight_rules': [
      \   { 'name'     : 'comment',
      \     'pattern'  : '/#.*/' },
      \   { 'name'     : 'sub',
      \     'pattern'  : '/\h\w*/',
      \     'highlight': unite#sources#outline#get_highlight('function') },
      \   { 'name'     : 'subtest',
      \     'pattern'  : '/\h\w*/',
      \     'highlight': unite#sources#outline#get_highlight('normal') },
      \   { 'name'     : 'block',
      \     'pattern'  : '/\<\%(BEGIN\|CHECK\|INIT\|END\|__\%(DATA\|END\)__\)\>/',
      \     'highlight': unite#sources#outline#get_highlight('special') },
      \   { 'name'     : 'package',
      \     'pattern'  : '/\S\+\ze : package/',
      \     'highlight': unite#sources#outline#get_highlight('type') },
      \   { 'name'     : '_after_colon',
      \     'pattern'  : '/ : \h\w*/',
      \     'highlight': unite#sources#outline#get_highlight('normal') },
      \ ],
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let h_lnum = a:context.heading_lnum
  " Level 1 to 3 are reserved for comment headings.
  let level = s:Util.get_indent_level(a:context, h_lnum) + 3
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let m_lnum = a:context.matched_lnum
    let heading.type = 'comment'
    let heading.level = s:Util.get_comment_heading_level(a:context, m_lnum)
  elseif a:which == 'heading'
    if a:heading_line =~ '^\s*package\>'
      let heading.word = substitute(heading.word, ';\s*$', '', '')
      let heading.word = substitute(heading.word, '^\s*\zspackage\s\+', '', '') . ' : package'
    else
      let heading.word = substitute(heading.word, '\<subtest\>\s*q\?[''"]\(.*\)[''"]\s.*$', '\1 : subtest', '')
      let heading.word = substitute(heading.word, '\<sub\>', '', '')
      let heading.word = substitute(heading.word, '\s*{.*$', '', '')
      let heading.level += 1
    endif
  endif
  return heading
endfunction
