"=============================================================================
" File    : autoload/unite/sources/outline/defaults/ruby.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
"
" Licensed under the MIT license:
" http://www.opensource.org/licenses/mit-license.php
"
"=============================================================================

" Default outline info for Ruby
" Version: 0.1.5

function! unite#sources#outline#defaults#ruby#outline_info(...)
  if a:0
    " Redirect to DSL's outline info.
    let context = a:1
    let path = context.buffer.path
    if path =~ '_spec\.rb$'
      " RSpec
      return 'ruby/rspec'
    endif
  endif
  return s:outline_info
endfunction

let s:Util = unite#sources#outline#import('Util')

"-----------------------------------------------------------------------------
" Outline Info

let s:outline_info = {
      \ 'heading-1': s:Util.shared_pattern('sh', 'heading-1'),
      \ 'heading_keywords': [
      \   'module', 'class', 'protected', 'private',
      \   'def', '[mc]\=attr_\(accessor\|reader\|writer\)', 'alias',
      \   'BEGIN', 'END', '__END__',
      \   ],
      \
      \ 'skip': {
      \   'header': s:Util.shared_pattern('sh', 'header'),
      \   'block' : ['^=begin', '^=end'],
      \ },
      \
      \ 'heading_groups': {
      \   'type'  : ['module', 'class'],
      \   'method': ['method'],
      \ },
      \
      \ 'not_match_patterns': [
      \   s:Util.shared_pattern('*', 'parameter_list'),
      \ ],
      \
      \ 'highlight_rules': [
      \   { 'name'     : 'comment',
      \     'pattern'  : '/#.*/' },
      \   { 'name'     : 'method',
      \     'pattern'  : '/:\@<! \zs\%(=>\)\@![_[:alnum:]=\[\]<>!?.]\+/' },
      \   { 'name'     : 'type',
      \     'pattern'  : '/\S\+\ze : \%(module\|class\)/' },
      \   { 'name'     : 'eigen_class',
      \     'pattern'  : '/\<class\s\+<<\s\+.*/',
      \     'highlight': unite#sources#outline#get_highlight('special') },
      \   { 'name'     : 'access',
      \     'pattern'  : '/\<\%(protected\|private\)\>/',
      \     'highlight': unite#sources#outline#get_highlight('special') },
      \   { 'name'     : 'meta_method',
      \     'pattern'  : '/\<def\s\+[^(]*/',
      \     'highlight': unite#sources#outline#get_highlight('special') },
      \   { 'name'     : 'parameter_list',
      \     'pattern'  : '/(.*)/' },
      \ ],
      \}

function! s:outline_info.initialize()
  let self.heading = '^\s*\(' . join(self.heading_keywords, '\|') . '\)\>'
endfunction

function! s:outline_info.create_heading(which, heading_line, matched_line, context)
  let word = a:heading_line
  let type = 'generic'
  let level = 0

  if a:which == 'heading-1' && a:heading_line =~ '^\s*#'
    let m_lnum = a:context.matched_lnum
    let type = 'comment'
    let level = s:Util.get_comment_heading_level(a:context, m_lnum)

  elseif a:which == 'heading'
    let h_lnum = a:context.heading_lnum
    let level = s:Util.get_indent_level(a:context, h_lnum) + 3
    " NOTE: Level 1 to 3 are reserved for toplevel comment headings.

    let matches = matchlist(a:heading_line, self.heading)
    let keyword = matches[1]
    let type = keyword

    if keyword == 'module' || keyword == 'class'
      if word =~ '\s\+<<\s\+'
        " Eigen-class
      else
        " Module, Class
        let word = substitute(matchstr(word, '^\s*\%(module\|class\)\s\+\zs\h\%(\w\|\s*::\s*\)*'),'\s*','','g') . ' : ' . keyword
      endif
    elseif keyword == 'protected' || keyword == 'private'
      " Accessibility
      let indented = 0
      for idx in range(1, 5)
        let line = get(a:context.lines, h_lnum + idx, '')
        if line =~ '\S'
          let indented = level < s:Util.get_indent_level(a:context, h_lnum + idx) + 3
          break
        endif
      endfor
      if !indented
        let level = 0
      endif
    elseif keyword == 'def'
      if word =~ '#{'
        " Meta-method
      else
        " Method
        let type = 'method'
        let word = substitute(word, '\<def\s*', '', '')
      endif
      let word = substitute(word, '\S\zs(', ' (', '')
    elseif keyword =~ '^[mc]\=attr_'
      " Accessor
      let type = 'method'
      let access = matches[2]
      let word = substitute(word, '\<[mc]\=attr_\w\+\s*', '', '')
      let word = substitute(word, ',\s*\S\+\s*=>.*', '', '')
      let word = substitute(word, '\s*:', ' ', 'g') . ' : ' . access
    elseif keyword == 'alias'
      " Alias
      let type = 'method'
      let word = substitute(word, '\<alias\s*', '', '')
      let word = substitute(word, ':\=\(\S\+\)\s\+:\=\(\S\+\)', '\1 => \2', '')
    elseif keyword =~ '^\%(BEGIN\|END\)$'
      " BEGIN, END
      let word = substitute(word, '\s*{.*$', '', '')
    else
      " __END__
    endif
    let word = substitute(word, '\%(;\|#{\@!\).*$', '', '')
  endif

  if level > 0
    let heading = {
          \ 'word' : word,
          \ 'level': level,
          \ 'type' : type,
          \ }
  else
    let heading = {}
  endif
  return heading
endfunction

function! s:outline_info.fold_ruby_block(context, lnum)
  let line = a:context.lines[a:lnum]
  let indent = matchlist(line, '^\(\s*\)')[1]
  let line = s:Util.join_to(a:context, a:lnum, indent . '%\(end\>\|}\)')
  let line = substitute(line, '\s*\n\s*', '; ', 'g')
  let line = substitute(substitute(line, 'do;', '{', ''), '; end', ' }', '')
  return line
endfunction

function! s:outline_info.need_blank_between(cand1, cand2, memo)
  if a:cand1.source__heading_group == 'method' && a:cand2.source__heading_group == 'method'
    " Don't insert a blank between two sibling methods.
    return 0
  else
    return (a:cand1.source__heading_group != a:cand2.source__heading_group ||
          \ a:cand1.source__has_marked_child || a:cand2.source__has_marked_child)
  endif
endfunction
