#!/usr/bin/perl -w
use strict;
use warnings;

die "usage: $0 idcat2title pzgd dictionary\n" if @ARGV!=3;
my ($idcat,$pzgd,$idict)=@ARGV;

my %cat2id=();
my %clust2id=();
my %idofcat=();
my %idofclu=();

my $nl=load_cat($idcat,\%cat2id,\%idofcat);
my $nc=load_clust($pzgd,\%clust2id,\%idofclu);
print "load $nl documents with label and $nc documents with clustering result.\n";

my $ncat=clean_ids(\%cat2id,\%idofclu);
my $nclu=clean_ids(\%clust2id,\%idofcat);

die "ncat=$ncat, nclu=$nclu\n" if $ncat != $nclu;
print "ncat=$ncat, nclu=$nclu\n";
my $n=$ncat;
my $map=calc(\%clust2id, \%cat2id, $n);

my %dict=();
my $curid = load($idict, \%dict);
print "load " . ($curid-1) . " words.\n";
open(PWGZ,$pzgd) or die "Fail to read from $pzgd.\n";
while(<PWGZ>) {
  chomp;
  if(/^topic (\d+):/) {
    my @tokens = split(/ /,$_);
		my $z=$1;
    print "#".$map->{$z}."#";
    for(my $i=2; $i<@tokens;++$i) {
      my ($k,$v) = split(/:/, $tokens[$i]);
      # print " " . $dict{$k} . ":$v";
      print " " . $dict{$k};
    }
    print "\n";
  }
}
close(PWGZ);

sub load {
  my ($fdict, $dict) = @_;
  open(F,$fdict) or return 1; 
  my $maxid=0;
  while(<F>) {
    chomp;
    my ($t,$id) = split(/\t/,$_);
    $dict->{$id} = $t;
    if($id > $maxid) {
      $maxid=$id;
    }
  }
  close(F);
  return $maxid+1;
}

sub calc {
  my ($l2id, $c2id, $n)=@_;
  my $sum=0;
	my %map=();
  foreach my $k (keys %{$l2id}) {
    my $lmap=$l2id->{$k};
    my $nl=scalar keys %{$lmap};
    my ($mp,$mc)=undef;
    foreach my $c (keys %{$c2id}) {
      my $cmap=$c2id->{$c};
      my $prec=precision($lmap,$cmap);
      if(!defined $mp or $mp<$prec) {
        $mp=$prec;
	      $mc=$c;
      }
    }
		$map{$k}=$mc;
    # print "elements=($k<->$mc,$mp,$nl,$n)\n";
  }
	return \%map;
}

sub clean_ids {
  my ($map, $set)=@_;
  my $n=0;
  foreach my $k (keys %{$map}) {
    my $c2id=$map->{$k};
    foreach my $id (keys %{$c2id}) {
      if(!exists $set->{$id}) {
	delete $c2id->{$id};
      }else{
	$n+=1;
      }
    }
  }
  return $n;
}
#calc: |C1 \cap C2| / |C1|
sub precision {
  my ($c1,$c2)=@_;
  my ($n,$nt)=(0,0);
  foreach my $id (keys %{$c1}) {
    if(exists $c2->{$id}) {
      $n+=1;
    }
    $nt+=1;
  }
  return $n/$nt;
}

sub load_cat {
  my ($idcat, $map, $set)=@_;
  my $n=0;
  open(F, $idcat) or die "Fail to read category from $idcat.\n";
  while(<F>) {
    chomp;
    my ($cat,$id)=split(/\t/,$_);
    $cat=~s/^\/([^\/]*?)\/.*/$1/;
    next if $cat eq '';
    $map->{$cat}{$id}=1;
    $set->{$id}=1;
    $n+=1;
  }
  close(F);
  return $n;
}

sub load_clust {
  my ($pzgd, $map, $set)=@_;
  my $n=0;
  open(F,$pzgd) or die "Fail to read cluster from $pzgd.\n";
  while(<F>) {
    chomp;
    if(/^doc:(\d+?) (\d+?):(.+?) /) {
      my ($id,$clust)=($1,$2);
      $map->{$clust}{$id}=1;
      $set->{$id}=1;
      $n+=1;
    }
  }
  close(F);
  return $n;
}
