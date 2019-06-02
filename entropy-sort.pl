#!/usr/bin/perl -w
# sort the distribution with decreasing of entropy
use strict;
use warnings;

die "usage: $0 cluster head catid2title\n" if @ARGV!=3;
my ($clust,$head,$cat2id)=@ARGV;
my %id2catitle=();
my %id2entropy=();
load($cat2id,\%id2catitle);
open(CLUST,$clust) or die "Fail to read cluster from $clust.\n";
while(<CLUST>) {
  chomp;
  if(/^$head(.*)$/) {
    my @tkns=split(/\s+/,$1);
    my $id=shift @tkns;
    my $entropy=0;
    foreach my $tkn (@tkns) {
      my ($k,$v)=split(/:/,$tkn);
      next if $v<=0.0;
      $entropy=$v*log($v);
    }
    $id2entropy{$id}=-$entropy;
  }
}
close(CLUST);

foreach my $id (sort {$id2entropy{$b}<=>$id2entropy{$a}} keys %id2entropy) {
  print "$id\t" . $id2entropy{$id} ."\t". $id2catitle{$id}{'title'} ."\t". $id2catitle{$id}{'cat'},"\n";
}

sub load {
  my ($cat2id,$map)=@_;
  open(CI,$cat2id) or die "Fail to read from $cat2id.\n";
  while(<CI>) {
    chomp;
    my ($cat,$id,$title)=split(/\t/,$_);
    $map->{$id}{'cat'}=$cat;
    $map->{$id}{'title'}=$title;
  }
  close(CI);
}
