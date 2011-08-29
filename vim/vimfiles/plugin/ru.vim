if exists("ruvim_loaded") | finish | endif
let ruvim_loaded = 1
scriptencoding utf-8
"if has("multi_lang")
"	"if has("gettext")
"        
"			set fileencodings=ucs-bom,utf-8,koi8-r,cp1251,cp866
"			set keymap=russian-jcukenwin
"			"language messages ru
"			set helplang=ru
"			"set langmenu=ru_ru
"		if has("Win32")
"			set encoding=utf-8
"			if has("gui")
"				set guifont=courier_new:h18:w9:b:cRUSSIAN
"				if has("multibyte")
"				else "no multibyte
"				endif
"			else "no gui
"				set termencoding=cp866
"			endif
"
"		elseif has("dos32")
"
"		elseif has("unix")
"			set encoding=koi8-r
"            set guifont=-misc-fixed-medium-r-normal--14-130-75-75-c-70-koi8-r
"		endif
"		set iminsert=0
"		set imsearch=0
"	"endif
"endif
set langmenu=en
"language messages none
let s:encodings = 'koi-8r cp1251 cp866 utf-7 utf-8 utf-16 utf-16le'
let s:enc_keys='kwd786l'
if has("menu")
	let s:rootmenu='&ru\.vim'
	let s:read_as='&ReRead\ as\ \.\.\.'
	let s:set_enc='&Set\ encoding\ \.\.\.'
	"exe 'menutrans '. s:rootmenu.' &ру\.вим'
	"echo 'menutrans '. s:rootmenu.'.'.s:read_as.'	Перечитать\ как\ \.\.\.'
	"exe 'menutrans '. s:rootmenu.'.'.s:read_as.'	Перечитать\ как\ \.\.\.'
	"exe 'menutrans '.s:rootmenu.'.'.s:read_as.' ddd'
	exe 'silent! aunmenu '.s:rootmenu
	exe 'amenu <silent> '.s:rootmenu.'.Set\ Encoding :call <SID>ReReadDialog()'
	"exe 'amenu <silent> '.s:rootmenu.'.'.s:read_as.'.&autodetect'.
	"			\' :call <SID>DetectEncoding("perl","ru","'.
	"			\substitute(s:encodings," ",",","g").
	"			\'")'
	"exe 'amenu <silent> '.s:rootmenu.'.'.s:read_as.'.&autodetect (ku)'.
	"			\' :call <SID>KuDetectEncoding("ru","'.
	"			\substitute(s:encodings," ",",","g").
	"			\'")'
	exe 'amenu <silent> '.s:rootmenu.'.'.s:read_as.'.dialog'.
				\' :call <SID>ReReadDialog()<CR>'
	exe 'amenu '.s:rootmenu.'.'.s:read_as.'.-Sep- :'
endif
let s:encodings = s:encodings . ' '
let s:enc_idx=0
let s:encodings_choices=''
while s:encodings != ''
	let s:current_enc = strpart(s:encodings, 0, stridx(s:encodings, ' '))
	let s:enc_key=strpart(s:enc_keys,s:enc_idx,1)
	let s:encodings{s:enc_idx} = s:current_enc
	let s:call_read_as=':call <SID>Read_as("'.s:current_enc.'")<CR>'
	let s:call_set_enc=':call <SID>Set_enc("'.s:current_enc.'")<CR>'
	exe 'nmap <silent> \r'.s:enc_key. ' '.s:call_read_as
	exe 'nmap <silent> \e'.s:enc_key. ' '.s:call_set_enc
	if has("menu")
		let s:menu_entry=substitute(s:current_enc,s:enc_key,'\&'.s:enc_key,'')
		exe 'amenu <silent> '.s:rootmenu.'.'.s:read_as.'.'.
					\s:menu_entry.'<Tab>\\r'.s:enc_key.
					\' '.s:call_read_as
		exe 'amenu <silent> '.s:rootmenu.'.'.s:set_enc.'.'.
					\s:menu_entry.'<Tab>\\e'.s:enc_key.
					\' '.s:call_set_enc
	endif
	let s:encodings_choices=s:encodings_choices.s:menu_entry."\n"
	let s:enc_idx =s:enc_idx+1
	let s:encodings = strpart(s:encodings, stridx(s:encodings, ' ') + 1)
endwhile
let s:encodings_choices=s:encodings_choices."&Cancel"
let s:encodings_cancel =s:enc_idx+1
if has ("statusline")
	if (0)
		let &statusline="%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ %{&fileencoding}"
		let &laststatus=2
	endif
	if(1)
let &rulerformat="%60(%{&fileencoding}%=%l\ %c(%v)\ |%04Bh\ @\ %o(%4(%p%%%))%)"
	endif
endif
if has('autocmd')
augroup ruvim 
autocmd!
"autocmd BufReadPost call <SID>DetectEncoding("perl","ru",substitute(s:encodings," ",",","g")
autocmd Syntax * if ( b:current_syntax == "help" )
			\|syn match helpHyperTextJump	"\\\@<!|[^"*|]\+|"
			\|syn match helpHyperTextEntry	"\*[^"*|]\+\*\s"he=e-1
			\|syn match helpHyperTextEntry	"\*[^"*|]\+\*$"
			\|endif
augroup END	
endif
fun! s:Read_as(enc)
	if !strlen(@%)| return| endif
	exe 'edit! ++enc=' . a:enc
endfun
fun! s:Set_enc(enc)
	let &fileencoding = a:enc
endfun
fun! s:ReReadDialog()
	if !strlen(@%)| return| endif
	if !exists("s:re_read_dialog")
		let s:re_read_dialog = "Select encoding"
	endif
	let default = 1
	let n = confirm(s:re_read_dialog, s:encodings_choices, default, "Question") - 1
	if n==s:encodings_cancel | return | endif
	if exists("s:encodings{n}") 
	call s:Read_as(s:encodings{n})
	echo s:encodings{n}
	endif
endfun
" http://iamphet.nm.ru/vim/encdetectpl.vim
" (C) Sergey Khorev
" Script for automatic detection of encoding
" Currently works only for russian
" Requires perl 5.8 or later
" (you can try 5.6.1 with package 'Encode' installed)
" The technology is similar to one used in FAR filemanager
" (http://www.farmanager.com) - character frequency distribution table
function! s:DetectEncoding(scrpt, lng, encs)
    " script language (currently only 'perl'),
    " language (currently only 'ru') 
    " and comma-separated list of possible encodings

    if has('perl') && tolower(a:scrpt) == 'perl' 
	if (!exists('g:DetectEncodingPerlDefined') 
		    \ || g:DetectEncodingPerlDefined == 0)
	    let g:DetectEncdingPerlDefined = 1

	    function! DetectEncodingPerl(lng, encs)
		perl << EOF
		#use strict; # doesn't work with Vim :(
		use Encode;

		sub DetectEncoding
		{
		    # dispersion (%), dist.table ref, dt encoding, 
		#			stat.table ref, list of encodings to try
		    my ($disp, $dt, $dte, $st, @encs) = @_;
		    my @encw; # weights of encodings
		    my $mc = 0; # maximum count

		    foreach (@$st)
		    {
			if (defined($_) && $mc < $_)
			{
			    $mc = $_;
			}
		    }

		    my $dv = $mc/254; # divisor
		    # Normalize @$st. Note: change $st!!!
		    foreach (@$st)
		    {
			if (defined($_))
			{
			    $_ = $_/$dv;
			    if ($_ > 254)
			    {
				$_ = 254;
			    }
			}
			else
			{
			    $_ = 0;
			}
		    }

		    my $mindev = 0xFFFFFFFF; # minimum deviation
		    foreach (@encs)
		    {
			my $edt = EncodeDistTable($dt, $dte, $_);
			my $dev = 0; # deviation

			for (my $i = 0; $i <= $#$st; $i++)
			{
			    my $dval = 0; # value from dist table
			    $dval = $edt->[$i] if defined($edt->[$i]);

			    $dev += ($st->[$i]-$dval)**2 unless ($dval == 0xFF);
			}
			push(@encw, $dev);
			if ($dev < $mindev)
			{
			    $mindev = $dev;
			}
		    }
		    my @detected; # list of possible encodings
		    for (my $i = 0; $i<=$#encw; $i++)
		    {
			if (($encw[$i]-$mindev)*100/$mindev < $disp)
			{
			    push(@detected, $encs[$i]);
			}
		    }
		    return @detected;
		}

		sub EncodeDistTable # convert dist.table to attempted encoding
		{
		    # dist.table ref, dist.table encoding, target encoding
		    my ($dt, $dte, $enc) = @_;
		    if ($dte eq $enc)
		    {
			return $dt;
		    }

		    my @edt; # target dist.table
		    $#edt = $#$dt; # grow it

		    for (my $i = 0; $i <= $#$dt; $i++) # $#$dt is maximum dt index
		    {
			# index in the new dist table: 
			my $ni = ord(encode($enc, decode($dte, chr($i))));
			$edt[$ni] = $dt->[$i];
		    }

		    return \@edt;
		}

		# Main program

		# Get arguments
		my ($succ, $lng) = VIM::Eval("a:lng");
		if ($succ)
		{
		    VIM::Msg($lng);
		}
		my $encs;
		my @enclist;
		($succ, $encs) = VIM::Eval("a:encs");
		if ($succ)
		{
		    @enclist = split(/\s*,\s*/, $encs);
		}

		# Get dist.table
		my $distenc;
		my $dist;

		if (lc($lang) == "russian" || lc($lang) == "ru")
		{
		    $distenc = "cp866";
		    $dist = [
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0x00,0xFF,0xFF,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0x00,0x00,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
	0xC0,0x27,0x68,0x26,0x48,0xBC,0x16,0x2C,0x98,0x18,0x54,0x72,0x4C,0x9B,0xFA,0x46,
	0x65,0x7A,0x8E,0x42,0x04,0x14,0x08,0x22,0x15,0x08,0x00,0x2C,0x28,0x09,0x0C,0x38,
	0xC7,0x25,0x68,0x24,0x44,0xCA,0x17,0x2B,0xAD,0x1C,0x4F,0x77,0x4C,0x9B,0xFE,0x44,
	0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
	0x73,0x77,0x94,0x42,0x05,0x13,0x0B,0x23,0x13,0x09,0x00,0x2F,0x30,0x06,0x0F,0x35,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0000
			    ];
		}
		
		my @st; # text statistics
		$#st = $#$dist; # grow it

		# Gather statistics
		foreach ($curbuf->Get(1, 100)) # detect by the first 100 lines
		{
		    foreach (unpack("C*", $_)) # get char codes
		    {
			$st[$_]++;
		    }
		}
		
		my @detected = DetectEncoding(1, $dist, $distenc, \@st, 
			    @enclist);

		# reopen file
		VIM::DoCommand(":e! ++enc=" . $detected[0]);
EOF
	    endfunction "DetectEncodingPerl
	endif "!exists(DetectEncodingPerlDefined)

	call DetectEncodingPerl(a:lng, a:encs)
    endif "has('perl')

endfunction "DetectEncoding 

