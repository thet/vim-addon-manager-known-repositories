" get list of all availible packages on www.vim.org
" The result can be pasted into
" plugin/vim-addon-manager-known-repositories.vim

" throws fine if end of scripts has been reached
fun! www_vim_org#Script(nr, cached)
  let nr = a:nr
  let page_url = 'http://www.vim.org/scripts/script.php?script_id='.nr
  let error = {'title2': 'error', 'script_nr': nr}

  if !exists('g:www_vim_org_cache')
    let g:www_vim_org_cache = {}
  endif

  if a:cached && has_key(g:www_vim_org_cache, page_url)
    let str = g:www_vim_org_cache[page_url]
    let shell_error1 = 0
  else
    let str = system('curl '.shellescape(page_url,":?='").' 2>/dev/null')
    let shell_error1 = v:shell_error
  endif

  if str =~ 'Vim Online Error' || shell_error1 != 0
   if (nr -1) > 2900 || shell_error1 != 0
    echo "end reached? script nr ".(nr -1)
      throw "fine"
    else
      return error
    endif
  endif

  let lines = split(str,"\n")

  let g:www_vim_org_cache[page_url] = str

  let title = matchstr(lines[5], '<title>\zs.*\ze -.*<\/title')

  while len(lines) > 0 && lines[0] !~ 'class="prompt">script type</td>'
    let lines = lines[1:]
  endwhile
  if (empty(lines))
    return error
  endif

  let type = matchstr(lines[1], 'td>\zs[^<]*\ze')

  while len(lines) > 0 && lines[0] !~ 'download_script.php'
    let lines = lines[1:]
  endwhile

  if (empty(lines))
    return error
  endif
  let url = 'http://www.vim.org/scripts/download_script.php?src_id='.matchstr(lines[0], '.*src_id=\zs\d\+\ze')
  let archive_name = matchstr(lines[0], '">\zs[^<]*\ze')
  let v = matchstr(lines[1], '<b>\zs[^<]*\ze')
  let date = matchstr(lines[2], '<i>\zs[^<]*\ze')
  let vim_version = matchstr(lines[3], 'nowrap>\zs[^<]*\ze')

  " remove spaces : and ' from names
  let title2=substitute(title,"[+:'()\\/]",'','g')
  let title2=substitute(title2," ",'_','g')
  " also remove trailing .vim
  let title2=substitute(title2,"\.vim$",'','g')

  return {
    \ 'type' : 'archive',
    \ 'archive_name' : archive_name,
    \ 'url' : url,
    \ 'version' : v,
    \ 'date' : date,
    \ 'vim_script_nr' : nr,
    \ 'script-type' : type,
    \ 'vim_version' : vim_version,
    \ 'title2' : title2
    \ } 
endf

" usage: insert mode: <c-r>=www_vim_org#List()
fun! www_vim_org#List()
  let nr=1
  let list = []

  while 1

    let nr = nr +1
    echo nr

    try
      let dict = www_vim_org#Script(nr, 1)
    catch /fine/
      return list
    endtry

    let title2 = dict['title2']
    unlet dict['title2']

    call add(list, "let s:plugin_sources['".title2."'] = ".string(dict))
  endwhile
  return list
endf




