" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" layout.vim - window layout
"
" Created by skywind on 2022/11/25
" Last Modified: 2022/11/25 20:02:09
"
"======================================================================


"----------------------------------------------------------------------
" horizon
"----------------------------------------------------------------------
function! s:layout_horizon(ctx, opts) abort
	let ctx = a:ctx
	let padding = starter#config#get(a:opts, 'padding')
	let spacing = starter#config#get(a:opts, 'spacing')
	let ctx.cx = a:ctx.wincx - (padding[0] + padding[2])
	if ctx.cx <= ctx.stride
		let ctx.ncols = 1
	else
		" Ax + B(x-1) = y  -->  (A+B)x = y+B  --> x = (y+B)/(A+B)
		let ctx.ncols = (ctx.cx + spacing) / (spacing + ctx.stride)
	endif
	if type(ctx.ncols) == 5
		let ctx.ncols = float2nr(ctx.ncols)
	endif
	let ctx.ncols = (ctx.ncols < 1)? 1 : ctx.ncols
	let nitems = len(ctx.items)
	let ctx.nrows = (nitems + ctx.ncols - 1) / ctx.ncols
	if type(ctx.nrows) == 5
		let ctx.nrows = float2nr(ctx.nrows)
	endif
	let min_height = starter#config#get(a:opts, 'min_height')
	let max_height = starter#config#get(a:opts, 'max_height')
	let padding = starter#config#get(a:opts, 'padding')
	let ypad = padding[1] + padding[3]
	let min_height -= ypad
	let max_height -= ypad
	let min_height = (min_height < 1)? 1 : min_height
	let max_height = (max_height < 1)? 1 : max_height
	let ctx.pg_count = (ctx.nrows + max_height - 1) / max_height
	if type(ctx.pg_count) == 5
		let ctx.pg_count = float2nr(ctx.pg_count)
	endif
	let ctx.pg_height = (max_height < ctx.nrows)? max_height : ctx.nrows
	let ctx.pg_height = (min_height > ctx.pg_height)? min_height : ctx.pg_height
	let ctx.pg_size = ctx.pg_height * ctx.ncols
	let ctx.pages = []
endfunc


"----------------------------------------------------------------------
" vertical
"----------------------------------------------------------------------
function! s:layout_vertical(ctx, opts) abort
	let a:ctx.wincy = winheight(0)
endfunc


"----------------------------------------------------------------------
" layout init
"----------------------------------------------------------------------
function! starter#layout#init(ctx, opts, hspace, vspace) abort
	let a:ctx.wincx = a:hspace
	let a:ctx.wincy = a:vspace
	if a:ctx.vertical == 0
		call s:layout_horizon(a:ctx, a:opts)
	else
		call s:layout_vertical(a:ctx, a:opts)
	endif
endfunc



"----------------------------------------------------------------------
" fill a column
"----------------------------------------------------------------------
function! starter#layout#fill_column(ctx, opts, start, size, minwidth) abort
	let ctx = a:ctx
	let columns = []
	let index = a:start
	let endup = index + a:size
	let endup = (endup < len(ctx.keys))? endup : len(ctx.keys)
	let csize = 0
	while index < endup
		let item = ctx.items[ctx.keys[index]]
		let columns += [item.compact]
		let index += 1
	endwhile
	for text in columns
		let width = strwidth(text)
		let csize = (width > csize)? width : csize
	endfor
	let csize = (csize < a:minwidth)? a:minwidth : csize
	let index = 0
	while index < len(columns)
		let text = columns[index]
		let width = strwidth(text)
		if width < csize
			let columns[index] = text . repeat(' ', csize - width)
		endif
		let index += 1
	endwhile
	return columns
endfunc


