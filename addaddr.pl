#!/usr/bin/perl -w
use strict;
use NetAddr::IP;
my ($listofips) = @ARGV;
my $iface = $ARGV[2] || "venet0";
my $intnum = $ARGV[1] || 0;
die "Usage: perl -w addaddr.pl input-file first-subint-num main-int" unless (defined $listofips);

open(SUBNETLIST,$listofips) || die "!!! can\'t read $listofips";
open(IPLIST, ">iplist.out") || die "!!! can\'t create iplist.out";

open(IFACES,">>/etc/network/interfaces") || die "!!! can\'t write to interfaces";
#open(IFACES,">out.txt") || die "!!! error";
while(<SUBNETLIST>){
	my $ip = new NetAddr::IP($_);
	while ($ip < $ip->broadcast){
		print IPLIST $ip->addr."\n";
		print IFACES "auto $iface:$intnum\n";
		print IFACES "iface $iface:$intnum inet static\n";
		print IFACES "     address ".$ip->addr."\n";
		print IFACES "     netmask ".$ip->mask."\n\n";
		$intnum++;
		$ip++;
	}
}
close(IPLIST);
close(SUBNETLIST);
close(IFACES);
#system("systemctl restart networking") == 0 || die "!!! can\'t apply config" ;

