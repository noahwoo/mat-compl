#!/usr/bin/perl -w
use strict;
use warnings;
die "usage: $0 triple MI|IG|FQ(default FQ)\n" if @ARGV!=2;

my $in=shift @ARGV;
my $way=shift @ARGV;

my $info=\&FQ;
if(defined $way) {
 if( $way eq "IG") {
  $info=\&IG;
 }elsif( $way eq "MI") {
  $info=\&MI;
 }
}

my $nt=0;
my %nx=();
my %ny=();
open(IN,$in) or die "Fail to read from $in.\n";
while(<IN>) {
  chomp;
  my ($n, $x, $y)=split(/\t/,$_);
  $nx{$x}+=$n;
  $ny{$y}+=$n;
  $nt+=$n;
}
close(IN);
print STDERR "calc statistics done.\n";
# open and process again
my %y2mi=();
open(IN,$in);
my $px=undef;
while(<IN>) {
  chomp;
  my ($n, $x, $y)=split(/\t/,$_);
  if(defined $px and !($px eq $x)) {
    foreach my $k (sort {$y2mi{$b} <=> $y2mi{$a}} keys %y2mi) {
      print "$px\t$k\t".$y2mi{$k},"\n";
	}
	%y2mi=();
  }
  next if $nx{$x} < 10 or $ny{$y} < 10; # cut the less freq term
  $y2mi{$y}=$info->($n, $ny{$y}, $nx{$x}, $nt);
  $px=$x;
}
close(IN);
# the last one
foreach my $k (sort {$y2mi{$b} <=> $y2mi{$a}} keys %y2mi) {
  print "$px\t$k\t".$y2mi{$k},"\n";
}

sub FQ {
  my ($a, $nw, $nc, $n)=@_;
  return $a/$nc;
}

sub MI {
  my ($a, $nw, $nc, $n)=@_;
  my ($pab, $pa, $pb)=($n*$a, $nw, $nc);
  return log($pab/($pa*$pb));
}

sub IG {
  my ($a, $nw, $nc, $n)=@_;
  my $ig=0.0;
  # print STDERR "calc IG with: a=$a, nw=$nw, nc=$nc, n=$n\n";
  # calculate the information gain by
  # IG(c|w)=H(c)-H(c|w): this measures how much information is obtained if knows w
  # H(c)= P(c) log P(c) + P(~c) log P(~c)
  # H(c|w) = P(w){P(c|w) log P(c|w) + P(~c|w) log P(~c|w)} 
  #			+ P(~w){P(c|~w) log P(c|~w) + P(~c|~w) log P(~c|~w)} 
  my ($pw, $pc)=($nw/$n, $nc/$n);
  my ($pcw, $pcnw)=($a/$nw, ($nc-$a)/($n-$nw));
  $pcw=0.99999 if $pcw==1;
  $pcw=0.00001 if $pcw==0;
  $pcnw=0.99999 if $pcnw==1;
  $pcnw=0.00001 if $pcnw==0;
  $ig = $pw*($pcw*log($pcw)+(1-$pcw)*log(1-$pcw)) + (1-$pw)*($pcnw*log($pcnw)+(1-$pcnw)*log(1-$pcnw));
  return -$ig;
}
