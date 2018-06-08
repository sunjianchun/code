#/bin/bash
cat << EOF > ~/.vimrc
let mapleader="'" " 定义<Leader>

syntax on " 开启自定义语法高亮

" set laststatus=2         " 总是显示状态栏
set number               " 显示行号

" 解决^[O延迟的问题
set noesckeys
set timeout timeoutlen=5000 ttimeoutlen=100

set nobomb               " 设置为无bom
set wildmenu             " 智能补全
set t_Co=256             " 配色方案
" set relativenumber       " 显示相对行号
set ambiwidth=double     " 显示中文引号
set ignorecase smartcase " 搜索小写内容时忽略大小写
set hlsearch             " 高亮搜索的关键字
set ruler                " 显示光标位置
set showcmd              " 显示正在输入的命令
set history=1000         " 设置历史记录数
set nocompatible         " 去掉vi一致性模式
set splitright           " 默认在右侧分屏
set autoread             " 自动读取外部变更
set cursorline           " 高亮行
set cursorcolumn         " 高亮列

set softtabstop=4        " 把连续数量的空格视为一个制表符
set shiftwidth=4         " 设置格式化时制表符占用空格数
set tabstop=4            " 设置编辑时制表符占用空格数
set expandtab            " 默认使用space
set smartindent          " 开启新行时使用智能自动缩进

set fencs=utf-8
set encoding=utf-8
set fileencodings=utf-8
set fileencoding=utf-8
set termencoding=utf-8

set background=dark
let g:solarized_contrast="high"
let g:solarized_visibility="high"

if strlen(globpath(&rtp, "colors/solarized.vim")) > 0
	colorscheme solarized
endif

" 行号宽度
set numberwidth=3

" 去掉行号背景颜色
hi LineNr ctermbg=NONE

" 去掉分屏时分割线的背景
hi VertSplit ctermbg=none

" ----------------------------------------------
filetype off

call plug#begin('~/.vim/plugged')
Plug 'altercation/vim-colors-solarized', {'do': 'mkdir -p ~/.vim/colors; mv colors/solarized.vim ~/.vim/colors/.'}
Plug 'junegunn/vim-easy-align'
Plug 'fatih/vim-go'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'zivyangll/git-blame.vim'
call plug#end()

filetype plugin indent on 

" ----------------------------------------------
" 格式化工具
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" go支持
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_types = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_fmt_command = "goimports"

" CtrlP
let g:ctrlp_map = '<leader>t'
let g:ctrlp_cmd = 'CtrlP'
map <leader>f :CtrlPMRU<CR>
map <leader>j :CtrlPBuffer<CR>
let g:ctrlp_working_path_mode=0
let g:ctrlp_match_window_bottom=1
let g:ctrlp_max_height=15
let g:ctrlp_match_window_reversed=0
let g:ctrlp_mruf_max=500
let g:ctrlp_follow_symlinks=1
"设置搜索时忽略的文件
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn|rvm)$',
    \ 'file': '\v\.(exe|so|dll|zip|tar|tar.gz|pyc)$',
    \ }
" ultisnips
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
let g:UltiSnipsEditSplit="vertical"

" ----------------------------------------------
" 返回上一个文件
nmap <Leader>b <C-^>

" 切换分屏快捷键
nmap <C-w>fl <C-w>l<C-w>\|zz
nmap <C-w>fh <C-w>h<C-w>\|zz
nmap <C-w>dl <C-w>l<C-w>c<C-w>\|zz
nmap <C-w>dh <C-w>h<C-w>c<C-w>\|zz
EOF

yum install vim -y

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
>/tmp/test_file
vim -E -s /tmp/test_file <<-EOF
:PlugInstall
:update
:quit
EOF
rm /tmp/test_file
