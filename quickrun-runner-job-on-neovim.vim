" quickrun: runner/job: Runs by job feature on neovim.
" Author : ogura01
" License: zlib License

if exists('g:loaded_quickrun_runner_job_on_neovim') | finish | endif
let g:loaded_quickrun_runner_job_on_neovim = 1

let s:is_win = has('win32')

let s:runner = {
\   'name': 'job_on_neovim',
\   'kind': 'runner',
\   'data': '',
\   'config': {
\     'interval': 1000,
\   }
\ }

" ------------------------------------------------------------------------------
"  quickrun: run
" ------------------------------------------------------------------------------
function! s:runner.run(commands, input, session) abort
  let self.command = join(a:commands, ' && ')
  echom self.command

  let cmd_arg = s:is_win ? printf("cmd.exe /c (%s)", self.command)
  \                      : ['sh', '-c', self.command]

  let self._key = a:session.continue()
  let self._job = jobstart(cmd_arg, self)
  let self._timer = timer_start(self.config.interval, self.calc_timer, { 'repeat': -1 })
endfunction

" ------------------------------------------------------------------------------
"  quickrun: output
" ------------------------------------------------------------------------------
function! s:runner.calc_output() dict
  if has_key(self, '_key') && self.data != ''
    call quickrun#session(self._key, 'output', self.data)
  endif
  let self.data = ''
endfunction

" ------------------------------------------------------------------------------
"  quickrun: sweep
" ------------------------------------------------------------------------------
function! s:runner.sweep() abort
  call self.stop_and_flush()
  echom 'cancel: ' . self.command
endfunction

" ------------------------------------------------------------------------------
"  dump and stop
" ------------------------------------------------------------------------------
function! s:runner.stop_and_flush() dict
  if has_key(self, '_job')
    try
      call jobstop(self._job)
    catch => err
      echo err
    endtry
    unlet! self._job
  endif
  if has_key(self, '_timer')
    try
      call timer_stop(self._timer)
    catch => err
      echo err
    endtry
    unlet! self._timer
  endif

  call self.calc_output()
endfunction

" ------------------------------------------------------------------------------
"  job: callback
" ------------------------------------------------------------------------------
function! s:runner.on_stdout(job_id, data, event) dict
  let self.data .= join(a:data, "\n")
endfunction

function! s:runner.on_stderr(job_id, data, event) dict
  let self.data .= join(a:data, "\n")
endfunction

function! s:runner.on_exit(job_id, data, event) dict
  call self.stop_and_flush()
  if has_key(self, '_key')
    try
      call quickrun#session(self._key, 'finish', a:data)
    catch => err
      echo err
    endtry
    unlet! self._key
  endif
endfunction

" ------------------------------------------------------------------------------
"  timer: callback
" ------------------------------------------------------------------------------
function! s:runner.calc_timer(timer_id) dict
  call self.calc_output()
endfunction

try
  call quickrun#module#register(deepcopy(s:runner))
catch
endtry

