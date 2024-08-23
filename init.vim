let mapleader = " "
let g:netrw_banner = 0
let g:netrw_liststyle = 3
"let g:netrw_winsize = 25
let g:netrw_preview = 1

syntax on

set nu
set rnu
set expandtab ts=2 sw=2 ai

" Ignore these file patterns when using filename completion
set wildignore+=*/tmp/*,*.so,*.swp,*.zip

" Enable command-line completion with a menu of choices
set wildmenu

" Allow the execution of a local vimrc file in a directory
set exrc

" Secure mode: Disallow potentially unsafe commands in local vimrc files
set secure

" Set the background color scheme to dark
set background=dark

" Enable support for 256 colors in the terminal
set t_Co=256

" Always display the status line
set laststatus=2

" Customize the status line to show the buffer number, window number, file name, line number, column number, and modified flag
set statusline=[%n][%{winnr()}]-%f:%l:%c\ %m

" Set the search path for files to the current directory and all subdirectories
set path=$PWD/**

" Switch off Vi compatibility mode, enabling Vim-specific features
set nocompatible

" Remove 'i' from the 'complete' option, so that included files are not scanned for completions
set complete-=i

" Enable persistent undo, allowing undo history to be saved to a file
set undofile

" Set the directory where backup files will be stored
set backupdir=/tmp/nvim/

" Set the directory where swap files will be stored
set directory=/tmp/nvim/

" Set the directory where undo files will be stored
set undodir=/tmp/nvim/

set splitbelow
set splitright

filetype off
set rtp+=/home/raman/.vim/bundle/Vundle.vim/
call vundle#begin()
  "Package management
  Plugin 'VundleVim/Vundle.vim'

  " Programming Languages
  Plugin 'elixir-editors/vim-elixir'
  Plugin 'pangloss/vim-javascript'
  Plugin 'mxw/vim-jsx'
  Plugin 'kchmck/vim-coffee-script'

  "Zen Mode
  Plugin 'folke/zen-mode.nvim'

  "Matchit Functionality
  Plugin 'andymass/vim-matchup'

  "File Navigation
  Plugin 'junegunn/fzf'
  Plugin 'junegunn/fzf.vim'
  Plugin 'preservim/nerdtree'

  "Theme Configuration
  Plugin 'catppuccin/nvim'

  "Treesitter Configuration"
  Plugin 'nvim-treesitter/nvim-treesitter'
  Plugin 'nvim-treesitter/nvim-treesitter-textobjects'

  " LSP Configuration
  Plugin 'neovim/nvim-lspconfig'
call vundle#end()
filetype indent plugin on
"runtime  macros/matchit.vim
packadd! matchit

" Set syntax of hamlc files to haml
au BufNewFile,BufRead *.hamlc set ft=haml

match ExtraWhitespace /\s\+$/

" Set colorscheme
colorscheme catppuccin-mocha
" when in diff mode set colorscheme to industry

if &diff
  colorscheme catppuccin-mocha
endif

" setup markdown to fold by indentation
augroup markdown_folding
  autocmd!
  autocmd FileType markdown call SetupMarkdownFolding()
  autocmd FileType markdown setlocal shiftwidth=2 tabstop=2
augroup END

" Functions
function! MaxWindow()
  wincmd _
  wincmd |
endfunction

function! FormatJSON()
  execute '%!python -m json.tool'
endfunction

function! FormatXML()
  execute '%!xmllint -format -'
endfunction

function! FormatSQL()
  execute '%!sqlformat -r -'
endfunction

function! VisualSelection(position1, position2)
  call setpos('.', a:position1)
  normal! v
  call setpos('.', a:position2)
endfunction

function GetStringRelativeToCursor(relnumber)
  let start=0
  let end = col('.') + a:relnumber - 1
  return getline('.')[start:end]
endfunction

function! CountPatternInString(string, pattern)
  let split_list = split(a:string, a:pattern, 1)
  return len(split_list) - 1
endfunction

function! IsEven(number)
  return a:number%2 == 0
endfunction

function! IsCursorBetweenPattern(pattern)
  let pos_before = searchpos(a:pattern, 'bn', line('.'))
  let pos_after = searchpos(a:pattern, 'zn', line('.'))
  return pos_before != [0,0] && pos_after != [0,0] && !IsCursorOverPattern(a:pattern)
endfunction

function! IsCursorOverPattern(pattern)
  let pos_before = searchpos(a:pattern, 'bnc', line('.'))
  let pos_before_end = searchpos(a:pattern, 'bnce', line('.'))
  let curindex = getcurpos()[2]
  let pos_after = searchpos(a:pattern, 'znc', line('.'))
  return pos_before != [0,0] && (pos_before == pos_after || (curindex >= pos_before[1] && pos_before_end[1] >= curindex))
endfunction

function! IsCursorOverBeginPattern(pattern)
  let str_b_cur = GetStringRelativeToCursor(-1)
  let ptrn_cnt_b_cur = CountPatternInString(str_b_cur, a:pattern)
  return IsEven(ptrn_cnt_b_cur) && IsCursorOverPattern(a:pattern)
endfunction

function! IsCursorOverEndPattern(pattern)
  let str_b_cur = GetStringRelativeToCursor(-1)
  let ptrn_cnt_b_cur = CountPatternInString(str_b_cur, a:pattern)
  return !IsEven(ptrn_cnt_b_cur) && IsCursorOverPattern(a:pattern)
endfunction

function! SelectAroundMatchingPattern(pattern)
  let init_pos = getcurpos()
  if IsCursorBetweenPattern(a:pattern)
    call searchpos(a:pattern, 'b', line('.'))
    let begin_pos = getcurpos()
    call setpos('.', init_pos)
    call searchpos(a:pattern, 'ze', line('.'))
    let end_pos = getcurpos()
    call VisualSelection(begin_pos, end_pos)
  elseif IsCursorOverBeginPattern(a:pattern)
    call searchpos(a:pattern, 'bc', line('.'))
    let begin_pos = getcurpos()
    let pos_after = searchpos(a:pattern, 'z', line('.'))
    if pos_after != [0,0]
      call searchpos(a:pattern, 'ze', line('.'))
      let end_pos = getcurpos()
      call VisualSelection(begin_pos, end_pos)
    endif
  elseif IsCursorOverEndPattern(a:pattern)
    call searchpos(a:pattern, 'bc', line('.'))
    call searchpos(a:pattern, 'ze', line('.'))
    let end_pos = getcurpos()
    call searchpos(a:pattern, 'b', line('.'))
    call searchpos(a:pattern, 'b', line('.'))
    let begin_pos = getcurpos()
    call VisualSelection(begin_pos, end_pos)
  endif
endfunction

function! SelectBetweenMatchingPattern(pattern)
  let init_pos = getcurpos()
  if IsCursorBetweenPattern(a:pattern)
    call searchpos(a:pattern, 'be', line('.'))
    normal! l
    let begin_pos = getcurpos()
    call setpos('.', init_pos)
    call searchpos(a:pattern, 'z', line('.'))
    normal! h
    let end_pos = getcurpos()
    call VisualSelection(begin_pos, end_pos)
  elseif IsCursorOverBeginPattern(a:pattern)
    call searchpos(a:pattern, 'bc', line('.'))
    call searchpos(a:pattern, 'ce', line('.'))
    normal! l
    let begin_pos = getcurpos()
    let pos_after = searchpos(a:pattern, 'z', line('.'))
    if pos_after != [0,0]
      normal! h
      let end_pos = getcurpos()
      call VisualSelection(begin_pos, end_pos)
    endif
  elseif IsCursorOverEndPattern(a:pattern)
    call searchpos(a:pattern, 'bc', line('.'))
    normal! h
    let end_pos = getcurpos()
    call searchpos(a:pattern, 'be', line('.'))
    normal! l
    let begin_pos = getcurpos()
    call VisualSelection(begin_pos, end_pos)
  endif
endfunction!




function! GitAdd(...)
  let target_file= expand('%')
  execute 'silent' '!' 'git' 'add' target_file
endfunction

function! SetupMarkdownFolding()
  setlocal foldmethod=indent
  setlocal foldcolumn=1
endfunction

function! OpenRailsRspec()
  let spec_file = SpecFile()
  let spec_dir = SpecDir()
  call OpenFile(spec_file)
endfunction

function! OpenFile(file)
  if filereadable(a:file)
    let bufmatcher = "^".a:file
    if bufwinnr(bufmatcher) > 0
      return GoToWindow(bufwinnr(bufmatcher))
    endif
    if bufexists(a:file)
      execute 'vert sb' a:file
    else
      call MkDirAndOpenFile(a:file)
    endif
  else
    return MkDirAndOpenFile(a:file)
  endif
endfunction

function GoToWindow(window_number)
  execute "normal! ".a:window_number."\<C-W>\<C-W>"
endfunction

function! MkDirAndOpenFile(file)
  let directory = GetDirectoryForFile(a:file)
  execute 'silent' '!' 'mkdir' '-p' directory
  execute 'vert' 'new' a:file
  execute 'redraw!'
endfunction

function! GetDirectoryForFile(file)
  let directory = substitute(a:file, '\/\w\+\(\.\w\+\)\?$', '','')
  if directory == a:file
    return ''
  else
    return directory
  endif
endfunction

function! GoToRailsRspec()
  let spec_file = SpecFile()
  let spec_dir = SpecDir()
  execute 'e' spec_file
endfunction

function! RunLastSpecCommand()
  execute g:last_spec_command
endfunction

function! ExecuteSpecCommmand(command)
  call SetLastSpecCommand(a:command)
  execute a:command
endfunction

function! SetLastSpecCommand(command)
  let g:last_spec_command = a:command
endfunction

function! RunAllSpecs()
  let command =  "bel term " . RspecCommand()
  call ExecuteSpecCommmand(command)
endfunction

function! RunAllFailures()
  let command = "bel term " . RspecCommand() . " --only-failures"
  call ExecuteSpecCommmand(command)
endfunction

function! RunRailsRspec()
  let command = "bel term " . RspecCommand() . " " . SpecFile()
  call ExecuteSpecCommmand(command)
endfunction

function! RspecCommand()
  let g:rspec_command = get(g:, 'rspec_command', "bundle exec rspec")
  return g:rspec_command
endfunction

function! RunRailsRspecFailure()
  let command = "bel term " . RspecCommand() . " " . SpecFile() . " --only-failures"
  call ExecuteSpecCommmand(command)
endfunction

function! RunNearSpec()
  let near_spec = SpecFile() . ":" . line(".")
  let command = "bel term " . RspecCommand() . " " . near_spec
  call ExecuteSpecCommmand(command)
endfunction

function! SpecDir()
  return substitute(SpecFile(), '\(spec.*\)\(\/.*rb$\)', '\1', '')
endfunction

function! SpecFile()
  let current_file = @%
  if current_file =~ "_spec.rb"
    let spec_file = current_file
  else
    let spec_file = substitute(current_file, '^app\/', 'spec/','')
    let spec_file = substitute(spec_file, '\.rb$', '_spec.rb','')
  end
  return spec_file
endfunction

function! OpenRailsRspecTarget()
  let target_file = SpecTargetFile()
  let target_dir = SpecTargetDir()
  call OpenFile(target_file)
endfunction

function! GoToRailsRspecTarget()
  let target_file = SpecTargetFile()
  execute 'e' target_file
endfunction

function! SpecTargetFile()
  let current_file = @%
  let target_file = substitute(current_file, '^spec\/', 'app/','')
  let target_file = substitute(target_file, '_spec\.rb$', '\.rb', '')
  let target_file = substitute(target_file, '^spec\/', 'app/','')
  return target_file
endfunction

function! SpecTargetDir()
  return substitute(SpecTargetFile(), '\(app.*\)\(\/.*rb$\)', '\1', '')
endfunction

function! SpecFileExist()
  let spec_file = SpecFile()
  if filereadable(expand(spec_file))
    echo expand(spec_file).' exists'
  else
    echohl ErrorMsg
    echo 'WARNING: '.expand(spec_file).' does not exist'
    echohl None
  endif
endfunction

function! Ctags()
  let ctags_command = get(g:, 'ctags_command', 'ctags -R')
  let command = "bel term " . ctags_command
  execute command
endfunction!

" Commands
command!OpenSpec call OpenRailsRspec()
command!GoToSpec call GoToRailsRspec()
command!RunFileSpec call RunRailsRspec()
command!RunFileSpecFailure call RunRailsRspecFailure()
command!RunNearSpec call RunNearSpec()
command!RunAllSpecs call RunAllSpecs()
command!RunAllFailures call RunAllFailures()
command!RunLastSpecCommand call RunLastSpecCommand()
command!OpenSpecTarget call OpenRailsRspecTarget()
command!GoToSpecTarget call GoToRailsRspecTarget()
command!SpecFileExist call SpecFileExist()
command!CopyFileToClipBoard normal gg"+yG
command!CopyFileNameToClipBoard execute "let @+=@%"
command!MaxWindow call MaxWindow()
command!FormatJSON call FormatJSON()
command!FormatSQL call FormatSQL()
command!FormatXML call FormatXML()
command!Ctags call Ctags()
command!GitAdd call GitAdd()


" normal mode remappings
nnoremap <leader>ga :GitAdd<cr>
nnoremap <leader>q :qa<cr>
nnoremap Y y$
nnoremap <leader>f :GFiles<cr>
nnoremap <leader>t :NERDTreeToggle<cr>
nnoremap <leader>rs :RunFileSpec<cr>
nnoremap <leader>rl :RunLastSpecCommand<cr>
nnoremap <leader>ras :RunAllSpecs<cr>
nnoremap <leader>raf :RunAllFailures<cr>
nnoremap <leader>rn :RunNearSpec<cr>
nnoremap <leader>rf :RunFileSpecFailure<cr>
nnoremap <leader>rrr :RunRailsRunner<cr>
nnoremap <leader>osf :OpenSpec<cr>
nnoremap <leader>ost :OpenSpecTarget<cr>
nnoremap <leader>gsf :GoToSpec<cr>
nnoremap <leader>gst :GoToSpecTarget<cr>
nnoremap <leader>vc :ViewChanges<cr>
nnoremap <leader>ob o<Esc>k
nnoremap <leader>oa O<Esc>j
nnoremap <C-W>m :MaxWindow<cr>

""---Text Object Mappings
onoremap <silent> i\| :<C-u> call SelectBetweenMatchingPattern('\|')<cr>
onoremap <silent> a\| :<C-u> call SelectAroundMatchingPattern('\|')<cr>
onoremap <silent> i* :<C-u> call SelectBetweenMatchingPattern('\*')<cr>
onoremap <silent> a* :<C-u> call SelectAroundMatchingPattern('\*')<cr>
onoremap <silent> i** :<C-u> call SelectBetweenMatchingPattern('\*\*')<cr>
onoremap <silent> a** :<C-u> call SelectAroundMatchingPattern('\*\*')<cr>
onoremap <silent> i_ :<C-u> call SelectBetweenMatchingPattern('_')<cr>
onoremap <silent> i__ :<C-u> call SelectBetweenMatchingPattern('__')<cr>
onoremap <silent> a__ :<C-u> call SelectAroundMatchingPattern('__')<cr>
onoremap <silent> i~~ :<C-u> call SelectBetweenMatchingPattern('\~\~')<cr>
onoremap <silent> a~~ :<C-u> call SelectAroundMatchingPattern('\~\~')<cr>
onoremap <silent> i/ :<C-u> call SelectBetweenMatchingPattern('/')<cr>
onoremap <silent> a/ :<C-u> call SelectAroundMatchingPattern('/')<cr>
""---Insert mode mappings

"Quickly insert ruby method
"inoremap <C-@>d def<cr>end<Esc>kA<space>
"inoremap <C-@>c class<cr>end<Esc>kA<space>
"inoremap <C-@>m module<cr>end<Esc>kA<space>
"inoremap <C-@>b <space>do<cr>end<Esc>kA
"inoremap <F5> <C-R>=strftime("%c")<cr>-
lua <<EOF
vim.api.nvim_set_keymap('i', '<C-Space>d', 'def\nend<Esc>kA ', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-Space>c', 'class\nend<Esc>kA ', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-Space>m', 'module\nend<Esc>kA ', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-Space>b', ' do\nend<Esc>kA', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<F5>', '<C-R>=strftime("%c")<CR>-', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-Space>l', 'console.log()<Esc>i', { noremap = true, silent = true })
EOF


"Treesitter Config
lua <<EOF
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "javascript", "ruby"},

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    -- disable = { "c", "rust" },
    -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
    -- disable = function(lang, buf)
    --     local max_filesize = 100 * 1024 -- 100 KB
    --     local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
    --     if ok and stats and stats.size > max_filesize then
    --         return true
    --     end
    -- end,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = false,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["as"] = "@scope",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
      },

      -- You can choose the select mode (default is charwise 'v')
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * method: eg 'v' or 'o'
      -- and should return the mode ('v', 'V', or '<c-v>') or a table
      -- mapping query_strings to modes.
      selection_modes = {
        ['@parameter.outer'] = 'v', -- charwise
        ['@function.outer'] = 'V', -- linewise
        ['@class.outer'] = '<c-v>', -- blockwise
      },
      -- If you set this to `true` (default is `false`) then any textobject is
      -- extended to include preceding or succeeding whitespace. Succeeding
      -- whitespace has priority in order to act similarly to eg the built-in
      -- `ap`.
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * selection_mode: eg 'v'
      -- and should return true or false
      include_surrounding_whitespace = false,
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]b"] = "@block.outer",
      },
      goto_next_end = {
        ["]B"] = "@block.outer",
      },

    },
    matchup = {
      enable = true,
    },
  },
}
EOF

" LSP Configuration
lua <<EOF
local function lsp_keymaps(bufnr)
  local opts = { noremap = true, silent = true }

  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'grn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gra', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'grr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gra', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  
  vim.api.nvim_buf_set_keymap(bufnr, 'i', '<C-S>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    lsp_keymaps(bufnr)
  end,
})
EOF
