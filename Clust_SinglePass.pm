#!/usr/bin/perl -w
package Clust_SinglePass;
use strict;
use warnings;
use Data::Dumper;
# perform the single pass clustering 
our (@ISA, @EXPORT);
use Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(sng_pass add dot);
# main();

#############
sub main {
  my %id2feature=(1=>[(1,1)], 2=>[(1,1,2,0.1)], 3=>[(1,0.707,2,0.707)], 4=>[(1,0.1,2,1)], 5=>[(2,1)]);
  print Dumper(\%id2feature);
  my ($key, $clust) = sng_pass("test", \%id2feature, 0.8);
  print Dumper($clust);
}
# in: key; array of feature vector; threshold
# out: cluster result
sub sng_pass {
  my ($key, $id2feature, $th)=@_;
  my %cluster=();
  my $gid=0;
  # for a cluster, we include: 1) the sum; 2) the count; 3) the ids 
  # the main loop of the single pass iteration
  foreach my $id ( keys %{$id2feature}) {
    my $f=$id2feature->{$id};
	# print "Handling: " . Dumper($f);
	my ($maxsim,$maxc)=(undef,undef);
	my $nf=norm2($f,1);
	foreach my $c ( keys %cluster ) {
      my $s=sim_clust($f,$nf,$cluster{$c});
	  if(!defined $maxsim or $s > $maxsim) {
		$maxsim=$s;
		$maxc=$c;
	  }
	}
	if(defined $maxsim and $maxsim>$th) {
	  # print "$maxsim>$th, update...\n";
	  update_clust($cluster{$maxc}, $id, $f);
	}else{
	  # print "creating...\n";
	  $gid=create_clust(\%cluster, $id, $f, $gid);
	}
  }
  return ($key, \%cluster);
}

sub dot($$) {
  my ($f1,$f2)=@_;
  my @a1=@{$f1};
  my @a2=@{$f2};
  # print "dot of " . Dumper(\@a1) . "and " . Dumper(\@a2);
  # sparse dot, make sure the ids are sorted, no check in this code
  my ($i,$j,$sum)=(0,0,0.0);
  while(1) {
    last if $i>=@a1 or $j>=@a2;
	if($a1[$i] < $a2[$j]) {
	  $i+=2;
	}elsif($a1[$i] > $a2[$j]) {
      $j+=2;
	}else{
	  $sum += $a1[$i+1]*$a2[$j+1];
      $i+=2; $j+=2;
	  # print "dot: sum=$sum\n";
	}
  }
  return $sum;
}

sub add($$) {
  my ($f1,$f2)=@_;
  my @a1=@{$f1};
  my @a2=@{$f2};
  # sparse add, make sure the ids are sorted, no check in this code
  my ($i,$j,$ind)=(0,0,0);
  my @sum=();
  while(1) {
    last if $i>=@a1 or $j>=@a2;
	if($a1[$i] < $a2[$j]) {
      $sum[$ind++]=$a1[$i];
	  $sum[$ind++]=$a1[$i+1];
	  $i+=2;
	}elsif($a1[$i] > $a2[$j]) {
	  $sum[$ind++]=$a2[$j];
	  $sum[$ind++]=$a2[$j+1];
      $j+=2;
	}else{
	  $sum[$ind++]=$a1[$i];
	  $sum[$ind++]=$a1[$i+1]+$a2[$j+1];
      $i+=2; $j+=2;
	}
  }

  while($i<@a1) {
    $sum[$ind++]=$a1[$i];
	$sum[$ind++]=$a1[$i+1];
	$i+=2;
  }

  while($j<@a2) {
	$sum[$ind++]=$a2[$j];
	$sum[$ind++]=$a2[$j+1];
    $j+=2;
  }
  # print "add " . Dumper($f1) . "and " . Dumper($f2);
  # print "obtain " . Dumper(\@sum);
  return \@sum;
}

sub norm {
  my ($f, $n, $flag)=@_;
  my $sum=0.0;
  my @arr=@{$f};
  for(my $i=0; $i<@arr; $i+=2) {
    $sum+=$arr[$i+1]**$n;
  }
  if($flag==1) {
	return $sum ** (1/$n);
  }else{
	return $sum;
  }
}

sub norm2 {
  my ($f, $flag)=@_;
  my $sum=0.0;
  my @arr=@{$f};
  for(my $i=0; $i<@arr; $i+=2) {
    $sum+=$arr[$i+1]*$arr[$i+1];
  }

  if($flag==1) {
	return sqrt($sum);
  }else{
	return $sum;
  }
}

sub cosine {
  my ($f1,$f2,$n1,$n2)=@_;
  # my ($f1,$f2)=@_;
  my $a=dot($f1,$f2);
  # my ($n1,$n2)=(norm2($f1,1),norm2($f2,1));
  # print "cosine of " . Dumper($f1) . " and " . Dumper($f2) if $n1*$n2==0;
  my $res=0;
  $res=$a/($n1*$n2) if $n1*$n2>0;
  # print "cosine of " . Dumper($f1) . " and " . Dumper($f2);
  # print "equals to $res\n";
  return $res;
}

# we current use the centriod - cosine
sub sim_clust {
  my ($f, $nf, $clust)=@_;
  # print "sim_clust: " . Dumper($clust);
  my $c=$clust->{'c'};
  my $n=$clust->{'n'};
  return cosine($f,$c,$nf,$clust->{'cn'}); # cosine used, some other similarity should also be supported
  # return cosine($f,$c);
}

sub update_clust {
  my ($clust,$id,$f)=@_;
  my $sum=add($clust->{'c'}, $f);
  $clust->{'c'}=[@{$sum}];
  $clust->{'n'}=$clust->{'n'}+1;
  push @{$clust->{'s'}},$id;
  $clust->{'cn'}=norm2($sum,1);

  # print clust
  # print "update_clust: " . Dumper($clust);
}

sub create_clust {
  my ($clust,$id,$f,$gid)=@_;
  $clust->{$gid}->{'c'}=[@{$f}];
  $clust->{$gid}->{'n'}=1;
  $clust->{$gid}->{'s'}=[($id)];
  $clust->{$gid}->{'cn'}=norm2($f,1);
  # print clust
  # print "create_clust: ";
  # print Dumper($clust);
  return $gid+1;
}
