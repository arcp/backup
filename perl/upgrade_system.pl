use strict;
use warnings;
use Net::SSH::Perl;
use Net::SCP::Expect;

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub scp() {
    my ( $host, $user, $pass, $src, $dst ) = @_;
    my $scp = new Net::SCP::Expect(
        host     => $host,
        port     => 22,
        user     => $user,
       auto_yes=>1,timeout=>300,
        password => $pass
    );
	eval { $scp->scp( $src, $dst ) };
	if ($@) {
		my $pos = index($@,":");
		printf "xxx %d\n",$pos;
		printf "%s\n",$@,substr($@,0,$pos);
		return 0;
	}
	return 1;
}

my $cfgfile = shift || "soooner.cfg";
my $ipfile  = shift || "ip_system.txt";
my $pkgfile = shift || "pkglist_system.txt";

my %config  = ();
my @iplist  = ();
my @pkglist = ();

open( CFG, "<" . $cfgfile );
while (<CFG>) {
    chomp;
    my ( $key, $value ) = split(/=/);
    $key   = trim($key);
    $value = trim($value);

    #printf "[%s] => [%s]\n", $key, $value;
    $config{$key} = $value;
}
close(CFG);

open( IP, "<" . $ipfile );
while (<IP>) {
    chomp;
    push @iplist, trim($_);
}
close(IP);

open( PKG, "<" . $pkgfile );
while (<PKG>) {
    chomp;
    push @pkglist, trim($_);
}
close(PKG);

foreach my $ip (@iplist) {
    next if ( $ip =~ /^#/ );
    foreach my $pkg (@pkglist) {
        next if ( $pkg =~ /^#/ );
        my @items = split( /;/, $pkg );
         my $result = 0;
        if ( $#items >= 1 ) {
            printf "scp %s %s\@%s:%s \n", trim( $items[0] ), $config{'user'},
              $ip, trim( $items[1] );
            $result = &scp(
                $ip, $config{'user'}, $config{'pass'},
                trim( $items[0] ),
                trim( $items[1] ),
            );
        }
        if ($result &&  $#items >= 2 ) {
            my $ssh = Net::SSH::Perl->new($ip,options => [ "BatchMode yes", "ConnectTimeout 30"]);
            $ssh->login( $config{'user'}, $config{'pass'} );

            for ( my $i = 2 ; $i <= $#items ; $i++ ) {
                printf "[%s]: exec [%s]\n", $ip, trim( $items[$i] );
                my ( $stdout, $stderr, $exit ) =
                  $ssh->cmd( trim( $items[$i] ));
                if ( $exit == 0 ) {
                    chomp($stdout) if $stdout;
                    printf "[%s]: [%s]\n", $ip, $stdout || 'OK';
                }
                else {
                    chomp($stderr) if $stderr;
                    printf "[%s]: [%s]\n", $ip, $stderr || 'FAILED';
                }
            }
        }
    }
#sleep(30);
}

printf "done\n";
