#!/usr/bin/perl -w
package Clust_FeatureExtractor;
use strict;
use warnings;
use Data::Dumper;
# perform the single pass clustering 
our (@ISA, @EXPORT);
use Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(sseg print_feature extract);
#
sub sseg {
  my $news=shift @_;
  # print STDERR 'sseg:' . Dumper($news);
  # here we segment the article into sentence
  my @ss=();
  my $n=0;
  push @ss, $news->{'t'};
  $n++;
  my $text=$news->{'c'};
  # print STDERR Dumper($news) if !defined $text;
  my $ptn="。|！|？|，";
  $text=~s/($ptn)/$1\n/g;
  my @rawss=split(/\n/,$text);
  foreach my $r (@rawss) {
	$r=~s/^\s+//;
	$r=~s/\s+$//;
	next if $r eq '';
	$ss[$n++]=$r;
  }
  # print STDERR "sseg: return $n sentences.\n";
  return \@ss;
}

sub feature_in_window {
  my ($key,$arr,$i,$window,$fmap)=@_;
  my @arr=@{$arr};
  {
	# print STDERR "extract for $key from " . $arr[$i],"\n";
    if($arr[$i]=~m/ $key\/n/) {
	  my $b=$i-$window;
	  $b=0 if $b<0;
	  my $e=$i+$window;
	  $e=scalar @arr - 1  if $e>scalar @arr - 1;
      
	  # extract from the sub-sequence
	  for(my $j=$b;$j<=$e;$j++) {
		feature_one_stnc($key,$arr[$j],$fmap);
	  }
	}
  }
}

sub feature_one_stnc {
  my ($key,$stnc,$fmap)=@_;
  my @words=split(/ /,$stnc);
  foreach my $w (@words) {
    if($w=~/\/n/) { # use noun phrase only
	  # validate the feature
	  next if $w=~m/^[^\x01-\x7F]/ and length($w)==5;
      next if $w=~m/^$key\/n/;
	  $w=~s/\/n.*$//;
	  $fmap->{$w}+=1;
	}
  }
}

sub print_feature {
  my ($key,$ss,$window,$nid)=@_;
  my @arr=@{$ss};
  $key=~s/[\[\]\(\)\{\}]//g;

  # print "extract:" . Dumper($ss);
  # here we extract the features
  my %fmap=();
  my $title=shift @arr;
  feature_one_stnc($key,$title,\%fmap);
  for(my $i=0; $i<@arr; $i++) {
	# print STDERR "extract for $key from " . $arr[$i],"\n";
	feature_in_window($key,\@arr,$i,$window,\%fmap);
  }
  foreach my $w (keys %fmap) {
    print "$w\t$nid\n";
  }
}

sub extract {
  my ($key,$ss,$window,$dict,$idf,$norm)=@_;
  my @arr=@{$ss};
  $key=~s/[\[\]\(\)\{\}]//g;

  # print "extract:" . Dumper($ss);
  # here we extract the features
  my %id2val=();
  my %fmap=();
  my $title=shift @arr;
  feature_one_stnc($key,$title,\%fmap);
  for(my $i=0; $i<@arr; $i++) {
	# print STDERR "extract for $key from " . $arr[$i],"\n";
	feature_in_window($key,\@arr,$i,$window,\%fmap);
  }
  my $cnt=0;
  foreach my $w (keys %fmap) {
	$cnt+=$fmap{$w};
  }

  foreach my $w (keys %fmap) {
	my $wgt=1.0;
	if(defined $idf) {
      if(exists $idf->{$w}) {
		$wgt=$idf->{$w};
	  }else{
		warn "WARN: IDF not found for '$w', ignore it.\n";
		next;
	  }
	}
	$wgt=$wgt*$fmap{$w}/$cnt; #IDF*TF
    if(exists $dict->{$w}) {
      $id2val{$dict->{$w}}=$wgt;
    }else{
  	  my $gid=scalar keys %{$dict};
  	  $id2val{$gid}=$wgt;
  	  $dict->{$w}=$gid;
    }
  }
  # normalize and return
  my @id2feature=();
  my $sum=0;
  if($norm==1) {
    foreach my $k (keys %id2val) {
      $sum+=$id2val{$k}*$id2val{$k};
    }
    $sum=$sum**0.5;
  }
  # 
  foreach my $k (sort{ $a<=>$b } keys %id2val) {
    push @id2feature, $k;
	if($norm==1) {
	  push @id2feature, $id2val{$k}/$sum;
    }else{
	  push @id2feature, $id2val{$k};
	}
  }
  # print "extract:" . Dumper(\@id2feature);
  return \@id2feature;
}
