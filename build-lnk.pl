#!/usr/bin/perl -w
use strict;
use warnings;

die "usage: $0 citations\n" if @ARGV!=1;
my $cite=shift @ARGV;
my %cmap=();
load($cite,\%cmap);

while(<STDIN>) {
  chomp;
  my $id=$_;
  $id=~s/^(\d+) .*$/$1/;
  if(exists $cmap{$id}) {
    print $id;
    my $map=$cmap{$id};
    foreach my $k (sort {$a<=>$b} keys %{$map}) {
      next if $k<=0;
      print " -$k:1";
    }
    print "\n";
  }
}

sub load {
  my ($cite,$map)=@_;
  open(C,$cite) or die "Fail to read citations from $cite.\n";
  while(<C>) {
    chomp;
    my ($src,$ref)=split(/\t/,$_);
    $map->{$src}{$ref}=1;
  }
  close(C);
}
