#!/usr/bin/perl -w
use strict;
use warnings;

die "usage: $0 paper classification root\n" if @ARGV!=3;
my ($fp, $cls, $root)=@ARGV;

my %p2c=();
load($cls, \%p2c);
my %idset=();
open(F,$fp) or die "Fail to read from $fp.\n";
while(<F>) {
  chomp;
  my ($id,$url,$text)=split(/\t/,$_);
  next if exists $idset{$id};
  next if !defined $text or $text eq '';
  if(exists $p2c{$url}) {
    my $c=$p2c{$url};
    # $text=~s/^.*?<title>(.*?)<\/title>.*$/$1/;
		warn "no file $root/$url found.\n" and next if !-e "$root/$url";
		$text=`grep '^Abstract:' $root/$url`;
		$text=~s/Abstract://;
		$text=~s/\n.*//;
		# $text=~s/Abstract-found://;
		# $text=~s/Reference-contexts:.*$//i;
		# next if $text=~m/\s+0$/;
	  $text=~s/^\s+|\s+$//;
		next if $text eq '';
    print "$c\t$id\t$text\n";
    $idset{$id}=1;
  }
}
close(F);

sub load {
  my ($cls,$map)=@_;
  open(C,$cls) or die "Fail to read from $cls.\n";
  while(<C>) {
    chomp;
    my ($url,$c)=split(/\t/,$_);
    $map->{$url}=$c;
  }
  close(C);
}
