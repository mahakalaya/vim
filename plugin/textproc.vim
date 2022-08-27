"======================================================================
"
" textproc.vim - 
"
" Created by skywind on 2022/01/21
" Last Modified: 2022/08/28 07:19
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" script home
"----------------------------------------------------------------------
let s:script_home = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:scripts = {}


"----------------------------------------------------------------------
" string strip
"----------------------------------------------------------------------
function! s:string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)[\s\r\n]*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" script root
"----------------------------------------------------------------------
function! s:script_roots() abort
	let candidate = []
	let fn = s:script_home . '/site/text'
	let fn = substitute(fn, '\\', '\/', 'g')
	let candidate += [fn]
	let location = get(g:, 'textproc_root', '')
	if location != ''
		if isdirectory(location)
			let candidate += [location]
		endif
	endif
	let rtp_name = get(g:, 'textproc_home', 'text')
	for rtp in split(&rtp, ',')
		if rtp != ''
			let path = rtp . '/' . rtp_name
			if isdirectory(path)
				let candidate += [path]
			endif
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" list script
"----------------------------------------------------------------------
function! s:script_list() abort
	let select = {}
	let check = {}
	let marks = ['py', 'lua', 'pl', 'php', 'js', 'ts', 'rb']
	let marks += ['gawk', 'awk']
	if s:windows == 0
		let marks += ['sh', 'zsh', 'bash', 'fish']
	else
		let marks += ['cmd', 'bat', 'exe', 'ps1']
	endif
	for mark in marks
		let check[mark] = 1
	endfor
	let roots = s:script_roots()
	for root in roots
		if isdirectory(root) == 0
			continue
		endif
		let filelist = globpath(root, '*', 1, 1)
		call sort(filelist)
		for fn in filelist
			let name = fnamemodify(fn, ':t')
			let main = fnamemodify(fn, ':t:r')
			let ext = fnamemodify(name, ':e')
			let ext = (s:windows == 0)? ext : tolower(ext)
			if s:windows
				let fn = substitute(fn, '\/', '\\', 'g')
			endif
			if has_key(check, ext)
				let select[main] = fn
			endif
		endfor
	endfor
	return select
endfunc

" echo s:script_list()


"----------------------------------------------------------------------
" returns shebang
"----------------------------------------------------------------------
function! s:script_shebang(script)
	let script = a:script
	if !filereadable(script)
		return ''
	endif
	let textlist = readfile(script, '', 20)
	let shebang = ''
	for text in textlist
		let text = s:string_strip(text)
		if text =~ '^#'
			let text = s:string_strip(strpart(text, 1))
			if text =~ '^!'
				let shebang = s:string_strip(strpart(text, 1))
				break
			endif
		endif
	endfor
	return shebang
endfunc


"----------------------------------------------------------------------
" detect script runner
"----------------------------------------------------------------------
function! s:script_runner(script) abort
	let script = a:script
	let ext = fnamemodify(script, ':e')
	let ext = (s:windows == 0)? ext : tolower(ext)
	let runner = ''
	if script == ''
		return ''
	elseif executable(script) 
		return ''
	elseif exists('g:textproc_runner')
		let runners = g:textproc_runner
		let runner = get(runners, ext, '')
		if runner != ''
			return runner
		endif
	endif
	if s:windows
		if index(['cmd', 'bat', 'exe'], ext) >= 0
			return ''
		elseif ext == 'ps1'
			return 'powershell -file'
		endif
	else
		let shebang = s:script_shebang(script)
		if shebang != ''
			return shebang
		endif
	endif
	if index(['py', 'pyw', 'pyc', 'pyo'], ext) >= 0
		if s:windows
			for name in ['python', 'python3', 'python2']
				if executable(name)
					return name
				endif
			endfor
		else
			for name in ['python3', 'python', 'python2']
				if executable(name)
					return name
				endif
			endfor
		endif
	elseif ext == 'lua'
		let t = ['lua', 'lua5.4', 'lua5.3', 'lua5.2', 'lua5.1', 'luajit']
		for name in t
			if executable(name)
				return name
			endif
		endfor
	elseif ext == 'sh'
		for name in ['sh', 'bash', 'zsh', 'dash']
			if executable(name)
				return name
			endif
		endfor
		if executable('busybox')
			return 'busybox sh'
		endif
	elseif ext == 'gawk'
		if executable('gawk')
			return 'gawk -f'
		endif
	elseif ext == 'awk'
		for name in ['gawk', 'awk', 'mawk', 'nawk']
			if executable(name)
				return name . ' -f'
			endif
		endfor
	endif
	let ext_runners = {
				\ 'pl' : 'perl',
				\ 'php' : 'php',
				\ 'rb' : 'ruby',
				\ 'zsh' : 'zsh',
				\ 'bash' : 'bash',
				\ 'sh' : 'sh',
				\ 'fish' : 'fish',
				\ }
	if has_key(ext_runners, ext) 
		let runner = ext_runners[ext]
		if type(runner) == type('')
			if executable(runner)
				return runner
			endif
		elseif type(runner) == type([])
			for name in runner
				if executable(runner)
					return runner
				endif
			endfor
		endif
	endif
	return ''
endfunc

" echo s:script_runner('c:/share/vim/lib/ascmini.awk')


"----------------------------------------------------------------------
" run script
"----------------------------------------------------------------------
function! s:script_run(name, args, lnum, count, debug) abort
	if a:count <= 0
		return 0
	endif
	let scripts = s:script_list()
	if has_key(scripts, a:name) == 0
		echohl ErrorMsg
		echo 'ERROR: runner not find:' a:name
		echohl None
		return 0
	endif
	let script = scripts[a:name]
	let runner = s:script_runner(script)
	let runner = (runner != '')? (runner . ' ') : ''
	let cmd = runner . script
	if a:args != ''
		let cmd = cmd . ' ' . (a:args)
	endif
	let line1 = a:lnum
	let line2 = line1 + a:count - 1
	let cmd = printf('%s,%s!%s', line1, line2, cmd)
	let $VIM_ENCODING = &encoding
	let $VIM_FILEPATH = expand('%:p')
	let $VIM_FILENAME = expand('%:t')
	let $VIM_FILEDIR = expand('%:p:h')
	execute cmd
	return 0
endfunc



"----------------------------------------------------------------------
" function
"----------------------------------------------------------------------
function! s:TextProcess(bang, args, line1, line2, count) abort
	let cmdline = s:string_strip(a:args)
	let name = ''
	let args = ''
	if cmdline =~# '^\w\+'
		let name = matchstr(cmdline, '^\w\+')
		let args = substitute(cmdline, '^\w\+\s*', '', '')
	endif
	if a:count == 0
		echohl WarningMsg
		" echo 'Warning: no range specified !'
		echohl None
		return 0
	endif
	if name == ''
		echohl ErrorMsg
		echo 'ERROR: script name required'
		echohl None
	endif
	let cc = a:line2 - a:line1 + 1
	call s:script_run(name, args, a:line1, cc, 0)
	return 0
endfunc


"----------------------------------------------------------------------
" command complete
"----------------------------------------------------------------------
function! s:complete(ArgLead, CmdLine, CursorPos)
	let candidate = []
	let scripts = s:script_list()
	let names = keys(scripts)
	call sort(names)
	for name in names
		if stridx(name, a:ArgLead) == 0
			let candidate += [name]
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" command defintion
"----------------------------------------------------------------------
command! -bang -nargs=+ -range=0 -complete=customlist,s:complete TP
		\ call s:TextProcess('<bang>', <q-args>, <line1>, <line2>, <count>)



