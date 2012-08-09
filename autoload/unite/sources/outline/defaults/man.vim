" ------------- - ------------------------------------------------------------
" File          : autoload/unite/sources/outline/defaults/man.vim
" Author        : Zhao Cai
" Email         : caizhaoff@gmail.com
" URL           :
" Version       : 0.1
" Date Created  : Wed 25 Jul 2012 03:28:54 PM EDT
" Last Modified : Thu 09 Aug 2012 02:39:40 AM EDT
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
" ------------- - ------------------------------------------------------------


"---------------------------------------
" Sub Patterns

let s:man_section_heading           = '[a-zA-Z][a-zA-Z -_]*[a-zA-Z]'
let s:man_sub_heading_leading_space = '\s\{3\}'
let s:man_sub_heading               = s:man_sub_heading_leading_space . s:man_section_heading

"-----------------------------------------------------------------------------
" Outline Info
"
" Assume: (no syntax callback from unite-outline)
"   unite#get_current_unite().abbr_head == 3
"
let s:outline_info = {
            \ 'heading': '^\(' . s:man_section_heading . '\|' . s:man_sub_heading . '\)$',
            \
            \ 'highlight_rules': [
            \   { 'name'      : 'H1',
            \     'pattern'   : '/\%3c' . s:man_section_heading . '/',
            \     'highlight' : 'htmlH1',
            \   },
            \   { 'name'      : 'H2',
            \     'pattern'   : '/\%3c\s\+' . s:man_section_heading . '/',
            \     'highlight' : 'htmlH2'
            \   },
            \ ],
            \}


function! s:outline_info.create_heading(which, heading_line, matched_line, context)

    let heading = {
                \ 'word' : a:heading_line,
                \ 'level': 0,
                \ 'type' : 'generic',
                \ }

    if a:heading_line =~ '^' . s:man_section_heading . '$'
        let heading.level = 1
    elseif a:heading_line =~ '^' . s:man_sub_heading . '$'
        let heading.level = 2
    endif

    if heading.level > 0
        return heading
    else
        return {}
    endif
endfunction


" Default outline info for man files

function! unite#sources#outline#defaults#man#outline_info()
    return s:outline_info
endfunction

