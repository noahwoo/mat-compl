#!/usr/bin/perl -w
package Clust_PLSA;
use strict;
use warnings;
use Data::Dumper;
# perform the plsa
our (@ISA, @EXPORT);
use Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(plsa);
# main();

#############
sub main {
  my %id2feature=(1=>[(1,10)], 2=>[(1,11)], 3=>[(1,9)], 5=>[(2,10)], 4=>[(2,9)], 6=>[(2,11)], 7=>[(1,10, 2,10)]);
  print Dumper(\%id2feature);
  my ($pwgz, $pdgz, $pz) = plsa(\%id2feature, 2, 20, 0.01);
  print "pdgz:" . Dumper($pdgz);
  print "pwgz:" . Dumper($pwgz);
}

sub plsa {

  my ($id2feature,$K,$maxit,$eps,$lnkinfo,$lmda)=@_;

  my @pwgz=();
  my %pdgz=();
  my @pz=();
  my @pwz=();
  my @pdz=();

  my @ppwgz=();
  my %ppdgz=();
  my @ppz=();

  my ($nz,$ndz,$nwz)=(0,0,0);
  # issue the EM iterations
  my @pzgdw=(); # $K length 
  my @pzgdd=(); # $K length
  # init pzgdw with random value
  print STDERR "initializing...\n";
  # rand_init(\@pzgdw,$K);
  foreach my $d (keys %{$id2feature}) {
    my @vec=@{$id2feature->{$d}};
    for(my $w=0; $w<@vec; $w+=2) {
      # no e-step needed for estimiation of pzgdw needed
      rand_init(\@pzgdw,$K);
      # m-step
      for(my $z=0; $z<$K; $z++) {
	my $delta=$lmda*$pzgdw[$z]*$vec[$w+1];
        $pwgz[$vec[$w]][$z] += $delta;
	$pdgz{$d}[$z] += $delta;
	$pz[$z] += $delta;
	$pdz[$z] += $delta;
        $pwz[$z] += $delta;
        $nz+=$delta;
	$nwz+=$delta;
	$ndz+=$delta;
      }
    }
    next if $lmda==1.0;
    next if !defined $lnkinfo;
    next if !defined $lnkinfo->{$d};
    my %map=%{$lnkinfo->{$d}};
    foreach my $d1 (keys %map) {
      rand_init(\@pzgdd,$K);
      for(my $z=0; $z<$K; $z++) {
	my $other=0.0;
	$other=$lnkinfo->{$d1}{$d} if defined $lnkinfo->{$d1}{$d};
	my $delta=(1-$lmda)*$pzgdd[$z]*($other+$map{$d1});
	$pdgz{$d}[$z] += $delta;

	my $delta1=(1-$lmda)*$pzgdd[$z]*$map{$d1};
	$pz[$z]+=$delta1;
        $nz+=$delta1;

	$pdz[$z] += $delta;
	$ndz+=$delta;
      }
    }
  }
  # record to the prev iteration
  foreach my $d (keys %{$id2feature}) {
    my @vec=@{$id2feature->{$d}};
    for(my $w=0; $w<@vec; $w+=2) {
      for(my $z=0; $z<$K; $z++) {
	$ppwgz[$vec[$w]][$z] = $pwgz[$vec[$w]][$z]/$pwz[$z];
	$ppdgz{$d}[$z] = $pdgz{$d}[$z]/$pdz[$z];
        $ppz[$z] = $pz[$z]/$nz;
      }
    }
  }
  print STDERR "em-iteration...\n";
  my ($sum,$nstep, $olikeli)=(0.0,0,undef);
  while(1) {
    
    @pwgz=();
    %pdgz=();
    @pz=();
    @pdz=();
    @pwz=();
    ($nz,$ndz,$nwz)=(0,0,0);
    # em-iteration
    foreach my $d (keys %{$id2feature}) {
      my @vec=@{$id2feature->{$d}};
      for(my $w=0; $w<@vec; $w+=2) {
	$sum=0.0;
	# e-step posterior
    	for(my $z=0; $z<$K; $z++) {
  	  $pzgdw[$z]=$ppwgz[$vec[$w]][$z]*$ppdgz{$d}[$z]*$ppz[$z];
  	  $sum+=$pzgdw[$z];
	}
	# normalise
        for(my $z=0; $z<$K; $z++) {
  	  $pzgdw[$z]/=$sum;
	}
	# m-step
        for(my $z=0; $z<$K; $z++) {
    	  my $delta=$lmda*$pzgdw[$z]*$vec[$w+1];
          $pwgz[$vec[$w]][$z] += $delta;
    	  $pdgz{$d}[$z] += $delta;

    	  $pz[$z] += $delta;
          $nz+=$delta;

          $pdz[$z] += $delta;
          $ndz+=$delta;

          $pwz[$z] += $delta;
          $nwz+=$delta;
        }
      }
      next if $lmda==1.0;
      next if !defined $lnkinfo;
      next if !defined $lnkinfo->{$d};
      my %map=%{$lnkinfo->{$d}};
      foreach my $d1 (keys %map) {
        $sum=0.0;
	# e-step posterior
    	for(my $z=0; $z<$K; $z++) {
	  my $other=0;
	  $other=$ppdgz{$d1}[$z] if exists $ppdgz{$d1};
  	  $pzgdd[$z]=$other*$ppdgz{$d}[$z]*$ppz[$z];
  	  $sum+=$pzgdd[$z];
	}
	# normalise
        for(my $z=0; $z<$K; $z++) {
  	  $pzgdd[$z]/=$sum;
	}

        for(my $z=0; $z<$K; $z++) {
    	  my $other=0.0;
    	  $other=$lnkinfo->{$d1}{$d} if defined $lnkinfo->{$d1}{$d};
    	  my $delta=(1-$lmda)*$pzgdd[$z]*($other+$map{$d1});
    	  $pdgz{$d}[$z] += $delta;
    	  my $delta1=(1-$lmda)*$pzgdd[$z]*$map{$d1};
    	  $pdz[$z] += $delta;
	  $ndz+=$delta;
	  $pz[$z] += $delta1;
          $nz+=$delta1;
        }
      }
    }
    # record to the prev iteration
    my $loglike=0.0;
    foreach my $d (keys %{$id2feature}) {
      my @vec=@{$id2feature->{$d}};
      for(my $w=0; $w<@vec; $w+=2) {
        my $pdw=0.0;
        for(my $z=0; $z<$K; $z++) {
    	  $ppwgz[$vec[$w]][$z] = $pwgz[$vec[$w]][$z]/$pwz[$z];
	  $ppdgz{$d}[$z] = $pdgz{$d}[$z]/$pdz[$z];
    	  $ppz[$z] = $pz[$z]/$nz;
 	  $pdw+=$ppdgz{$d}[$z]*$ppwgz[$vec[$w]][$z]*$ppz[$z];
        }
        $loglike+=$vec[$w+1]*$log($pdw);
      }
    }
    $nstep+=1;
    if(defined $olikeli and abs($olikeli-$loglike)/abs($olikeli) < $eps) {
      last;
    }
    $olikeli=$loglike;
    # print STDERR "pwgz:" . Dumper(\@ppwgz);
    # print STDERR "pdgz:" . Dumper(\%ppdgz);
    print STDERR "em-iter:$nstep,log-likelihood:$loglike\n";
    # print 'pz' . Dumper(\@ppz);
    last if $nstep >= $maxit;
  }
  return (\@ppwgz, \%ppdgz, \@ppz);
}

sub link_plsa {

  my ($id2feature,$K,$maxit,$eps,$lnkinfo,$lmda)=@_;

  my @pwgz=();
  my %pzgd=();
  my %pcgz=();
  my %pwz=();
  my %pdz=();
  my %pcz=();

  my @ppwgz=();
  my %ppzgd=();
  my %ppcgz=();

  # issue the EM iterations
  my @pzgdw=(); # $K length 
  my @pzgdc=(); # $K length
  # init pzgdw with random value
  print STDERR "initializing...\n";
  # rand_init(\@pzgdw,$K);
  foreach my $d (keys %{$id2feature}) {
    my @vec=@{$id2feature->{$d}};
    my $sum=0;
    for(my $w=0; $w<@vec; $w+=2) {
      $sum+=$vec[$w+1];
    }
    for(my $w=0; $w<@vec; $w+=2) {
      # no e-step needed for estimiation of pzgdw needed
      rand_init(\@pzgdw,$K);
      # m-step
      for(my $z=0; $z<$K; $z++) {
	my $delta=$pzgdw[$z]*$vec[$w+1]/$sum;
        $pwgz[$vec[$w]][$z] += $delta;
	$pwz{$z} += $delta;

	$pdgz{$d}[$z] += $lmda*$delta;
	$pdz{$d} += $lmda*$delta;
      }
    }
    next if $lmda==1.0;
    next if !defined $lnkinfo;
    next if !defined $lnkinfo->{$d};
    my %map=%{$lnkinfo->{$d}};
    $sum=0;
    foreach my $d1 (keys %map) {
      $map{$d1}+=$sum;
    }
    foreach my $d1 (keys %map) {
      rand_init(\@pzgdc,$K);
      for(my $z=0; $z<$K; $z++) {
	my $delta=$pzgdc[$z]*$map{$d1}/$sum;
	$pcgz{$d}[$z] += $delta;
        $pcz{$z} += $delta;
	my $delta1=(1-$lmda)*$delta;
	$pzgd{$d}[$z] += $delta1;
	$pdz{$d} += $delta1;
      }
    }
  }
  # record to the prev iteration
  foreach my $w (@pwgz) {
    next if !defined $pwgz[$w];
    my @vec=@{$pwgz[$p]};
    for(my $z=0; $z<$K; $z++) {
      $ppwgz[$p][$z] = $vec[$z]/$pwz[$z];
    }
  }
  foreach my $d (keys %pzgd) {
    my @vec=@{$pdgz[$d]};
    for(my $z=0; $z<$K; $z++) {
      $ppzgd[$d][$z] = $vec[$z]/$pdz[$d];
    }
  }
  foreach my $c (keys %pcgz) {
    my @vec=@{$pcgz[$c]};
    for(my $z=0; $z<$K; $z++) {
      $ppcgz[$c][$z] = $vec[$z]/$pcz[$z];
    }
  }
   
  print STDERR "em-iteration...\n";
  my ($sum,$nstep, $olikeli)=(0.0,0,undef);
  while(1) {
    
    @pwgz=();
    %pdgz=();
    @pz=();
    @pdz=();
    @pwz=();
    ($nz,$ndz,$nwz)=(0,0,0);
    # em-iteration
    foreach my $d (keys %{$id2feature}) {
      my @vec=@{$id2feature->{$d}};
      for(my $w=0; $w<@vec; $w+=2) {
	$sum=0.0;
	# e-step posterior
    	for(my $z=0; $z<$K; $z++) {
  	  $pzgdw[$z]=$ppwgz[$vec[$w]][$z]*$ppdgz{$d}[$z]*$ppz[$z];
  	  $sum+=$pzgdw[$z];
	}
	# normalise
        for(my $z=0; $z<$K; $z++) {
  	  $pzgdw[$z]/=$sum;
	}
	# m-step
        for(my $z=0; $z<$K; $z++) {
    	  my $delta=$pzgdw[$z]*$vec[$w+1];
          $pwgz[$vec[$w]][$z] += $delta;
	  $pwz{$z} += $delta;

          $pzgd{$d}[$z] += $lmda*$delta;
	  $pdz{$d} += $lmda*$delta;
        }
      }
      next if $lmda==1.0;
      next if !defined $lnkinfo;
      next if !defined $lnkinfo->{$d};
      my %map=%{$lnkinfo->{$d}};
      $sum=0;
      foreach my $d1 (keys %map) {
	$sum+=$map{$d1};
      }

      foreach my $d1 (keys %map) {
        $sum=0.0;
	# e-step posterior
    	for(my $z=0; $z<$K; $z++) {
  	  $pzgdc[$z]=$ppdgz{$d}[$z]*$ppcgz{$d1}[$z]*$ppz[$z];
  	  $sum+=$pzgdc[$z];
	}
	# normalise
        for(my $z=0; $z<$K; $z++) {
  	  $pzgdc[$z]/=$sum;
	}

        for(my $z=0; $z<$K; $z++) {
    	  my $delta=$pzgdd[$z]*$map{$d1}/$sum;
    	  $pcgz{$d}[$z] += $delta;
	  $pcz{$z} += $delta;
    	  my $delta1=(1-$lmda)*$delta;
    	  $pzgd{$d}[$z] += $delta1;
	  $pdz{$d} += $delta1;
        }
      }
    }
    # record to the prev iteration
    foreach my $p (@pwgz) {
      next if !defined $pwgz[$p];
      my @vec=@{$pwgz[$p]};
      for(my $z=0; $z<$K; $z++) {
        $ppwgz[$p][$z] = $vec[$z]/$pwz[$z];
      }
    }
    foreach my $p (keys %pzgd) {
      my @vec=@{$pdgz[$p]};
      for(my $z=0; $z<$K; $z++) {
        $ppzgd[$p][$z] = $vec[$z]/$pdz[$p];
      }
    }
    foreach my $p (keys %pcgz) {
      my @vec=@{$pcgz[$p]};
      for(my $z=0; $z<$K; $z++) {
        $ppcgz[$p][$z] = $vec[$z]/$pcz[$z];
      }
    }
    # print log-likelihood
    my $loglike=0.0;
    foreach my $d (keys %{$id2feature}) {
      # d-w
      my @vec=@{$id2feature->{$d}};
      my $sum=0;
      for(my $w=0; $w<@vec; $w+=2) {
	$sum+=$vec[$w+1];
      }
      for(my $w=0; $w<@vec; $w+=2) {
        my $pdw=0.0;
        for(my $z=0; $z<$K; $z++) {
 	  $pdw+=$ppzgd{$d}[$z]*$ppwgz[$vec[$w]][$z];
        }
        $loglike+=$lmda*$vec[$w+1]*log($pdw)/$sum;
      }
      # d-c
      $sum=0;
      foreach my $c (keys %{$lnkinfo->{$d}} {
        $sum+=$lnkinfo->{$d}{$c};
      }
      foreach my $c (keys %{$lnkinfo->{$d}} {
	my $pdc=0.0;
        for(my $z=0; $z<$K; $z++) {
 	  $pdc+=$ppzgd{$d}[$z]*$ppcgz{$c}[$z];
        }
	$loglike+=(1-$lmda)*$lnkinfo->{$d}{$c}*log($pdc)/$sum;
      }  
    }
    $nstep+=1;
    if(defined $olikeli and abs($olikeli-$loglike)/abs($olikeli) < $eps) {
      last;
    }
    $olikeli=$loglike;
    # print STDERR "pwgz:" . Dumper(\@ppwgz);
    # print STDERR "pdgz:" . Dumper(\%ppdgz);
    print STDERR "em-iter:$nstep,log-likelihood:$loglike\n";
    # print 'pz' . Dumper(\@ppz);
    last if $nstep >= $maxit;
  }
  return (\@ppwgz, \%ppdgz, \@ppz);
}

sub rand_init {
  my ($vec, $K)=@_;
  my $sum=0.0;
  for(my $k=0;$k<$K;$k++) {
    $vec->[$k]=rand();
    $sum+=$vec->[$k];
  }
  for(my $k=0;$k<$K;$k++) {
    $vec->[$k]/=$sum;
  }
  # print "rand_init: " . Dumper($vec);
}
