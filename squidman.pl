#!/usr/bin/perl -w

use DBI;

my $dbuser = "root";
my $dbpass = "test123!";
my $dbname = "testdb";
my $dbhost = "localhost";
my $acl = "squidman.acl";
my $htpasswd = "passwd";

my ($squidmainip) = @ARGV;
die "Usage: perl -w squidman.pl squid-ip" unless (defined $squidmainip);

#my $logfile = 'squidman.log';
#open OUTPUT, ">>$logfile" or die $!;
#STDOUT->fdopen( \*OUTPUT, 'w' ) or die $!;
print "---STARTED at ".localtime()."\n";

$dbh = DBI->connect("DBI:mysql:$dbname:$dbhost",$dbuser,$dbpass);
$sth = $dbh->prepare("select ip,username,password,authorized_ip from squid_access where server=\'$squidmainip\'") ||
	 die $dbh->errstr();
$sth->execute();

open(ACL,'>'.$acl) || die "--can\'t create $acl";

my $htpasswd_exits = 0;
my $ipaclcnt = 0;
while(@row = $sth -> fetchrow_array) {
	my ($squidip, $squiduser, $squidpass, $squidauthip) = @row;
	print "$squidip $squiduser $squidpass $squidauthip\n";
	if ($squiduser){
		print ACL "acl acl-name-$squiduser proxy_auth $squiduser\n";
		print ACL "acl acl-ip-$squiduser localip $squidip\n";
		print ACL "http_access allow acl-ip-$squiduser acl-name-$squiduser\n";
		if ($htpasswd_exists) {
			system("/usr/bin/htpasswd -b $htpasswd $squiduser $squidpass");
		}else{
			system("/usr/bin/htpasswd -cb $htpasswd $squiduser $squidpass");
			$htpasswd_exists = 1;
		}
	}elsif($squidauthip){
#		for my $authip (split/\,/,$squidauthip){
		$squidauthip =~ s/\,/ /g;
		print ACL "acl acl-src-$ipaclcnt src $squidauthip\n";				
		print ACL "acl acl-ip-$ipaclcnt localip $squidip\n";				
		print ACL "http_access allow acl-src-$ipaclcnt acl-ip-$ipaclcnt\n";				
		$ipaclcnt++;
#		}
	}
}
system("/usr/bin/scp $acl $htpasswd squid.conf $squidmainip:/etc/squid3/") == 0 || die "---can\'t copy config to remote";
system("/usr/bin/ssh -t $squidmainip \'squid3 -k parse &1>/dev/null\'") == 0 || die "---error in squid config" ;
system("/usr/bin/ssh -t $squidmainip \'squid3 -k reconfigure\'") == 0 || die "---can\'t reconfigure" ;


$sth->finish();
$dbh->disconnect();
close(ACL);
print "---FINISHED at ".localtime()."\n";

