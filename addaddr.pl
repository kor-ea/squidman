#!/usr/bin/perl -w
use strict;
my ($listofips) = @ARGV;
my $iface = $ARGV[2] || "venet0";
my $intnum = $ARGV[1] || 0;
my %hosts = ('29'=> 6, '28' => 14, '27' => 30, '26' => 62, '25' => 126, '24' => 254);
die "Usage: perl -w addaddr.pl input-file first-subint-num main-int" unless (defined $listofips);

open(SUBNETLIST,$listofips) || die "!!! can\'t read $listofips";
open(IPLIST, ">iplist.out") || die "!!! can\'t create iplist.out";

open(IFACES,">>/etc/network/interfaces") || die "!!! can\'t write to interfaces";
#open(IFACES,">out.txt") || die "!!! error";
while(<SUBNETLIST>){
	my ($first3octets,$lastoctet,$mask) = ($_ =~ /(\d+\.\d+\.\d+\.)(\d+)\/(\d{2})/);
	for (my $i = 1; $i <= $hosts{$mask}; $i++){
		my $newip = $lastoctet + $i;
		my $ip =  $first3octets.$newip;	
		print IPLIST $ip."\n";
		print IFACES "auto $iface:$intnum\n";
		print IFACES "iface $iface:$intnum inet static\n";
		print IFACES "     address $ip\n";
		print IFACES "     netmask 255.255.255.255\n\n";
		$intnum++;
	}
}
close(IPLIST);
close(SUBNETLIST);
close(IFACES);
#system("systemctl restart networking") == 0 || die "!!! can\'t apply config" ;

