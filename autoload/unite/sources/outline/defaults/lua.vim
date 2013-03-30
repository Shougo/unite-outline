"=============================================================================
" File    : autoload/unite/sources/outline/defaults/lua.vim
" Author  : meryngii <meryngii+git@gmail.com>
" Updated : 2013-03-31
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

function! unite#sources#outline#defaults#lua#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading'  : '^\s*\%(local\s\+\)\=function\s\+\h',
      \ 'skip'     : {
      \   'block' : ['--\[\[', '--\]\]'],
      \ },
      \ 'highlight_rules': [
      \     { 'name'     : 'comment',
      \       'pattern'  : '/--.*/' },
      \     { 'name'     : 'function',
      \       'pattern'  : '/\h\w*/' },
      \     { 'name'     : '_after_colon',
      \       'pattern'  : '/ : \h\w*/',
      \       'highlight': unite#sources#outline#get_highlight('normal') },
      \ ]
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
    let h_lnum = a:context.heading_lnum
    let level = s:Util.get_indent_level(a:context, h_lnum)

    let heading = {
        \ 'word' : a:heading_line,
        \ 'level': level,
        \ 'type' : 'generic',
        \ }

    let suffix = ''
    if heading.word =~ '\<local\>'
        let suffix = ' : local'
    end

    let heading.word = substitute(heading.word, '^\s*\%(local\s\+\)\=function\s\+', '', '') . suffix

    return heading
endfunction

