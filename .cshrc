# Sean's .cshrc file. Why? 'cause bash(1) sucks and you won't look back once
# you make the switch. Use sh(1) for scripts and tcsh(1) for your day-to-day
# shell.
#
# Can be installed per-user at ~/.cshrc or system-wide at /etc/csh.cshrc
#
# Check out http://tcshrc.sf.net/ for more ideas.
#
# Updates available via:
#
# fetch -o ~/.cshrc.new https://github.com/sean-/cshrc/raw/master/.cshrc
# diff -u ~/.cshrc ~/.cshrc.new
# mv -f ~/.cshrc.new ~/.cshrc

# UTF-8 or go home.
setenv LC_TYPE en_US.utf-8

onintr -

### Set various path bits
if ( ! $?newpath ) set newpath
foreach d (/usr/local/sbin /opt/local/sbin /usr/local/bin /opt/local/bin $HOME/sbin $HOME/bin /usr/bin /usr/sbin /bin /sbin $path)
	if ( -d $d ) then
		set -f newpath = ( $newpath $d )
	endif
end
set path = ( $newpath )
unset d
unset newpath

# Skip to the end if we're not an interactive shell
if (! $?prompt) goto end

### Handle various interactive components

### Begin the autohost completion thang
set noglob
if ( ! $?hosts ) set hosts
if ( ! $?ssh_ports ) set ssh_ports

foreach f ($HOME/.hosts /usr/local/etc/csh.hosts $HOME/.rhosts /etc/hosts.equiv)
	if ( -r $f && ! -z $f ) then
		set hosts = ($hosts `grep -v "+" $f | grep -E -v "^#" | awk '{print $1}'`)
	endif
end

if ( -s $HOME/.netrc ) then
	set f=`awk '/machine/ { print $2 }' < $HOME/.netrc` >& /dev/null
	set hosts=($hosts $f)
endif

# auto-complete hosts. Run perl twice... easier to have two one-liners
# than try and jam it all together in to a single ball of nastiness.
foreach f (/etc/ssh/known_hosts /etc/ssh_known_hosts $HOME/.ssh/known_hosts )
	if ( -r $f && ! -z $f ) then
		# Grab every line that begins with a [
		set ssh_hosts=`grep '^\[' ${HOME}/.ssh/known_hosts | perl -p -e 's#^\[([^\]]+)\].*$#$1\n#gos'` >& /dev/null
		set -f hosts=($hosts $ssh_hosts)

		set ssh_hosts=`grep -v '^\[' ${HOME}/.ssh/known_hosts | perl -p -e 's#^([^\s,]+).*$#$1\n#gos'` >& /dev/null
		set -f hosts=($hosts $ssh_hosts)
		unset ssh_hosts

		# Now snag random ssh ports
		set tmp_ports=`grep '^\[' ${HOME}/.ssh/known_hosts | perl -p -e 's#^\[[^\]]+\]:?(\d+|).*$#$1\n#gos'` >& /dev/null
		set -f ssh_ports=($ssh_ports $tmp_ports)
		unset tmp_ports
	endif
end
unset f
unset noglob
### End autohost-ification foo

# OS-specific aliases. Be sure to copy and port aliases on new OS types.
switch ($OSTYPE)
case "freebsd*":
case "FreeBSD*":
	alias altq_see pfctl -vvsq
	alias pflog tcpdump -X -vvv -n -e -ttt -i pflog0

case "darwin*":
	# FreeBSD's ls(1) uses the -G flag to enable color
	alias ll ls -lAG
	breaksw
default:
	alias ll ls -lA --color=auto
	breaksw
endsw
alias rm rm -i
alias cp cp -i
alias mv mv -i
alias find.tcsh-sourced find . -type f -a \\\( -name '.enter.tcsh' -o -name '.exit.tcsh' -o -name '.site.tcsh' -o -name '.local.tcsh' \\\)
alias fs fossil
alias emacs emacs --no-splash
alias dmalloc 'eval `\dmalloc -C \!*`'

# mmm... Kerberos
alias kscp scp -o GSSAPIAuthentication=yes -o GSSAPIDelegateCredentials=yes
alias kssh ssh -o GSSAPIAuthentication=yes -o GSSAPIDelegateCredentials=yes

# Change the behavior of the shell/environment based on the current
# directory. The "-P22: file == '0'" bits check to make sure group and other
# don't have write perms. -o = we're the owner. To test this out:
#
# echo 'echo Entering src! at $PWD' >> src/.enter.tcsh
# echo 'setenv SRC_ENV in_src_true' >> src/.enter.tcsh
# echo 'unsetenv SRC_ENV' >> src/.exit.tcsh
# cd src
# env | grep SRC_ENV
# cd ..
# env | grep SRC_ENV
#
# Use the `filetest` builtin to test the various 'File inquiry operators'
# listed in tcsh(1). Very handy. E.g.
#
# % filetest -P77: /tmp/tmp.${USER}
# % filetest -P22: .enter.tcsh
alias cwdcmd 'if (-o .enter.tcsh && -P22: .enter.tcsh == "0") source .enter.tcsh'
alias popd 'if ("\!*" == "" && -o .exit.tcsh && -P22: .exit.tcsh == "0") source .exit.tcsh; ""popd \!*'
alias cd 'if (-o .exit.tcsh && -P22: .exit.tcsh == "0") source .exit.tcsh; chdir \!*'
alias pushd 'if (-o .exit.tcsh && -P22: .exit.tcsh == "0") source .exit.tcsh; ""pushd \!*'



# An interactive shell -- set some stuff up
set autocorrect
set autoexpand
set autolist
#set autologout=15 # Uncomment to autologout after 15min
set color
set colorcat
set complete = 'enhance'
set correct = 'all'
set echo_stype = 'both'
set filec
set fignore = (\~ .bak .class CVS .o .pyc .svn)
set histdup = 'erase'
set histfile = ~/.history
set history = 10000
set implicitcd
set listjobs = long

# I like having a temp directory that I can stash things in knowing that its
# contents *will* be blown away. Significantly helps reduce disk clutter. Do
# not use ~/tmp/ for sensitive material that needs to be securely deleted via
# `rm -P`, shred(1) or srm(1).
/bin/mkdir -pm 0700 /tmp/tmp.${USER}
if ( -o /tmp/tmp.${USER} && -P77: /tmp/tmp.${USER} == "0" ) then
  if ( ! -l ~/tmp ) /bin/ln -sf /tmp/tmp.${USER} ~/tmp
endif
# Check to make sure someone didn't exploit a race condition
if ( ! -o /tmp/tmp.${USER} || ! -P77: /tmp/tmp.${USER} == "0" ) then
  /bin/rm -f ~/tmp
  echo "DANGER! DANGER! DANGER! Someone changed the mask or user of /tmp/tmp.${USER} during login! Removed ~/tmp shortcut as a precaution. Be careful on this system. You have been warned."
endif

if ( -d ~/Mail/inbox/new/ ) then
	set mail = ~/Mail/inbox/new/
endif

#set nobeep
set printexitvalue
set promptchars = '%#'
set prompt = "%T %B%n%b@%m %# %L"
# When horizontal space is a premium, not vertical space:
# set prompt='%B%n%b@%U%m%u %S%/%s\
# %# '
set prompt3="CORRECT> %B%R%b (y|n|e|a)?"
set rmstar
# There are days when I like having a prompt to the right of my cursor.
#set rprompt = "%~"
set savehist = 10000 merge
set symlinks = 'chase'
set time=(8 "\
Time spent in user mode   (CPU seconds) : %Us\
Time spent in kernel mode (CPU seconds) : %Ss\
Total time                              : %Es\
CPU utilization (percentage)            : %P\
Times the process was swapped           : %W\
Times of major page faults              : %F\
Times of minor page faults              : %R")
set watch=(0 any any)
set who="%n has %a %l from %M."

if ( $?tcsh ) then
	bindkey "^W" backward-delete-word
	bindkey -k up history-search-backward
	bindkey -k down history-search-forward
endif

# I program using emacs and edit checkins or system files with vi(1). As
# such, I don't set an EDITOR variable globally. See the .enter.tcsh files
# below.
setenv SVN_EDITOR vi
setenv CVS_RSH ssh

# For tcsh's builtin ls command, ls-F. See LS_COLORS in tcsh(1) for details.
set noglob
set base_colors = 'no=00:fi=00:di=01;34:or=05:41:ln=01;36:pi=40;33:so=40;33:bd=40;33:cd=40;33:ex=01;32'
# Executable scripts
set lsexts = (js lua php pl py rb sh)
set lscolor = '00;32'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# Source files
set lsexts = (c cc cpp h hh java js lua php pl pm rb sh)
set lscolor = '00;33'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# Archive files
set lsexts = (arj bz2 class deb gz pkg rar rpm tar tgz xz z zip Z)
set lscolor = '00;31'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# Audio files
set lsexts = (mp3 mp4a ogg wav)
set lscolor = '00;33'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# Image files
set lsexts = (bmp gif jpeg jpg pic png xbm xcf xpm xwd)
set lscolor = '00;35'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# Video files
set lsexts = (avi flac mpeg mpg)
set lscolor = '00;36'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# Doc files
set lsexts = (abw doc gnumeric htm html pdf ps rtf tex txt xls)
set lscolor = '01;37'
foreach lsext (${lsexts})
    set base_colors = "${base_colors}:*.${lsext}=${lscolor}"
end

# tcsh(1)'s colors
setenv LS_COLORS "${base_colors}"
# ls(1)'s colors
setenv LSCOLORS 'exfxcxdxbxegedabagacad'
unset base_colors
unset lsexts
unset lscolor
set color = (ls-F)
alias ls "ls-F"



# Begin the auto-complete section for commands
set noglob

# Set various lists of commands/options.
set cvs_cmds = (add ad new admin adm rcs annotate ann checkout co get commit ci com diff di dif export exp ex history hi his import im imp log lo login logon lgn ls dir list rannotate rann ra rdiff patch pa release re rel remove rm delete rlog rl rls rdir rlist rtag rt rfreeze status st stat tag ta freeze update up upd version ve ver)
set fossil_cmds = (add co info rename ticket addremove commit init revert timeline all configuration leaves rm ui annotate deconstruct ls scrub undo artifact delete merge search unset bisect descendants mv server update branch diff new settings user cgi export open sha1sum version changes extras pull sqlite3 wiki checkout finfo push stash zip ci gdiff rebuild status clean help reconstruct sync clone http redo tag close import remote-url tarball)
set git_cmds = (add gui reflog add--interactive gui--askpass relink am hash-object remote annotate help remote-ftp apply http-backend remote-ftps archimport http-fetch remote-http archive http-push remote-https bisect imap-send remote-testgit bisect--helper index-pack repack blame init replace branch init-db repo-config bundle instaweb request-pull cat-file log rerere check-attr lost-found reset check-ref-format ls-files rev-list checkout ls-remote rev-parse checkout-index ls-tree revert cherry mailinfo rm cherry-pick mailsplit send-email citool merge send-pack clean merge-base shell clone merge-file shortlog commit merge-index show commit-tree merge-octopus show-branch config merge-one-file show-index count-objects merge-ours show-ref cvsexportcommit merge-recursive stage cvsimport merge-resolve stash cvsserver merge-subtree status daemon merge-tree stripspace describe mergetool submodule diff mktag svn diff-files mktree symbolic-ref diff-index mv tag diff-tree name-rev tar-tree difftool notes unpack-file difftool--helper pack-objects unpack-objects fast-export pack-redundant update-index fast-import pack-refs update-ref fetch patch-id update-server-info fetch-pack peek-remote upload-archive filter-branch prune upload-pack fmt-merge-msg prune-packed var for-each-ref pull verify-pack format-patch push verify-tag fsck quiltimport web--browse fsck-objects read-tree whatchanged gc rebase write-tree get-tar-commit-id rebase--interactive grep receive-pack)
set ssh_opts = (AddressFamily BatchMode BindAddress ChallengeResponseAuthentication CheckHostIP Cipher Ciphers ClearAllForwardings Compression CompressionLevel ConnectionAttempts ConnectTimeout ControlMaster ControlPath DynamicForward EscapeChar ExitOnForwardFailure ForwardAgent ForwardX11 ForwardX11Trusted GatewayPorts GlobalKnownHostsFile GSSAPIAuthentication GSSAPIDelegateCredentials HashKnownHosts Host HostbasedAuthentication HostKeyAlgorithms HostKeyAlias HostName IdentityFile IdentitiesOnly KbdInteractiveDevices LocalCommand LocalForward LogLevel MACs NoHostAuthenticationForLocalhost NumberOfPasswordPrompts PasswordAuthentication PermitLocalCommand Port PreferredAuthentications Protocol ProxyCommand PubkeyAuthentication RekeyLimit RemoteForward RhostsRSAAuthentication RSAAuthentication SendEnv ServerAliveInterval ServerAliveCountMax SmartcardDevice StrictHostKeyChecking TCPKeepAlive Tunnel TunnelDevice UsePrivilegedPort User UserKnownHostsFile VerifyHostKeyDNS VisualHostKey XAuthLocation)
set sv_cmds = (status up down once pause cont hup alarm interrupt quit 1 2 term kill exit start stop restart shutdown force-stop force-reload force-restart force-shutdown check)
set svn_cmds = (add blame praise annotate ann cat changelist cl checkout co cleanup commit ci copy cp delete del remove rm diff di export help ? h import info list ls lock log merge mergeinfo mkdir move mv rename ren propdel pdel pd propedit pedit pe propget pget pg proplist plist pl propset pset ps resolve resolved revert status stat st switch sw unlock update up)

# environment variables
complete -%*        c/%/j/                  # fill in the jobs builtin
complete {fg,bg,stop} c/%/j/ p/1/"(%)"//
complete alias      p/1/a/          # only aliases are valid
complete bunzip2    'p/*/f:*.{bz2,tbz2}/'
complete cd         p/1/d/
complete chdir      p/1/d/
complete chgrp      'p/1/g/'
complete chown      'p/1/u/'
complete complete   p/1/X/
complete cvs        'p/1/$cvs_cmds/' 'n/-H/$cvs_cmds/'
# (kinda cool: complete first arg with an env variable, and add an =,
# continue completion of first arg with a filename.  complete 2nd arg with a
# command)
complete env        'c/*=/f/' 'p/1/e/=/' 'p/2/c/'
complete exec       p/1/c/
complete find       n/-fstype/"(nfs 4.2)"/ n/-name/f/ \
                    n/-type/"(c b d f p l s)"/ n/-user/u/ n/-group/g/ \
                    n/-exec/c/ n/-ok/c/ n/-cpio/f/ n/-ncpio/f/ n/-newer/f/ \
                    c/-/"(fstype name perm prune type user nouser \
                         group nogroup size inum atime mtime ctime exec \
                         ok print ls cpio ncpio newer xdev depth \
                         daystart follow maxdepth mindepth noleaf version \
                         anewer cnewer amin cmin mmin true false uid gid \
                         ilname iname ipath iregex links lname empty path \
                         regex used xtype fprint fprint0 fprintf \
                         print0 printf not a and o or)"/ \
                         n/*/d/
complete {fossil,fs} 'n/help/$fossil_cmds/' 'p/1/$fossil_cmds/'
complete gcc        c/-[IL]/d/ \
                    c/-f/"(caller-saves cse-follow-jumps delayed-branch \
                           elide-constructors expensive-optimizations \
                           float-store force-addr force-mem inline \
                           inline-functions keep-inline-functions \
                           memoize-lookups no-default-inline \
                           no-defer-pop no-function-cse omit-frame-pointer \
                           rerun-cse-after-loop schedule-insns \
                           schedule-insns2 strength-reduce \
                           thread-jumps unroll-all-loops \
                           unroll-loops syntax-only all-virtual \
                           cond-mismatch dollars-in-identifiers \
                           enum-int-equiv no-asm no-builtin \
                           no-strict-prototype signed-bitfields \
                           signed-char this-is-variable unsigned-bitfields \
                           unsigned-char writable-strings call-saved-reg \
                           call-used-reg fixed-reg no-common \
                           no-gnu-binutils nonnull-objects \
                           pcc-struct-return pic PIC shared-data \
                           short-enums short-double volatile)"/ \
                    c/-W/"(all aggregate-return cast-align cast-qual \
                           comment conversion enum-clash error format \
                           id-clash-len implicit missing-prototypes \
                           no-parentheses pointer-arith return-type shadow \
                           strict-prototypes switch uninitialized unused \
                           write-strings)"/ \
                    c/-m/"(68000 68020 68881 bitfield fpa nobitfield rtd \
                           short c68000 c68020 soft-float g gnu unix fpu \
                           no-epilogue)"/ \
                    c/-d/"(D M N)"/ \
                    c/-/"(f W vspec v vpath ansi traditional \
                          traditional-cpp trigraphs pedantic x o l c g L \
                          I D U O O2 C E H B b V M MD MM i dynamic \
                          nodtdlib static nostdinc undef)"/ \
                    c/-l/f:*.a/ \
                    n/*/f:*.{c,C,cc,o,a,s,i}/
complete gdb        n/-d/d/ n/*/c/
complete git        'n/help/$git_cmds/' 'p/1/$git_cmds/'
complete gunzip     'p/*/f:*.{gz2,tgz}/'
complete limit      c/-/"(h)"/ n/*/l/
complete man        'p/1/c/'
complete mtr        'p/1/$hosts/'
complete ping       'p/1/$hosts/'
complete popd       p/1/d/
complete pushd      p/1/d/
complete scp        'n/-P/$ssh_ports/' 'n/-o/$ssh_opts/' "c,*:/,F:/," "c,*:,F:$HOME," 'c/*@/$hosts/:/'
complete set        'c/*=/f/' 'p/1/s/=' 'n/=/f/'
complete setenv     'p/1/e/'
complete sv         'p/1/$sv_cmds/'
complete svn        'n/help/$svn_cmds/' 'p/1/$svn_cmds/'
complete ssh        'p/1/$hosts/' 'n/-p/$ssh_ports/' 'n/-o/$ssh_opts/' 'p/2/c/'
complete su         c/--/"(login fast preserve-environment command shell help version)"/ \
		    c/-/"(f l m p c s -)"/ n/{-c,--command}/c/ \
		    n@{-s,--shell}@'`cat /etc/shells`'@ n/*/u/
complete traceroute 'p/1/$hosts/'
complete unalias    n/*/a/
complete uncomplete p/*/X/
complete unzip     'p/*/f:*.zip/'
complete unxz      'p/*/f:*.xz/'
complete unlimit    c/-/"(h)"/ n/*/l/
complete unset      n/*/s/
complete unsetenv 'p/1/e/'
complete where p/1/c/
complete which p/*/c/

# Host-specific completion bits
switch ( $OSTYPE )
case "darwin*":
    complete sysctl     'p/1/`sysctl -a | cut -d : -f 1`/'
    complete top 'n/-o/(cpu pid command csw time threads ports \
			mregion rprvt rshrd rsize vsize vprvt pgrp ppid \
			state uid wq faults cow user msgsent msgrecv \
			sysbsd sysmach pageins)/'
    breaksw
case "freebsd*":
case "FreeBSD*":
    complete sysctl     'p/1/`sysctl -Na`/'
    complete top 'n/-o/(cpu size res time pri threads total read write fault vcsw ivcsw jid)/'
    breaksw
endsw

unset noglob
# End the auto-complete section

# Use a "site-wide" .tcsh.site file for per-company settings and a per-host
# .tcsh.local for per-host settings. .cshrc is largely immutable because I
# update it periodically via:
#
# fetch -o ~/.cshrc https://github.com/sean-/flask-skeleton/raw/master/.cshrc
if (-o .site.tcsh && -P22: .site.tcsh == "0") source .site.tcsh
if (-o .local.tcsh && -P22: .local.tcsh == "0") source .local.tcsh

end:
    onintr
