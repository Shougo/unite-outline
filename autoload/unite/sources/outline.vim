"=============================================================================
" File    : autoload/unite/source/outline.vim
" Author  : h1mesuke <himesuke@gmail.com>
" Updated : 2012-01-11
" Version : 0.5.1
" License : MIT license {{{
"
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
"   
"   The above copyright notice and this permission notice shall be included
"   in all copies or substantial portions of the Software.
"   
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

"-----------------------------------------------------------------------------
" Constants

let s:OUTLINE_INFO_PATH = [
      \ 'autoload/outline/',
      \ 'autoload/unite/sources/outline/',
      \ 'autoload/unite/sources/outline/defaults/',
      \ ]

" NOTE: source <- [aliases...]
let s:OUTLINE_ALIASES = {
      \ 'markdown': ['mkd'],
      \ 'cpp'     : ['c'],
      \ 'dosini'  : ['cfg'],
      \ 'tex'     : ['plaintex'],
      \ 'conf'    : ['snippet'],
      \ 'html'    : ['eruby', 'xhtml'],
      \ 'sh'      : ['zsh'],
      \ }

let s:OUTLINE_CACHE_DIR = g:unite_data_directory . '/outline'

" Rename the cache directory if its name is still old, dotted style name.
" See http://d.hatena.ne.jp/tyru/20110824/unite_file_mru
"
let old_cache_dir = g:unite_data_directory . '/.outline'
if isdirectory(s:OUTLINE_CACHE_DIR)
  if isdirectory(old_cache_dir) 
    call unite#print_message("[unite-outline] Warning: Please remove the old cache directory: ")
    call unite#print_message("[unite-outline] " . old_cache_dir)
  endif
else " if !isdirectory(s:OUTLINE_CACHE_DIR)
  if isdirectory(old_cache_dir)
    if rename(old_cache_dir, s:OUTLINE_CACHE_DIR) != 0
      let s:OUTLINE_CACHE_DIR = old_cache_dir
      call unite#util#print_error("unite-outline: Couldn't rename the cache directory.")
    endif
  endif
endif
unlet old_cache_dir

let s:FILECACHE_FORMAT_VERSION = 2
let s:FILECACHE_FORMAT_VERSION_KEY = '__unite_outline_filecache_format_version__'

let s:BUFVAR_OUTLINE_DATA = 'unite_source_outline_data'
let s:WINVAR_OUTLINE_BUFFER_IDS = 'unite_source_outline_buffer_ids'

"-----------------------------------------------------------------------------
" Functions

function! unite#sources#outline#define()
  return s:source
endfunction

" Defines an alias of filetype {ftype}.
"
function! unite#sources#outline#alias(alias, ftype)
  if type(a:alias) == type([])
    call s:define_filetype_aliases(a:alias, a:ftype)
  elseif type(a:alias) == type('')
    call s:define_filetype_aliases([a:alias], a:ftype)
  else
    call unite#print_error("unite-outline: Unsupported alias type: " . string(a:alias))
  endif
endfunction

let s:ftype_alias_table = {}

function! s:define_filetype_aliases(aliases, ftype)
  for alias in a:aliases
    let s:ftype_alias_table[alias] = a:ftype
  endfor
endfunction

" Accessor functions for the outline data, that is a Dictionary assigned to
" the buffer local variable.
 
function! unite#sources#outline#has_outline_data(...)
  return call('s:has_outline_data', a:000)
endfunction
function! s:has_outline_data(bufnr, ...)
  if a:0
    let key = a:1
    let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
    return has_key(data, key)
  else
    let bufvars = getbufvar(a:bufnr, '')
    return has_key(bufvars, s:BUFVAR_OUTLINE_DATA)
  endif
endfunction

" Returns the value of outline data {key} for buffer {bufnr}. If the value
" isn't available, returns {default}. When {key} is omitted, returns an
" outline data's Dictionary.
"
function! unite#sources#outline#get_outline_data(...)
  return call('s:get_outline_data', a:000)
endfunction
function! s:get_outline_data(bufnr, ...)
  let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
  let argc = len(a:000)
  if argc == 0
    return data
  elseif argc == 1
    return data[a:1]
  else
    return get(data, a:1, a:2)
  endif
endfunction

" Sets the value of outline data {key} for buffer {bufnr} to {value}.
"
function! unite#sources#outline#set_outline_data(...)
  call call('s:set_outline_data', a:000)
endfunction
function! s:set_outline_data(bufnr, key, value)
  let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
  let data[a:key] = a:value
endfunction

" Removes the value of outline data {key} for buffer {bufnr}.
"
function! unite#sources#outline#remove_outline_data(...)
  call call('s:remove_outline_data', a:000)
endfunction
function! s:remove_outline_data(bufnr, key)
  let data = getbufvar(a:bufnr, s:BUFVAR_OUTLINE_DATA)
  unlet data[a:key]
endfunction

function! s:has_outline_buffer_ids(winnr)
  let winvars  = getwinvar(a:winnr, '')
  return has_key(winvars, s:WINVAR_OUTLINE_BUFFER_IDS)
endfunction

function! s:get_outline_buffer_ids(winnr)
  let winvars  = getwinvar(a:winnr, '')
  return winvars[s:WINVAR_OUTLINE_BUFFER_IDS]
endfunction

" Returns the outline info for filetype {ftype}. If not found, returns an
" empty Dictionary. When {ftype} is a Dictionary, assumes it is a Context and
" takes the context buffer's filetype.
"
function! unite#sources#outline#get_outline_info(...)
  return call('s:get_outline_info', a:000)
endfunction
function! s:get_outline_info(ftype, ...)
  if type(a:ftype) == type({})
    let ftype = join(a:ftype.buffer.filetypes, '.')
    let context = a:ftype
  else
    let ftype = a:ftype
    let context = {}
  endif
  let reload = get(a:000, 0, 0)
  let nouser = get(a:000, 1, 0)
  let oinfo_paths = (nouser ? s:OUTLINE_INFO_PATH[-1:] : s:OUTLINE_INFO_PATH)

  for ftype in s:resolve_filetype(ftype)
    if has_key(g:unite_source_outline_info, ftype)
      let name = ftype
      let oinfo = g:unite_source_outline_info[ftype]
      call s:initialize_outline_info(oinfo, ftype)
      return oinfo
    endif
    let load_func = s:find_loadable_func(ftype, oinfo_paths)
    if !empty(load_func)
      let name = load_func
      let oinfo = s:load_outline_info(load_func, context, reload)
      if type(oinfo) == type("")
        " Redirect.
        let redir_ftype = oinfo | unlet oinfo
        let oinfo = s:get_outline_info(redir_ftype, reload, nouser)
      else
        call s:initialize_outline_info(oinfo, load_func)
      endif
      return oinfo
    endif
  endfor
  return {}
endfunction

function! s:find_loadable_func(ftype, paths)
  let ftype = substitute(a:ftype, '\.', '_', 'g')
  for path in a:paths
    let path = substitute(path, '^autoload/', '', '') . ftype
    let load_func = substitute(path . '#outline_info', '/', '#', 'g')
    try
      " NOTE: This is a workaround for that exists('*auto#load#func') always
      " returns 0 when used in a function other than the toplevel.
      call call(load_func, [])
      return load_func
    catch /^Vim\%((\a\+)\)\=:E117:/
      " E117: Unknown function:
    catch
    endtry
  endfor
  return ''
endfunction

" Reloads an autoload script where autoload function {funcname} is defined.
"
function! s:reload_autoload_script(funcname)
  " path#to#file#func() -> autoload/path/to/file.vim -> full path
  let path = 'autoload/' . join(split(a:funcname, '#')[:-2], '/') . '.vim'
  let path = get(split(globpath(&runtimepath, path), "\<NL>"), 0, '')
  let path = fnamemodify(path, ':p')
  " Re-source the autoload script.
  source `=path`
endfunction

function! s:load_outline_info(load_func, context, reload)
  if a:reload
    call s:reload_autoload_script(a:load_func)
  endif
  if !empty(a:context)
    try
      let oinfo = call(a:load_func, [a:context])
    catch /^Vim\%((\a\+)\)\=:E118:/
      " E118: Too many arguments for function:
      let oinfo = call(a:load_func, [])
    endtry
  else
    let oinfo = call(a:load_func, [])
  endif
  return oinfo
endfunction

function! s:initialize_outline_info(oinfo, name)
  if has_key(a:oinfo, 'super')
    if a:oinfo.__initialized__ > a:oinfo.super.__initialized__
      return
    endif
  elseif has_key(a:oinfo, '__initialized__')
    return
  endif

  if has_key(a:oinfo, 'initialize')
    call a:oinfo.initialize()
  endif
  call extend(a:oinfo, { 'name': a:name, 'is_volatile': 0 }, 'keep' )
  if has_key(a:oinfo, 'skip')
    call s:normalize_skip_info(a:oinfo)
  endif
  call s:normalize_heading_groups(a:oinfo)
  if has_key(a:oinfo, 'not_match_patterns')
    let a:oinfo.__not_match_pattern__ =
          \ '\%(' . join(a:oinfo.not_match_patterns, '\|') . '\)'
  endif

  if has_key(a:oinfo, 'super')
    let a:oinfo.__initialized__ = a:oinfo.super.__initialized__ + 1
  else
    let a:oinfo.__initialized__ = 1
  endif
endfunction

function! s:normalize_skip_info(oinfo)
  if has_key(a:oinfo.skip, 'header')
    let value_type = type(a:oinfo.skip.header)
    if value_type == type("")
      let a:oinfo.skip.header = { 'leading': a:oinfo.skip.header }
    elseif value_type == type([])
      let a:oinfo.skip.header =
            \ { 'block': s:normalize_block_patterns(a:oinfo.skip.header) }
    elseif value_type == type({})
      if has_key(a:oinfo.skip.header, 'block') &&
            \ type(a:oinfo.skip.header.block) == type([])
        let a:oinfo.skip.header.block =
              \ s:normalize_block_patterns(a:oinfo.skip.header.block)
      endif
    endif
  endif
  if has_key(a:oinfo.skip, 'block')
    let value_type = type(a:oinfo.skip.block)
    if value_type == type([])
      let a:oinfo.skip.block = s:normalize_block_patterns(a:oinfo.skip.block)
    endif
  endif
endfunction

function! s:normalize_block_patterns(patterns)
  return { 'begin': a:patterns[0], 'end': a:patterns[1] }
endfunction

function! s:normalize_heading_groups(oinfo)
  if !has_key(a:oinfo, 'heading_groups')
    let a:oinfo.heading_groups = {}
    let group_map = {}
  else
    let groups = keys(a:oinfo.heading_groups)
    let group_map = {}
    for group in groups
      let group_types = a:oinfo.heading_groups[group]
      for heading_type in group_types
        let group_map[heading_type] = group
      endfor
    endfor
  endif
  let group_map.generic = 'generic'
  let a:oinfo.heading_group_map = group_map
endfunction

" Returns the value of filetype option {key} for filetype {ftype}.
" If the value isn't available, returns {default}.
"
function! unite#sources#outline#get_filetype_option(...)
  return call('s:get_filetype_option', a:000)
endfunction
function! s:get_filetype_option(ftype, key, ...)
  for ftype in s:resolve_filetype(a:ftype)
    if has_key(g:unite_source_outline_filetype_options, ftype)
      let options = g:unite_source_outline_filetype_options[ftype]
      if has_key(options, a:key)
        return options[a:key]
      endif
    endif
  endfor
  let default = (a:0 ? a:1 : 0)
  return get(s:default_filetype_options, a:key, default)
endfunction

" Returns a List of filetypes that are filetype {ftype} itself and its
" fallback filetypes and aliases of each of them.
"
"   the given filetype {ftype}
"     |/
"   (1)aaa.bbb.ccc -> (2)aliases
"   (3)aaa/bbb/ccc -> (4)aliases
"     |/
"   (5)aaa.bbb     -> (6)aliases
"   (7)aaa/bbb     -> (8)aliases
"     |/
"   (9)aaa         -> ($)aliases
"
function! s:resolve_filetype(ftype)
  let ftcands = []
  let ftype = a:ftype
  while 1
    call add(ftcands, ftype)
    let ftcands += s:resolve_filetype_alias(ftype)
    if ftype =~ '\.'
      let dsl_ftype = substitute(ftype, '\.', '/', 'g')
      call add(ftcands, dsl_ftype)
      let ftcands += s:resolve_filetype_alias(dsl_ftype)
    endif
    if ftype =~ '[./]\w\+$'
      let ftype = substitute(ftype, '[./]\w\+$', '', '')
    else
      break
    endif
  endwhile
  call add(ftcands, '*')
  return ftcands
endfunction

function! s:resolve_filetype_alias(ftype)
  let seen = {}
  let ftcands = []
  let ftype = a:ftype
  while 1
    if has_key(s:ftype_alias_table, ftype)
      if has_key(seen, ftype)
        throw "unite-outline: Cyclic alias definition detected."
      endif
      let ftype = s:ftype_alias_table[ftype]
      call add(ftcands, ftype)
      let seen[ftype] = 1
    else
      break
    endif
  endwhile
  return ftcands
endfunction

function! unite#sources#outline#get_highlight(...)
  return call('s:get_highlight', a:000)
endfunction
function! s:get_highlight(...)
  for name in a:000
    if has_key(g:unite_source_outline_highlight, name)
      return g:unite_source_outline_highlight[name]
    elseif has_key(s:default_highlight, name)
      return s:default_highlight[name]
    endif
  endfor
  return s:default_highlight.normal
endfunction

function! unite#sources#outline#import(name, ...)
  let name = tolower(substitute(a:name, '\(\l\)\(\u\)', '\1_\2', 'g'))
  return call('unite#sources#outline#modules#' . name . '#import', a:000)
endfunction

function! unite#sources#outline#remove_cache_files()
  call s:FileCache.clear()
endfunction

"-----------------------------------------------------------------------------
" Key-mappings

" DEPRECATED:
nmap <Plug>(unite_source_outline_loop_cursor_down) <Plug>(unite_skip_cursor_down)
nmap <Plug>(unite_source_outline_loop_cursor_up) <Plug>(unite_skip_cursor_up)

"-----------------------------------------------------------------------------
" Variables

if !exists('g:unite_source_outline_info')
  let g:unite_source_outline_info = {}
endif

if !exists('g:unite_source_outline_indent_width')
  let g:unite_source_outline_indent_width = 2
endif

if !exists('g:unite_source_outline_max_headings')
  let g:unite_source_outline_max_headings = 1000
endif

if !exists('g:unite_source_outline_cache_limit')
  let g:unite_source_outline_cache_limit = 1000
endif

let s:default_filetype_options = {
      \ 'auto_update'      : 1,
      \ 'auto_update_event': 'write',
      \ 'ignore_types'     : [],
      \ }
if !exists('g:unite_source_outline_filetype_options')
  let g:unite_source_outline_filetype_options = {}
endif

let s:default_highlight = {
      \ 'comment' : 'Comment',
      \ 'expanded': 'Constant',
      \ 'function': 'Function',
      \ 'id'      : 'Special',
      \ 'macro'   : 'Macro',
      \ 'method'  : 'Function',
      \ 'normal'  : g:unite_abbr_highlight,
      \ 'package' : g:unite_abbr_highlight,
      \ 'special' : 'Macro',
      \ 'type'    : 'Type',
      \ 'level_1' : 'Type',
      \ 'level_2' : 'PreProc',
      \ 'level_3' : 'Identifier',
      \ 'level_4' : 'Constant',
      \ 'level_5' : 'Special',
      \ 'level_6' : g:unite_abbr_highlight,
      \ 'parameter_list': g:unite_abbr_highlight,
      \ }
if !exists('g:unite_source_outline_highlight')
  let g:unite_source_outline_highlight = {}
endif

if !exists('g:unite_source_outline_verbose')
  let g:unite_source_outline_verbose = 0
endif

"---------------------------------------
" Aliases

" Define the default filetype aliases.
for [ftype, aliases] in items(s:OUTLINE_ALIASES)
  call call('s:define_filetype_aliases', [aliases, ftype])
endfor

"-----------------------------------------------------------------------------
" Source

let s:FileCache = unite#sources#outline#import('FileCache', s:OUTLINE_CACHE_DIR)
let s:Tree = unite#sources#outline#import('Tree')
let s:Util = unite#sources#outline#import('Util')

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID

let s:outline_buffer_id = 1
let s:source = {
      \ 'name'       : 'outline',
      \ 'description': 'candidates from heading list',
      \ 'filters'    : ['outline_matcher_glob', 'outline_formatter'],
      \ 'syntax'     : 'uniteSource__Outline',
      \
      \ 'hooks': {}, 'action_table': {}, 'alias_table': {}, 'default_action': {},
      \ }

function! s:Source_Hooks_on_init(source_args, unite_context)
  let a:unite_context.source__outline_buffer_id = s:outline_buffer_id
  let a:unite_context.source__outline_source_bufnr = bufnr('%')
  call s:initialize_outline_data()
  call s:attach_outline_buffer(s:outline_buffer_id)
  let s:outline_buffer_id += 1
endfunction
let s:source.hooks.on_init = function(s:SID . 'Source_Hooks_on_init')

" Initialize the current buffer's outline data and register autocommands to
" manage the data if the buffer hasn't been initialized yet.
"
function! s:initialize_outline_data()
  let bufnr = bufnr('%')
  let bufvars  = getbufvar(bufnr, '')
  if !has_key(bufvars, s:BUFVAR_OUTLINE_DATA)
    let bufvars[s:BUFVAR_OUTLINE_DATA] = { 'state': 'OK' }
    call s:register_autocmds()
  endif
  call s:update_buffer_changenr()
endfunction

" Associate the current buffer's window with the outline buffer {buffer_id}
" where the headings from the buffer will be displayed.
"
function! s:attach_outline_buffer(buffer_id)
  let winnr = winnr()
  let winvars  = getwinvar(winnr, '')
  if !has_key(winvars, s:WINVAR_OUTLINE_BUFFER_IDS)
    let winvars[s:WINVAR_OUTLINE_BUFFER_IDS] = []
  endif
  call add(winvars[s:WINVAR_OUTLINE_BUFFER_IDS], a:buffer_id)
endfunction

function! s:Source_Hooks_on_syntax(source_args, unite_context)
  let bufnr = a:unite_context.source__outline_source_bufnr
  let odata = s:get_outline_data(bufnr)
  if odata.state !=# 'OK'
    return
  endif
  let oinfo = odata.context.outline_info
  if odata.context.extracted_by ==# 'filetype'
    " Method: Filetype
    if has_key(oinfo, 'highlight_rules')
      for hl_rule in oinfo.highlight_rules
        if !has_key(hl_rule, 'highlight')
          let hl_rule.highlight = s:get_highlight(hl_rule.name)
        endif
        execute 'syntax match uniteSource__Outline_' . hl_rule.name hl_rule.pattern
              \ 'contained containedin=uniteSource__Outline'
        execute 'highlight default link uniteSource__Outline_' . hl_rule.name hl_rule.highlight
      endfor
    endif
  else
    " Method: Folding
    " NOTE: Folding headings are not highlighted at all.
  endif
endfunction
let s:source.hooks.on_syntax = function(s:SID . 'Source_Hooks_on_syntax')

function! s:Source_gather_candidates(source_args, unite_context)
  " Save the Vim options.
  let save_cpoptions  = &cpoptions
  let save_ignorecase = &ignorecase
  let save_magic = &magic
  try
    set cpoptions&vim
    set noignorecase
    set magic

    let bufnr = a:unite_context.source__outline_source_bufnr
    let options = s:parse_source_arguments(a:source_args, a:unite_context)

    let auto_update = s:get_filetype_option(getbufvar(bufnr, '&filetype'), 'auto_update', 0)
    if auto_update
      let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
      let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
      if model_changenr != buffer_changenr
        " The source buffer has been changed since the last extraction.
        " Need to update the candidates.
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr)
        let options.is_force = 1
      endif
    endif

    let candidates = s:get_candidates(bufnr, options)

    if auto_update
      if get(g:, 'unite_source_outline_event_debug', 0)
        let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
        let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
        call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
              \ ', model = ' . model_changenr)
      endif
    endif

    return candidates

  catch /^NoWindowError:/
    call unite#print_message("[unite-outline] The source buffer has no window.")
    return []

  catch
    if s:get_outline_data(bufnr, 'state') ==# 'OK'
      call unite#util#print_error(v:throwpoint)
      call unite#util#print_error(v:exception)
      call s:set_outline_data(bufnr, 'state', 'Error')
    endif
    call unite#print_message("[unite-outline] " . v:throwpoint)
    call unite#print_message("[unite-outline] " . v:exception)
    return []

  finally
    " Restore the Vim options.
    let &cpoptions  = save_cpoptions
    let &ignorecase = save_ignorecase
    let &magic = save_magic
  endtry
endfunction
let s:source.gather_candidates = function(s:SID . 'Source_gather_candidates')

function! s:parse_source_arguments(source_args, unite_context)
  let options = {
        \ 'is_force': 0,
        \ 'extracted_by': '?',
        \ }
  for value in a:source_args
    if value =~# '^\%(ft\|fi\%[letype]\)$'
      let options.extracted_by = 'filetype'
    elseif value =~# '^fo\%[lding]$'
      let options.extracted_by = 'folding'
    elseif value =~# '^\%(update\|!\)$'
      let options.is_force = 1
    endif
  endfor
  if a:unite_context.is_redraw
    let options.is_force = 1
  endif
  if has_key(a:unite_context, 'source__outline_swapping')
    unlet a:unite_context.source__outline_swapping
    let options.is_force = 0
  endif
  return options
endfunction

" Creates a context Dictionary.
"
function! s:create_context(bufnr, ...)
  let buffer = {
        \ 'nr'  : a:bufnr,
        \ 'path': fnamemodify(bufname(a:bufnr), ':p'),
        \ 'sw'  : getbufvar(a:bufnr, '&shiftwidth'),
        \ 'ts'  : getbufvar(a:bufnr, '&tabstop'),
        \ }
  let buffer.filetypes = split(getbufvar(a:bufnr, '&filetype'), '\.')
  let buffer.filetype = get(buffer.filetypes, 0, '')
  let context = {
        \ 'trigger': 'user', 'is_force': 0, 'buffer': buffer,
        \ 'extracted_by': '?',
        \ }
  call extend(context, (a:0 ? a:1 : {}))
  return context
endfunction

" Returns True if the cached {candidates} is valid and reusable.
"
function! s:is_valid_candidates(candidates, context)
  let last_method = (!empty(a:candidates) &&
        \ a:candidates[0].source__heading_type ==# 'folding' ? 'folding' : 'filetype')
  if a:context.extracted_by == '?'
    let a:context.extracted_by = last_method
  endif
  return (a:context.extracted_by ==# last_method)
endfunction

" Returns False if {cache_data}'s format is not compatible with the current
" version of unite-outline.
"
function! s:is_valid_filecache(cache_data)
  return (type(a:cache_data) == type({})
        \ && has_key(a:cache_data, s:FILECACHE_FORMAT_VERSION_KEY)
        \ && a:cache_data[s:FILECACHE_FORMAT_VERSION_KEY] == s:FILECACHE_FORMAT_VERSION)
endfunction

function! s:get_candidates(bufnr, options)
  " Update the context Dictionary.
  let context = s:create_context(a:bufnr, a:options)
  call s:set_outline_data(a:bufnr, 'context', context)
  if context.is_force || !s:has_outline_data(a:bufnr, 'outline_info')
    " If triggered by <C-l>, reload the outline info.
    let reload = (context.is_force && context.trigger ==# 'user')
    let oinfo = s:get_outline_info(context, reload)
    call s:set_outline_data(a:bufnr, 'outline_info', oinfo)
  else
    let oinfo = s:get_outline_data(a:bufnr, 'outline_info')
  end
  let context.outline_info = oinfo

  if !context.is_force && s:has_outline_data(a:bufnr, 'candidates')
    " Path A: Get candidates from the buffer local cache.
    let candidates = s:get_outline_data(a:bufnr, 'candidates')
    if s:is_valid_candidates(candidates, context)
      return candidates
    endif
  endif

  if !context.is_force && s:FileCache.has(a:bufnr)
    " Path B: Get candidates from the file cache.
    try
      let cache_data = s:FileCache.get(a:bufnr)
      if s:is_valid_filecache(cache_data)
        let candidates = cache_data.candidates
        if s:is_valid_candidates(candidates, context)
          " Save the candidates to the buffer local cache.
          call s:set_outline_data(a:bufnr, 'candidates', candidates)
          return candidates
        endif
      endif
      " Fallback to Path C.
    catch /^unite-outline:/
      call unite#util#print_error(v:exception)
    endtry
  endif

  " Path C: Candidates are invalid or haven't been cached, so try to get
  " candidates by extracting headings from the buffer.

  " Get headings by parsing the buffer.
  let headings = s:extract_headings(context)
  " Convert the headings into candidates.
  let candidates = s:convert_headings_to_candidates(headings, a:bufnr)

  let is_volatile = get(oinfo, 'is_volatile', 0)
  if !is_volatile
    " Save the candidates to the buffer local cache.
    call s:set_outline_data(a:bufnr, 'candidates', candidates)
    let is_persistant = (context.__num_lines__ > g:unite_source_outline_cache_limit)
    if is_persistant
      let cache_data = { 'candidates': candidates }
      let cache_data[s:FILECACHE_FORMAT_VERSION_KEY] = s:FILECACHE_FORMAT_VERSION
      call s:FileCache.set(a:bufnr, cache_data)
    elseif s:FileCache.has(a:bufnr)
      " Remove the invalid file cache.
      call s:FileCache.remove(a:bufnr)
    endif
  endif
  return candidates
endfunction

function! s:extract_headings(context)
  let src_winnr = bufwinnr(a:context.buffer.nr)
  if src_winnr == -1
    throw "NoWindowError:"
  endif

  " Print a progress message.
  if a:context.trigger ==# 'auto_update'
    if g:unite_source_outline_verbose
      call s:Util.print_progress("Update headings...")
    endif
  else
    call s:Util.print_progress("Extract headings...")
  endif

  " Save the Vim options.
  let save_eventignore = &eventignore
  let save_winheight   = &winheight
  let save_winwidth    = &winwidth
  let save_lazyredraw  = &lazyredraw
  try
    set eventignore=all

    " NOTE: To keep the window size on :wincmd, set 'winheight' and 'winwidth'
    " to a small value.
    let &winheight=&winminheight
    let &winwidth=&winminwidth

    set lazyredraw

    " Switch: current window -> source buffer's window
    let cur_winnr = winnr()
    execute src_winnr . 'wincmd w'
    " Save the cursor and scroll.
    let save_cursor  = getpos('.')
    let save_topline = line('w0')

    let lines = [""] + getbufline('%', 1, '$')
    let a:context.__num_lines__ = len(lines)
    " Merge the temporary context data to the context.
    let a:context.lines = lines
    let a:context.heading_lnum = 0
    let a:context.matched_lnum = 0

    let success = 0
    let start_time = s:benchmark_start()

    " Extract headings.
    let s:heading_id = 1
    if a:context.extracted_by !=# 'folding'
      " Path C_1: Extract headings in filetype-specific way using the
      " filetype's outline info.
      let a:context.extracted_by = 'filetype'
      let headings = s:extract_filetype_headings(a:context)
    else
      " Path C_2: Extract headings using folds' information.
      let a:context.extracted_by = 'folding'
      let headings = s:extract_folding_headings(a:context)
    endif

    " Update the change count of the headings.
    call s:set_outline_data(a:context.buffer.nr, 'model_changenr', changenr())

    let success = 1
    return headings

    " Don't catch anything.

  finally
    " Remove the temporary context data.
    unlet! a:context.lines
    unlet! a:context.heading_lnum
    unlet! a:context.matched_lnum

    " Restore the cursor and scroll.
    let save_scrolloff = &scrolloff
    set scrolloff=0
    call cursor(save_topline, 1)
    normal! zt
    call setpos('.', save_cursor)
    let &scrolloff = save_scrolloff
    " Switch: current window <- source buffer's window
    execute cur_winnr . 'wincmd w'

    " Restore the Vim options.
    let &lazyredraw  = save_lazyredraw
    let &winheight   = save_winheight
    let &winwidth    = save_winwidth
    let &eventignore = save_eventignore

    if success
      " Print a progress message.
      if a:context.trigger ==# 'auto_update'
        if g:unite_source_outline_verbose
          call s:Util.print_progress("Update headings...done.")
        endif
      else
        call s:Util.print_progress("Extract headings...done.")
      endif
      call s:benchmark_stop(start_time, a:context.__num_lines__)
    endif
  endtry
endfunction

function! s:benchmark_start()
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    return s:get_reltime()
  else
    return 0
  endif
endfunction

function! s:benchmark_stop(start_time, num_lines)
  if get(g:, 'unite_source_outline_profile', 0) && has("reltime")
    let used_time = s:get_reltime() - a:start_time
    let used_time_100l = used_time * (str2float("100") / a:num_lines)
    call s:Util.print_progress("unite-outline: used=" . string(used_time) .
          \ "s, 100l=". string(used_time_100l) . "s")
  endif
endfunction

function! s:get_reltime()
  return str2float(reltimestr(reltime()))
endfunction

" Extract headings from the source buffer in its filetype specific way using
" the filetype's outline info.
"
function! s:extract_filetype_headings(context)
  let buffer = a:context.buffer
  let oinfo = a:context.outline_info
  if empty(oinfo)
    if empty(buffer.filetype)
      call unite#print_message("[unite-outline] Please set the filetype.")
    else
      call unite#print_message("[unite-outline] " .
            \ "Sorry, " . toupper(buffer.filetype) . " is not supported.")
    endif
    return []
  endif

  " Extract headings.
  if has_key(oinfo, 'before')
    call oinfo.before(a:context)
  endif
  if has_key(oinfo, 'extract_headings')
    let headings = oinfo.extract_headings(a:context)
    let headings_normalized = 0
  else
    let headings = s:builtin_extract_headings(a:context)
    let headings_normalized = 1
  endif
  if has_key(oinfo, 'after')
    call oinfo.after(a:context)
  endif

  " Normalize headings.
  if type(headings) == type({})
    let heading_tree = headings | unlet headings
    let headings = s:Tree.flatten(heading_tree)
  else
    let headings = s:Tree.List.normalize_levels(headings)
  endif
  if !headings_normalized
    call map(headings, 's:normalize_heading(v:val, a:context)')
  endif

  " Filter headings.
  let ignore_types = unite#sources#outline#get_filetype_option(buffer.filetype, 'ignore_types')
  let headings = s:filter_headings(headings, ignore_types)

  return headings
endfunction

function! s:builtin_extract_headings(context)
  let oinfo = a:context.outline_info
  let [which, pattern] = s:build_heading_pattern(oinfo)

  let has_create_heading = has_key(oinfo, 'create_heading')
  let num_lines = line('$')

  let skip_ranges = s:get_skip_ranges(a:context)
  call add(skip_ranges, [num_lines + 1, num_lines + 2]) | " sentinel
  let srp = 0 | " skip range pointer

  let headings = []
  call cursor(1, 1)
  while 1
    let step  = 1
    let found = 0
    " Search the buffer for the next heading.
    let [lnum, col, submatch] = searchpos(pattern, 'cpW')
    if lnum == 0
      break
    endif
    while lnum > skip_ranges[srp][1]
      let srp += 1
    endwhile
    if lnum < skip_ranges[srp][0]
      if which[submatch] ==# 'heading-1' && lnum < num_lines - 3
        " Matched: heading-1
        let next_line = getline(lnum + 1)
        if next_line =~ '[[:punct:]]\@!\S'
          let a:context.heading_lnum = lnum + 1
          let a:context.matched_lnum = lnum
          let step  = 2
          let found = 1
        elseif next_line =~ '\S' && lnum < num_lines - 4
          " See one more next.
          let next_line = getline(lnum + 2)
          if next_line =~ '[[:punct:]]\@!\S'
            let a:context.heading_lnum = lnum + 2
            let a:context.matched_lnum = lnum
            let step  = 3
            let found = 1
          endif
        endif
      elseif which[submatch] ==# 'heading'
        " Matched: heading
        let a:context.heading_lnum = lnum
        let a:context.matched_lnum = lnum
        let found = 1
      elseif which[submatch] ==# 'heading+1' && lnum > 0
        " Matched: heading+1
        let a:context.heading_lnum = lnum - 1
        let a:context.matched_lnum = lnum
        let prev_line = getline(lnum - 1)
        let found = (prev_line =~ '[[:punct:]]\@!\S')
      endif
      if found
        let heading_line = getline(a:context.heading_lnum)
        let matched_line = getline(a:context.matched_lnum)
        if has_create_heading
          let heading = oinfo.create_heading(
                \ which[submatch], heading_line, matched_line, a:context)
        else
          let heading = {'word':heading_line}
        endif
        if !empty(heading)
          call add(headings, s:normalize_heading(heading, a:context))
        endif
        if len(headings) >= g:unite_source_outline_max_headings
          call unite#print_message("[unite-outline] " . 
                \ "Too many headings, the extraction was interrupted.")
          break
        endif
      endif
    endif
    if lnum == num_lines
      break
    endif
    call cursor(lnum + step, 1)
  endwhile
  return headings
endfunction

" Merge heading-1, heading, heading+1 patterns into one heading pattern for
" use of searchpos().
"
" Example of the return value:
"
"   [ ['dummy', 'dummy', 'heading-1', 'heading', 'heading+1'],
"     '\%(\(heading-1\)\|\(heading\)\|\(heading+1\)\)' ]
"
function! s:build_heading_pattern(oinfo)
  let which = ['dummy', 'dummy']
  " NOTE: searchpos() returns submatch counted from 2.
  let sub_patterns = []
  if has_key(a:oinfo, 'heading-1')
    call add(which, 'heading-1')
    call add(sub_patterns, a:oinfo['heading-1'])
  endif
  if has_key(a:oinfo, 'heading')
    call add(which, 'heading')
    call add(sub_patterns, a:oinfo.heading)
  endif
  if has_key(a:oinfo, 'heading+1')
    call add(which, 'heading+1')
    call add(sub_patterns, a:oinfo['heading+1'])
  endif
  call map(sub_patterns, 's:_substitue_sub_pattern(v:val)')
  let pattern = '\%(' . join(sub_patterns, '\|') . '\)'
  return [which, pattern]
endfunction
function! s:_substitue_sub_pattern(pattern)
  " Substitute all '\(' with '\%('
  let meta_lparen = '\(\(^\|[^\\]\)\(\\\{2}\)*\)\@<=\\('
  return '\(' . substitute(a:pattern, meta_lparen, '\\%(', 'g') . '\)'
endfunction

" Returns a List of ranges to be skipped while the extraction.
"
function! s:get_skip_ranges(context)
  let oinfo = a:context.outline_info
  if !has_key(oinfo, 'skip') | return [] | endif
  let ranges = []
  if has_key(oinfo.skip, 'header')
    let header_range = s:get_header_range(a:context)
    if !empty(header_range)
      call add(ranges, header_range)
    endif
  endif
  if has_key(oinfo.skip, 'block')
    let block = oinfo.skip.block
    let num_lines = line('$')
    call cursor(1, 1)
    while 1
      let beg_lnum = search(block.begin, 'ceW')
      if beg_lnum == 0 || beg_lnum == num_lines
        break
      endif
      let end_lnum = search(block.end, 'W')
      if end_lnum == 0
        break
      endif
      call add(ranges, [beg_lnum, end_lnum])
      if end_lnum == num_lines
        break
      else
        call cursor(end_lnum + 1, 1)
      endif
    endwhile
  endif
  return ranges
endfunction

function! s:get_header_range(context)
  let oinfo = a:context.outline_info
  let header = oinfo.skip.header
  let has_leading = has_key(header, 'leading')
  let has_block   = has_key(header, 'block')

  let lnum = 1 | let num_lines = line('$')
  while lnum < num_lines
    let line = getline(lnum)
    if has_leading && line =~# header.leading
      let lnum = s:skip_while(header.leading, lnum)
    elseif has_block && line =~# header.block.begin
      let lnum = s:skip_until(header.block.end, lnum)
    else
      break
    endif
  endwhile
  let lnum -= 1
  if lnum > 1
    return [1, lnum]
  else
    return []
  endif
endfunction

function! s:skip_while(pattern, from)
  let lnum = a:from + 1 | let num_lines = line('$')
  while lnum <= num_lines
    let line = getline(lnum)
    if line !~# a:pattern
      break
    endif
    let lnum += 1
  endwhile
  return lnum
endfunction

function! s:skip_until(pattern, from)
  let lnum = a:from | let num_lines = line('$')
  while lnum <= num_lines
    let line = getline(lnum)
    let lnum += 1
    if line =~# a:pattern
      break
    endif
  endwhile
  return lnum
endfunction

function! s:extract_folding_headings(context)
  let headings = []
  let cur_level = 0
  let lnum = 1 | let num_lines = line('$')
  while lnum < num_lines
    let foldlevel = foldlevel(lnum)
    if foldlevel > cur_level
      let heading_lnum = lnum
      if &l:foldmethod ==# 'indent'
        let heading_lnum -=1
      endif
      let heading = {
            \ 'word' : getline(heading_lnum),
            \ 'level': foldlevel,
            \ 'type' : 'folding',
            \ 'lnum' : heading_lnum,
            \ }
      call add(headings, s:normalize_heading(heading, a:context))
      if len(headings) >= g:unite_source_outline_max_headings
        call unite#print_message("[unite-outline] " .
              \ "Too many headings, the extraction was interrupted.")
        break
      endif
    endif
    let cur_level = foldlevel
    let lnum += 1
  endwhile
  return headings
endfunction

function! s:normalize_heading(heading, context)
  let oinfo = a:context.outline_info
  let a:heading.id = s:heading_id
  let a:heading.word = s:normalize_heading_word(a:heading.word)
  call extend(a:heading, {
        \ 'level': 1,
        \ 'type' : 'generic',
        \ 'lnum' : a:context.heading_lnum,
        \ 'keyword': a:heading.word,
        \ }, 'keep')
  let a:heading.line = a:context.lines[a:heading.lnum]
  let a:heading.signature = s:calc_signature(a:heading.lnum, a:context.lines)
  " group
  if !has_key(a:heading, 'group')
    let group_map = get(oinfo, 'heading_group_map', {})
    let a:heading.group = get(group_map, a:heading.type, 'generic')
  endif
  " keyword => candidate.word
  if has_key(oinfo, '__not_match_pattern__')
    let a:heading.keyword =
          \ substitute(a:heading.word, oinfo.__not_match_pattern__, '', 'g')
  endif
  let s:heading_id += 1
  return a:heading
endfunction

function! s:normalize_heading_word(word)
  let word = substitute(substitute(a:word, '^\s*', '', ''), '\s*$', '', '')
  let word = substitute(word, '\s\+', ' ', 'g')
  return word
endfunction

let s:SIGNATURE_RANGE = 10
let s:SIGNATURE_PRECISION = 2

function! s:calc_signature(lnum, lines)
  let range = s:SIGNATURE_RANGE
  let from = max([1, a:lnum - range])
  let to   = min([a:lnum + range, len(a:lines) - 1])
  let bwd_lines = a:lines[from : a:lnum]
  let fwd_lines = a:lines[a:lnum  : to]
  return s:_calc_signature(bwd_lines, fwd_lines)
endfunction
function! s:_calc_signature(bwd_lines, fwd_lines)
  let precision = s:SIGNATURE_PRECISION
  let is_not_blank = 'v:val =~ "\\S"'
  let bwd_lines = filter(a:bwd_lines, is_not_blank)[-precision-1 : -2]
  let fwd_lines = filter(a:fwd_lines, is_not_blank)[1 : precision]
  return join(map(bwd_lines + fwd_lines, 's:digest_line(v:val)'), '')
endfunction

" Quick and Dirty Digest
function! s:digest_line(line)
  let line = substitute(a:line, '\s*', '', 'g')
  if s:strchars(line) <= 20
    let digest = line
  else
    let line = matchstr(line, '^\%(.\{5}\)\{,20}')
    let digest = substitute(line, '\(.\).\{4}', '\1', 'g')
  endif
  return digest
endfunction

if v:version >= 703
  function! s:strchars(str)
    return strchars(a:str)
  endfunction
else
  function! s:strchars(str)
    return strlen(substitute(a:str, '.', 'c', 'g'))
  endfunction
endif

" Heading Type Filter
function! s:filter_headings(headings, ignore_types)
  if empty(a:ignore_types) | return a:headings | endif
  let headings = a:headings
  let ignore_types = copy(a:ignore_types)

  " Remove comment headings.
  let idx = index(ignore_types, 'comment')
  if idx >= 0
    call filter(headings, 'v:val.type !=# "comment"')
    let headings = s:Tree.List.normalize_levels(headings)
    call remove(ignore_types, idx)
  endif
  " Remove headings to be ignored.
  call map(ignore_types, 'unite#util#escape_pattern(v:val)')
  let ignore_types_pattern = '^\%(' . join(ignore_types, '\|') . '\)$'
  let pred = 'v:val.type =~# ' . string(ignore_types_pattern)
  let headings = s:Tree.List.remove(headings, pred)
  return headings
endfunction

function! s:convert_headings_to_candidates(headings, bufnr)
  if empty(a:headings) | return [] | endif
  let path = fnamemodify(bufname(a:bufnr), ':p')
  let candidates = map(copy(a:headings), 's:create_candidate(v:val, path)')
  return candidates
endfunction

function! s:create_candidate(heading, path)
  " NOTE:
  "   abbr - String for displaying
  "   word - String for narrowing
  let indent = repeat(' ', (a:heading.level - 1) * g:unite_source_outline_indent_width)
  let cand = {
        \ 'abbr': indent . a:heading.word,
        \ 'word': a:heading.keyword,
        \ 'source': 'outline',
        \ 'kind'  : 'jump_list',
        \ 'action__path': a:path,
        \ 'action__line': a:heading.lnum,
        \ 'action__pattern': '^' . unite#util#escape_pattern(a:heading.line) . '$',
        \ 'action__signature': a:heading.signature,
        \ 'source__heading_id': a:heading.id,
        \ 'source__heading_level': a:heading.level,
        \ 'source__heading_type' : a:heading.type,
        \ 'source__heading_group': a:heading.group,
        \}
  return cand
endfunction

function! s:Source_calc_signature(lnum)
  let range = s:SIGNATURE_RANGE
  let from = max([1, a:lnum - range])
  let to   = min([a:lnum + range, line('$')])
  let bwd_lines = getline(from, a:lnum)
  let fwd_lines = getline(a:lnum, to)
  return s:_calc_signature(bwd_lines, fwd_lines)
endfunction
let s:source.calc_signature = function(s:SID . 'Source_calc_signature')

"---------------------------------------
" Actions

let s:action_table = {}
let s:action_table.preview = {
      \ 'description'  : 'preview this position',
      \ 'is_selectable': 0,
      \ 'is_quit'      : 0,
      \ }
function! s:Action_preview(candidate)
  let cand = a:candidate

  " NOTE: Executing :pedit for a nofile buffer clears the buffer content at
  " all, so prohibit it.
  let bufnr = bufnr(unite#util#escape_file_searching(cand.action__path))
  if getbufvar(bufnr, '&buftype') =~# '\<nofile\>'
    call unite#print_error("unite-outline: Can't preview the nofile buffer.")
    return
  endif

  " workaround for `cursor-goes-to-top' problem on :pedit %
  let save_cursors = s:save_window_cursors(bufnr)
  let n_wins = winnr('$')
  call unite#take_action('preview', cand)
  wincmd p
  let preview_winnr = winnr()
  call s:adjust_scroll(s:best_winline())
  wincmd p
  call s:restore_window_cursors(save_cursors, preview_winnr, (winnr('$') > n_wins))
endfunction
let s:action_table.preview.func = function(s:SID . 'Action_preview')

function! s:save_window_cursors(bufnr)
  let save_cursors = {}
  let save_winnr = winnr()
  let winnr = 1
  while winnr <= winnr('$')
    if winbufnr(winnr) == a:bufnr
      execute winnr . 'wincmd w'
      let save_cursors[winnr] = {
            \ 'cursor' : getpos('.'),
            \ 'winline': winline(),
            \ }
    endif
    let winnr += 1
  endwhile
  execute save_winnr . 'wincmd w'
  return save_cursors
endfunction

function! s:restore_window_cursors(save_cursors, preview_winnr, is_new)
  let save_winnr = winnr()
  for [winnr, saved] in items(a:save_cursors)
    if winnr == a:preview_winnr
      continue
    elseif a:is_new && winnr >= a:preview_winnr
      let winnr += 1
    endif
    execute winnr . 'wincmd w'
    if getpos('.') != saved.cursor
      call setpos('.', saved.cursor)
      call s:adjust_scroll(saved.winline)
    endif
  endfor
  execute save_winnr . 'wincmd w'
endfunction

function! s:best_winline()
  return max([1, winheight(0) * g:unite_kind_jump_list_after_jump_scroll / 100])
endfunction

function! s:adjust_scroll(best_winline)
  normal! zt
  let save_cursor = getpos('.')
  let winl = 1
  " Scroll the cursor line down to the best position.
  while winl <= a:best_winline
    let prev_winl = winl
    execute "normal! \<C-y>"
    let winl = winline()
    if winl == prev_winl
      break
    end
    let prev_winl = winl
  endwhile
  if winl > a:best_winline
    execute "normal! \<C-e>"
  endif
  call setpos('.', save_cursor)
endfunction

let s:source.action_table.jump_list = s:action_table

"-----------------------------------------------------------------------------
" Auto-update

function! s:register_autocmds()
  augroup plugin-unite-source-outline
    autocmd! * <buffer>
    autocmd CursorHold   <buffer> call s:on_cursor_hold()
    autocmd BufWritePost <buffer> call s:on_buf_write_post()
  augroup END
endfunction

augroup plugin-unite-source-outline-win-enter
  autocmd!
  autocmd BufWinEnter * call s:on_buf_win_enter()
augroup END

function! s:on_cursor_hold()
  let bufnr = bufnr('%')
  if !s:has_outline_data(bufnr)
    return
  endif
  call s:Util.print_debug('event', 'on_cursor_hold at buffer #' . bufnr)
  call s:update_buffer_changenr()
  if s:should_update('hold')
    call s:update_headings(bufnr)
  endif
endfunction

function! s:on_buf_write_post()
  let bufnr = bufnr('%')
  if !s:has_outline_data(bufnr)
    return
  endif
  call s:Util.print_debug('event', 'on_buf_write_post at buffer #' . bufnr)
  call s:update_buffer_changenr()
  if s:should_update('write')
    call s:update_headings(bufnr)
  endif
endfunction

" Update the change count of the current buffer.
"
function! s:update_buffer_changenr()
  call s:set_outline_data(bufnr('%'), 'buffer_changenr', changenr())
endfunction

" Returns True if the current buffer has been changed and the headings of the
" buffer should be updated.
"
function! s:should_update(event)
  let auto_update_enabled = s:get_filetype_option(&l:filetype, 'auto_update')
  if !auto_update_enabled
    return 0
  endif
  let auto_update_event = s:get_filetype_option(&l:filetype, 'auto_update_event')
  if auto_update_event ==# 'write' && a:event ==# 'hold'
    return 0
  endif
  let bufnr = bufnr('%')
  let buffer_changenr = s:get_outline_data(bufnr, 'buffer_changenr', 0)
  let  model_changenr = s:get_outline_data(bufnr,  'model_changenr', 0)
  call s:Util.print_debug('event', 'changenr: buffer = ' . buffer_changenr .
        \ ', model = ' . model_changenr)
  return (buffer_changenr != model_changenr)
  " NOTE: The current changenr may smaller than the last one because undo
  " commands decrease the changenr.
endfunction

function! s:update_headings(bufnr)
  call s:Util.print_debug('event', 'update_headings')
  try
    " Update the Model data (headings).
    call s:get_candidates(a:bufnr, { 'trigger': 'auto_update', 'is_force': 1 })
  catch
    " Ignore all errors caused by auto-updates because they are so annoying.
    " We can know the error details from the error which was caught at
    " gather_candidates() not here.
    return
  endtry
  " Update the View (unite.vim' buffer) if the visible outline buffer exists.
  let outline_bufnrs = s:find_outline_buffers(a:bufnr)
  " NOTE: An outline buffer is an unite.vim's buffer that is displaying the
  " candidates from outline source.
  for bufnr in outline_bufnrs
    call s:Util.print_debug('event', 'redraw outline buffer #' . bufnr)
    call unite#force_redraw(bufwinnr(bufnr))
  endfor
endfunction

" Returns a List of bufnrs of the outline buffers that are displaying the
" heading list of the buffer {src_bufnr}.
"
function! s:find_outline_buffers(src_bufnr)
  let outline_bufnrs = []
  let bufnr = 1
  while bufnr <= bufnr('$')
    if bufwinnr(bufnr) > 0
      try
        " NOTE: This code depands on the current implementation of unite.vim.
        if s:is_unite_buffer(bufnr)
          let unite = getbufvar(bufnr, 'unite')
          let outline_source = s:Unite_find_outline_source(unite)
          if !empty(outline_source)
            let unite_context = outline_source.unite__context
            if unite_context.source__outline_source_bufnr == a:src_bufnr
              call add(outline_bufnrs, bufnr)
            endif
          endif
        endif
      catch
        call unite#util#print_error(v:throwpoint)
        call unite#util#print_error(v:exception)
      endtry
    endif
    let bufnr += 1
  endwhile
  return outline_bufnrs
endfunction

function! s:is_unite_buffer(bufnr)
  if unite#is_win()
    return (bufname(a:bufnr) =~# '^\[unite\]')
  else
    return (bufname(a:bufnr) =~# '^\*unite\*')
  endif
endfunction

function! s:Unite_find_outline_source(unite)
  let result = filter(copy(a:unite.sources), 'v:val.name ==# "outline"')
  if empty(result)
    return {}
  else
    return result[0]
  endif
endfunction

function! s:on_buf_win_enter()
  let winnr = winnr()
  if !s:has_outline_buffer_ids(winnr)
    return
  endif
  let new_bufnr = bufnr('%')
  if s:is_unite_buffer(new_bufnr)
    " NOTE: When -no-split.
    return
  endif
  let old_bufnr = bufnr('#')
  call s:Util.print_debug('event', 'on_buf_win_enter at window #' . winnr .
        \ ' from buffer #' . old_bufnr . ' to #' . new_bufnr)
  call s:swap_headings(s:get_outline_buffer_ids(winnr), new_bufnr)
endfunction

" Swaps the heading lists displayed in the outline buffers whose buffer ids
" are one of {outline_buffer_ids} for the heading list of buffer {new_bufnr}.
"
function! s:swap_headings(outline_buffer_ids, new_bufnr)
  let bufnr = 1
  while bufnr <= bufnr('$')
    if bufwinnr(bufnr) > 0
      try
        " NOTE: This code depands on the current implementation of unite.vim.
        if s:is_unite_buffer(bufnr)
          let unite = getbufvar(bufnr, 'unite')
          let outline_source = s:Unite_find_outline_source(unite)
          if !empty(outline_source)
            let unite_context = outline_source.unite__context
            if index(a:outline_buffer_ids, unite_context.source__outline_buffer_id) >= 0
              let unite_context.source__outline_source_bufnr = a:new_bufnr
              let unite_context.source__outline_swapping = 1
              call s:Util.print_debug('event', 'redraw outline buffer #' . bufnr)
              call s:initialize_outline_data()
              call unite#force_redraw(bufwinnr(bufnr))
            endif
          endif
        endif
      catch
        call unite#util#print_error(v:throwpoint)
        call unite#util#print_error(v:exception)
      endtry
    endif
    let bufnr += 1
  endwhile
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
