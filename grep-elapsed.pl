#!/usr/bin/perl -w
use strict;
use warnings;

my ($node,$bgn,$end);
my %map=();

while(<STDIN>) {
  chomp;
  if(/^\+\+training lambda=(.*),#nodes=(\d+) \* (\d+)/) {
		$node=$2*$3;
	}elsif(/^(.*) INFO mapred\.JobClient: Running job/) {
		$bgn=$1;
	}elsif(/^(.*) INFO mapred\.JobClient: Job complete/) {
		$end=$1;
	}elsif(/^training at iteration=(\d+),/) {
		my $it=$1;
		$map{$node}{$it}=tsub($end,$bgn);
		die "$_#$end,$bgn\n" if tsub($end,$bgn) < 0;
	}
}

foreach my $node (sort {$a <=>$b} keys %map) {
  my %time=%{$map{$node}};
  my ($n,$tot)=(0,0);
	foreach my $it (keys %time) {
		next if $it==0;
		$tot+=$time{$it};
		$n+=1;
	}
	my $avg=$tot/$n;
	print "$node\t$avg\n";
}

sub tsub {
	my ($end,$bgn)=@_;

	my ($ymde, $hmse)=split(/ /,$end);
  my ($ymdb, $hmsb)=split(/ /,$bgn);

  my ($ey,$emn,$ed)=split(/\//,$ymde);
  my ($by,$bmn,$bd)=split(/\//,$ymdb);

	my ($eh,$em,$es) = split(/:/,$hmse);
	my ($bh,$bm,$bs) = split(/:/,$hmsb);

	return ($ed-$bd)*24*60*60+($eh-$bh)*60*60+($em-$bm)*60+$es-$bs;
}
