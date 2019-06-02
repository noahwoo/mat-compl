#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Lingua::Stem::En;

die "usage: $0 stopwords\n" if @ARGV!=1;
my $fsw=shift @ARGV;
my %dict=();
my %stop=();

my $n=load($fsw,\%stop);
print STDERR "Read $n stopwords from $fsw.\n";
print STDERR Dumper(\%stop);
my $gid=1;
my %exceptions=();

while(<STDIN>) {
  chomp;
  my ($id,$title)=split(/\t/,$_);
  my @tkns=split(/[ `~!@#\$%^&*\(\)_+=:;"'<>,.?]+/,$title);
  # print Dumper(\@tkns);
  my %vmap=();
  foreach my $k (@tkns) {
    next if $k eq "";

    $k=lc($k);
    next if exists $stop{$k};
    # stemming
    my @word=($k);
    my $sword=Lingua::Stem::En::stem({ -words => \@word, -locale => 'en', -exceptions => \%exceptions });
    $k=$sword->[0];
    next if $k eq '';
    if(exists $dict{$k}) {
      $vmap{$dict{$k}}+=1;
    }else{
      $vmap{$gid}+=1;
      $dict{$k}=$gid;
      $gid+=1;
    }
  }
  # print Dumper(\%vmap);
  next if scalar keys %vmap == 0;
  print "$id";
  foreach my $fid (sort{ $a<=>$b } keys %vmap) {
    print " $fid:" . $vmap{$fid};
  }
  print "\n";
}

# dump the dictionary
open(D,">dictionary") or die "Fail to write dictionary.\n";
foreach my $k (sort {$dict{$a}<=>$dict{$b}} keys %dict) {
  print D "$k\t" . $dict{$k}, "\n";
}
close(D);

sub load {
  my ($f, $map)=@_;
  open(F,$f) or die "Fail to read stopwords from $f.\n";
  my $n=0;
  while(<F>) {
    chomp;
    $_=~s/\r//g;
    $map->{$_}=1;
    $n+=1;
  }
  close(F);
  return $n;
}
