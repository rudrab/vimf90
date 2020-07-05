if exists('b:loaded_hl_vimf90')
  finish
endif
let b:loaded_hl_vimf90 = 1

let s:save_cpo = &cpo
set cpo&vim

let s:SPEED_MOST_IMPORTANT = 1
let s:SPEED_DEFAULT = 2


if !exists('b:hl_vimf90_hl_groupname')
  let b:hl_vimf90_hl_groupname = 'cursorline'
endif
if !exists('b:hl_vimf90_hl_priority')
  let b:hl_vimf90_hl_priority = 0
endif
if !exists('b:hl_vimf90_speed_level')
  let b:hl_vimf90_speed_level = s:SPEED_DEFAULT
endif
if !exists('b:hl_vimf90_cursor_wait')
  let b:hl_vimf90_cursor_wait = 0.200
endif
if !exists('b:hl_vimf90_allow_ft')
  let b:hl_vimf90_allow_ft = ''
endif

if !exists('b:hl_vimf90_allow_ft_regexp')
  echoerr 'hl_vimf90: b:hl_vimf90_allow_ft_regexp is removed. use b:hl_vimf90_allow_ft'
endif



com! HiMatch call hl_vimf90#do_highlight()
com! NoHiMatch call hl_vimf90#hide()
com! HiMatchOn call hl_vimf90#enable()
com! HiMatchOff call hl_vimf90#disable()

if exists('b:hl_vimf90_enable_on_vim_startup') && b:hl_vimf90_enable_on_vim_startup
    HiMatchOn
endif

let &cpo = s:save_cpo
unlet s:save_cpo

