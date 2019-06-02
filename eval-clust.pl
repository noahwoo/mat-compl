#!/usr/bin/perl -w
use strict;
use warnings;
use URI::Escape;
use Data::Dumper;

die "usage: $0 clust labeling id2url wiki-redir\n" if @ARGV!=4;
my ($fclust, $flab, $fid2url, $fwiki)=@ARGV;

my %id2url=();
my %wiki=();
load_map($fid2url,"\t",1,0,\%id2url);
load_map($fwiki,"\t",1,2,\%wiki);

my %clust=();
my %uclust=();
my %lab=();
my %ulab=();

read_clust($fclust, \%id2url, \%clust, \%uclust);
read_lab($flab, \%wiki, \%lab, \%ulab);

###################################
# Evaluate
foreach my $key (keys %clust) {
  if(exists $lab{$key}) {
    my $cmap=$clust{$key};
	my $lmap=$lab{$key};

	my $cn=clean_ids($cmap, $ulab{$key},0);
  	my $ln=clean_ids($lmap, $uclust{$key},1);
    next if $cn==0 or $ln==0;
	print "cn=$cn,key=$key," . Dumper($cmap);
	print "ln=$ln,key=$key," . Dumper($lmap);
    next if scalar keys %{$cmap} == 0 or scalar keys %{$lmap} == 0;
    my $puri=calc($cmap, $lmap);
	my $invp=calc($lmap, $cmap);
	next if $puri==0 or $invp==0;
	my $f1=2*$puri*$invp/($puri+$invp);
	print "Evaluate for '$key'($cn),puri=$puri, invp=$invp, f-1=$f1.\n";
  }
}
###################################
sub clean_ids {
  my ($map, $set, $warn)=@_;
  my $n=0;
  foreach my $k (keys %{$map}) {
    my $c2id=$map->{$k};
    foreach my $id (keys %{$c2id}) {
      if(!exists $set->{$id}) {
		if($warn==1) {
		  warn "WARN: remove $id since of non-existance.\n";
	    }
        delete $c2id->{$id};
		delete $map->{$k} if scalar keys %{$c2id}==0;
      }else{
        $n+=1;
      }
    }
  }
  return $n;
}
  
###################################
sub calc {
  my ($l2id, $c2id)=@_;
  my ($sum,$n)=(0,0);

  foreach my $k (keys %{$l2id}) {
    my $lmap=$l2id->{$k};
    my $nl=scalar keys %{$lmap};
    $n+=$nl;
  }

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
    print "elements=($k<->$mc,$mp,$nl,$n)\n";
    $sum+=$mp*$nl/$n;
  }
  return $sum;
}

sub precision {
  my ($c1,$c2)=@_;
  my ($n,$nt)=(0,0);
  foreach my $id (keys %{$c1}) {
    if(exists $c2->{$id}) {
      $n+=1;
    }
    $nt+=1;
  }
  return 0 if($nt==0);
  return $n/$nt;
}

sub read_lab {
  my ($flab, $wiki, $lab, $ulab)=@_;
  open(FL,$flab) or die "Fail to read label from $flab.\n";
  while(<FL>) {
    chomp;
    my ($cnt, $key, $url, $entry)=split(/\t/,$_);
    $entry=~s/^.*\/([^\/]*)}$/$1/;
    $entry=uri_unescape($entry);
    # print STDERR "$t\t$e\t$wiki\n";
    $entry="out-of-wiki" if $entry=~m/out-of-wiki/i;
    $entry=~s/_/ /g;
    if(exists $wiki->{$entry}) {
	  print "REDIR: $entry=>" . $wiki->{$entry}, "\n";
      $entry=$wiki->{$entry};
	}
	$lab->{$key}{$entry}{$url}=1;
	$ulab->{$key}{$url}=1;
  }
  close(FL);
}

sub read_clust {
  my ($fclust,$id2umap,$clust,$uclust)=@_;
  open(FC,$fclust) or die "Fail to read cluster from $fclust.\n";
  while(<FC>) {
	chomp;
	if(/^CLUST\t/) {
      my ($dummy, $key, $name, $cnt, $ids)=split(/\t/,$_);
	  my @aid=split(/\s+/,$ids);
	  foreach my $id (@aid) {
        my $u=$id2umap->{$id};
		warn "unfounded id=$id in umap.\n" and next if !defined $u;
		$clust->{$key}{$name}{$u}=1;
		$uclust->{$key}{$u}=1;
	  }
    }
  }
  close(FC);
}

sub load_map {
  my ($f,$seg,$kfield,$vfield,$map)=@_;
  open (F,$f) or die "Fail to read data from $f.\n";
  while(<F>) {
	chomp;
	my @tkns=split(/$seg/,$_);
	if($kfield >= @tkns or $vfield >= @tkns) {
	  warn "WARN: ignore '$_' since kfield=$kfield, vfield=$vfield, but length=" . scalar @tkns, ".\n";
	  next;
	}
	$map->{$tkns[$kfield]}=$tkns[$vfield];
  }
  close(F);
}
