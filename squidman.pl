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
print "\n-------------------STARTED at ".localtime()."--------------\n";

$dbh = DBI->connect("DBI:mysql:$dbname:$dbhost",$dbuser,$dbpass);
$sth = $dbh->prepare("select ip,username,password,authorized_ip from squid_access where server=\'$squidmainip\'") ||
	 die $dbh->errstr();
$sth->execute();

open(ACL,'>'.$acl) || die "!!!can\'t create $acl";

my $htpasswd_exits = 0;
my $ipaclcnt = 0;
while(@row = $sth -> fetchrow_array) {
	my ($squidip, $squiduser, $squidpass, $squidauthip) = @row;
	print "\nFound record: $squidip $squiduser $squidauthip\n";
	if ($squiduser){
		print "    Adding ACL for $squiduser\n";
		print ACL "acl acl-name-$squiduser proxy_auth $squiduser\n";
		print ACL "acl acl-ip-$squiduser localip $squidip\n";
		print ACL "http_access allow acl-ip-$squiduser acl-name-$squiduser\n\n";
		print "    ";
		if ($htpasswd_exists) {
			system("/usr/bin/htpasswd -b $htpasswd $squiduser $squidpass");
		}else{
			system("/usr/bin/htpasswd -cb $htpasswd $squiduser $squidpass");
			$htpasswd_exists = 1;
		}
	}elsif($squidauthip){
#		for my $authip (split/\,/,$squidauthip){
		$squidauthip =~ s/\,/ /g;
		print "    Adding ACL for IP addresses $squidauthip\n";
		print ACL "acl acl-src-$ipaclcnt src $squidauthip\n";				
		print ACL "acl acl-ip-$ipaclcnt localip $squidip\n";				
		print ACL "http_access allow acl-src-$ipaclcnt acl-ip-$ipaclcnt\n\n";				
		$ipaclcnt++;
#		}
	}
}

close(ACL);
$sth->finish();
$dbh->disconnect();

print "\nCopying config to $squidmainip\...\n";
system("/usr/bin/scp $acl $htpasswd squid.conf $squidmainip:/etc/squid3/") == 0 || die "!!!can\'t copy config to remote";
#system("/usr/bin/ssh -t $squidmainip \'squid3 -k parse &1>/dev/null\'") == 0 || die "---error in squid config" ;
print "\nApplying config...\n";
system("/usr/bin/ssh -t $squidmainip \'squid3 -k reconfigure\'") == 0 || die "!!!can\'t apply config" ;

print "-------------------FINISHED at ".localtime()."--------------\n\n";

