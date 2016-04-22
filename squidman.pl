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
$sth = $dbh->prepare("select ip,username,password,authorized_ip,port from squid_access where server=\'$squidmainip\' order by authorized_ip desc") ||
	 die $dbh->errstr();
$sth->execute() || die $sth->errstr();

open(ACL,'>'.$acl) || die "!!! can\'t create $acl";

my $htpasswd_exits = 0;
my $ipaclcnt = 0;
my $recordfound = 0;
my $httpport = 3128;
while(@row = $sth -> fetchrow_array) {
	my ($squidip, $squiduser, $squidpass, $squidauthip,$squidport) = @row;
	print "\nFound record: $squidip:$squidport $squiduser $squidauthip\n";
	$recordfound = 1;
	if ($squidport){
		$httpport = $squidport;
	}
	if ($squiduser){
		print "    Adding ACL for $squiduser\n";
		print ACL "acl acl-name-$squiduser proxy_auth $squiduser\n";
		print ACL "acl acl-ip-$squiduser localip $squidip\n";
		print ACL "http_access allow acl-ip-$squiduser acl-name-$squiduser\n";
		print ACL "tcp_outgoing_address $squidip acl-name-$squiduser\n\n";
		print "    ";
		if ($htpasswd_exists) {
			system("/usr/bin/htpasswd -b $htpasswd $squiduser $squidpass");
		}else{
			system("/usr/bin/htpasswd -cb $htpasswd $squiduser $squidpass");
			$htpasswd_exists = 1;
		}
		print "\n";
	}elsif($squidauthip){
#		for my $authip (split/\,/,$squidauthip){
		$squidauthip =~ s/\,/ /g;
		print "    Adding ACL for IP addresses $squidauthip\n";
		print ACL "acl acl-src-$ipaclcnt src $squidauthip\n";				
		print ACL "acl acl-ip-$ipaclcnt localip $squidip\n";				
		print ACL "http_access allow acl-src-$ipaclcnt acl-ip-$ipaclcnt\n";				
		print ACL "tcp_outgoing_address $squidip acl-src-$ipaclcnt\n\n";
		$ipaclcnt++;
#		}
	}
}
print "Adding http_port $httpport\n\n";					
print ACL "http_port $httpport\n\n";					
close(ACL);
$sth->finish();
$dbh->disconnect();

if ($recordfound){
	print "\nCopying config to $squidmainip\...\n";
	system("/usr/bin/scp $acl $htpasswd squid.conf $squidmainip:/etc/squid3/") == 0 || die "!!! can\'t copy config to remote";
	#system("/usr/bin/ssh -t $squidmainip \'squid3 -k parse &1>/dev/null\'") == 0 || die "---error in squid config" ;
	print "\nApplying config...\n";
	system("/usr/bin/ssh -t $squidmainip \'squid3 -k reconfigure\'") == 0 || die "!!! can\'t apply config" ;
}else{
	print "\n!!! No records were found for specified squid server $squidmainip\.\n";
}
print "\n-------------------FINISHED at ".localtime()."--------------\n\n";

