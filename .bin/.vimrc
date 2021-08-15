"-----------------------------------
"
" 文字
"
"-----------------------------------

" 読み込み時の文字コード
set encoding=utf-8
" 保存時の文字コード
set fileencoding=utf-8
" 読み込み時の文字コードの自動判別. 左側が優先される
set fileencodings=ucs-boms,utf-8,euc-jp,cp932
" 改行コードの自動判別. 左側が優先される
set fileformats=unix,dos,mac
" □や○文字が崩れる問題を解決
set ambiwidth=double

"-----------------------------------
"
" ステータスライン
"
"-----------------------------------
" ステータスラインを常に表示
set laststatus=2
" 現在のモードを表示
set showmode
" 打ったコマンドをステータスラインの下に表示
set showcmd
" ステータスラインの右側にカーソルの位置を表示する
set ruler

"-----------------------------------
"
" コマンドモード
"
"-----------------------------------
" コマンドモードの補完
set wildmenu
" 保存するコマンド履歴の数
set history=5000

"-----------------------------------
"
" タブ・インデント
"
"-----------------------------------
" タブ入力を複数の空白入力に置き換える
set expandtab
" 画面上でタブ文字が占める幅
set tabstop=4
" 連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set softtabstop=4
" 改行時に前の行のインデントを継続する
set autoindent
" 改行時に前の行の構文をチェックし次の行のインデントを増減する
set smartindent
" smartindentで増減する幅
set shiftwidth=4

"-----------------------------------
"
" 文字列検索
"
"-----------------------------------
" インクリメンタルサーチ. １文字入力毎に検索を行う
set incsearch
" 検索パターンに大文字小文字を区別しない
set ignorecase
" 検索パターンに大文字を含んでいたら大文字小文字を区別する
set smartcase
" 検索結果をハイライト
set hlsearch
" ESCキー2度押しでハイライトの切り替え
nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

"-----------------------------------
"
" カーソル
"
"-----------------------------------
" カーソルの左右移動で行末から次の行の行頭への移動が可能になる
set whichwrap=b,s,h,l,<,>,[,],~
" 行番号を表示
set number
" カーソルラインをハイライト
set cursorline

" 行が折り返し表示されていた場合、行単位ではなく表示行単位でカーソルを移動する
nnoremap j gj
nnoremap k gk
nnoremap <down> gj
nnoremap <up> gk

" バックスペースキーの有効化
set backspace=indent,eol,start

"-----------------------------------
"
" カッコ・タグの対応
"
"-----------------------------------
" 括弧の対応関係を一瞬表示する
set showmatch
" Vimの「%」を拡張する
source $VIMRUNTIME/macros/matchit.vim

"-----------------------------------
"
" マウスでカーソル移動とスクロール
"
"-----------------------------------
if has('mouse')
    set mouse=a
    if has('mouse_sgr')
        set ttymouse=sgr
    elseif v:version > 703 || v:version is 703 && has('patch632')
        set ttymouse=sgr
    else
        set ttymouse=xterm2
    endif
endif
