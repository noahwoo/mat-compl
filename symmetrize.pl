#!/usr/bin/perl -w
use strict;
use warnings;

my %trans=();

while(<STDIN>) {
  chomp;
  my @tkns=split(/\s+/,$_);
  my $id=shift @tkns;
  foreach my $pair (@tkns) {
    my ($k,$v)=split(/:/,$pair);
    $k=sprintf("%d",-$k) if $k < 0;
    $trans{$k}{$id}=$v;
    $trans{$id}{$k}=$v;
  }
}

foreach my $d (keys %trans) {
  my %map=%{$trans{$d}};
  print $d;
  foreach my $k (sort {$a<=>$b} keys %map) {
    print " $k:" . $map{$k};
  }
  print "\n";
}
