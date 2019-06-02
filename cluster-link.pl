#!/usr/bin/perl -w
# cluster the news for different person:
use FindBin qw/$Bin/;
use lib "$Bin";
use strict;
use warnings;
use Data::Dumper;
# use Clust_SinglePass;
# use Clust_FeatureExtractor;
use Clust_PLSA;

main();

# main entry
sub main {
  # my %id2feature=(1=>[(1,1)], 2=>[(1,1,2,0.1)], 3=>[(1,0.707,2,0.707)], 4=>[(1,0.1,2,1)], 5=>[(2,1)]);
  # print Dumper(\%id2feature);
  # my ($key2, $clust) = sng_pass("test", \%id2feature, 0.8);
  # print Dumper($clust);
  die "usage: $0 feature link lambda K algo\n" if @ARGV!=5;
  my ($feature,$link,$lmda,$K,$algo)=@ARGV;
  my %fmap=();
  my %lmap=();
  load_feature($feature,\%fmap);
  load_link($link,\%lmap);
  my ($pwgz, $pdgz, $pcgz, $pz);
  if($algo eq 'S') {
    ($pwgz, $pdgz, $pz)=plsa(\%fmap,$K,200,0.00001,\%lmap,$lmda);
  }elsif($algo eq 'L') {
    ($pwgz, $pdgz, $pcgz)=link_plsa(\%fmap,$K,200,0.00001,\%lmap,$lmda);
  }else {
    die "algo option: [S|L]\n";
  }
  # print Dumper($pwgz);
  # print p(z)
  # print "p(z)\n";
  # for(my $i=0;$i<@{$pz};$i++) {
    # print " $i:" . $pz->[$i],"\n";
  # }
  # print doc
  foreach my $d (keys %{$pdgz}) {
    my @arr=@{$pdgz->{$d}};
    my %k2v=();
    my $n=0;
    my $sum=0;
    for(my $k=0;$k<@arr;$k+=1) {
      if($algo eq 'S') {
        $k2v{$k}=$arr[$k]*$pz->[$k];
      }else{
        $k2v{$k}=$arr[$k];
      }
      $sum+=$k2v{$k};
    }
    for(my $k=0;$k<@arr;$k+=1) {
      $k2v{$k}/=$sum;
    }
    print "doc:$d";
    $n=0;
    foreach my $k (sort {$k2v{$b}<=>$k2v{$a}} keys %k2v) {
      print " $k:" . $k2v{$k};
      $n+=1;
      last if $n>=5;
    }
    print "\n";
  }
  # print word
  my %z2topic=();
  my @pwgz=@{$pwgz};
  for(my $w=0; $w<@pwgz; $w++) {
    next if !defined $pwgz[$w];
    my @arr=@{$pwgz[$w]};
    for(my $k=0;$k<@arr;$k++) {
      $z2topic{$k}{$w}=$arr[$k];
    }
  }
  my $topN=100;
  foreach my $k (sort {$a<=>$b} keys %z2topic) {
    my %topic=%{$z2topic{$k}};
    my $n=0;
    print "topic $k:";
    foreach my $w (sort {$topic{$b}<=>$topic{$a}} keys %topic) {
      last if $topic{$w} == 0;
      print " $w:" . $topic{$w};
      $n+=1;
      last if $n>=$topN;
    }
    print "\n";
  }
}

sub load_feature {
  my ($feature,$fmap)=@_;
  open(F,$feature) or die "Fail to read feature from $feature.\n";
  while(<F>) {
    chomp;
    my @tkns=split(/\s+/,$_);
    my $id=shift @tkns;
    my @vec=();
    foreach my $pair (@tkns) {
      my ($k,$v)=split(/:/,$pair);
      push @vec,$k;
      push @vec,$v;
    }
    $fmap->{$id}=[@vec];
  }
  close(F);
}

sub load_link {
  my ($link,$lmap)=@_;
  open(L,$link) or die "Fail to read feature from $link.\n";
  while(<L>) {
    chomp;
    my @tkns=split(/\s+/,$_);
    my $id=shift @tkns;
    foreach my $pair (@tkns) {
      my ($k,$v)=split(/:/,$pair);
      $k=-$k if($k<0);
      $lmap->{$id}{$k}=$v;
    }
  }
  close(L);
}
