#!/usr/bin/perl -w
use strict;
use warnings;

while(<STDIN>) {
  chomp;
  my @tkns=split(/\s+/,$_);
  my $lab=shift @tkns;
  my %k2v=();
  foreach my $tkn (@tkns) {
    my ($k,$v)=split(/:/,$tkn);
    $k2v{$k}=$v;
  }
  next if scalar keys %k2v == 0;
  print $lab;
  foreach my $k (sort {$a<=>$b} keys %k2v) {
    print " $k:" . $k2v{$k};
  }
  print "\n";
}
