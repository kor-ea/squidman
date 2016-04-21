#!/usr/bin/perl -w

use DBI;

my $dbuser = "root";
my $dbpass = "test123!";
my $dbname = "testdb";
my $dbhost = "localhost";

$dbh = DBI->connect("DBI:mysql:$dbname:$dbhost",$dbuser,$dbpass);
$sth = $dbh->prepare("select ip,username,password,authorized_ip from squid_access") || die $dbh->errstr();
$sth->execute();
while(@row = $sth -> fetchrow_array) {
	my ($squidip, $squiduser, $squidpass, $squidauthip) = @row;
	print "$squidip $squiduser $squidpass $squidauthip\n";
}
$sth->finish();

