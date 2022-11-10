
""" --- vim-plug plugins
call plug#begin()

" Markdown Support
Plug 'preservim/vim-markdown'

" Indent Line Markings
Plug 'Yggdroot/indentLine'

" Linting
" pip install --user yamllint
Plug 'dense-analysis/ale'

call plug#end()

""" Markdown Settings
"
" Disable Markdown Folding
let g:vim_markdown_folding_disabled = 1
" Allow YAML Front Matter Highlighting
let g:vim_markdown_frontmatter = 1
" Allow TOML Front Matter Highlighting
let g:vim_markdown_toml_frontmatter = 1
" Allow JSON Front Matter Highlighting
let g:vim_markdown_json_frontmatter = 1
" Set list indent to 2
let g:vim_markdown_new_list_item_indent = 2
" Auto-write when following link
let g:vim_markdown_autowrite = 1
" Do not require .md extensions for Markdown links
let g:vim_markdown_no_extensions_in_markdown = 1

""" --- YAML Settings
set tabstop=2 softtabstop=2 shiftwidth=2
set expandtab
set number ruler
set autoindent smartindent
syntax enable
filetype plugin indent on
