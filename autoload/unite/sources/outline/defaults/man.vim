" ------------- - ------------------------------------------------------------
" File          : autoload/unite/sources/outline/defaults/man.vim
" Author        : Zhao Cai
" Email         : caizhaoff@gmail.com
" URL           :
" Version       : 0.1
" Date Created  : Wed 25 Jul 2012 03:28:54 PM EDT
" Last Modified : Wed 25 Jul 2012 04:11:07 PM EDT
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
" ------------- - ------------------------------------------------------------

" Default outline info for man files

function! unite#sources#outline#defaults#man#outline_info()
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading': '^[a-zA-Z][a-zA-Z ]*[a-zA-Z]$',
      \}

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let heading = {
        \ 'word' : a:heading_line,
        \ 'level': 1,
        \ 'type' : 'manSectionHeading'
        \ }

    return heading
endfunction
