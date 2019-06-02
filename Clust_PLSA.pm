#!/usr/bin/perl -w
package Clust_PLSA;
use strict;
use warnings;
use Data::Dumper;
# perform the plsa
our (@ISA, @EXPORT);
use Exporter;

@ISA=qw(Exporter);
@EXPORT=qw(plsa link_plsa);
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

  # issue the EM iterations
  # init pzgdw with random value
  print STDERR "initializing...\n";
  # rand_init(\@pzgdw,$K);
  iteration($id2feature, $lnkinfo, $lmda, $K,
      undef, undef, undef,
      \@pwgz, \%pdgz, \@pz,
      \@pwz, \@pdz);
  # record to the prev iteration
  record(\@pwgz, \%pdgz, \@pz, 
        \@pwz, \@pdz, 
	\@ppwgz, \%ppdgz, \@ppz, $K);
 
  print STDERR "em-iteration...\n";
  my ($sum,$nstep, $olikeli)=(0.0,0,undef);
  while(1) {
    @pwgz=();
    %pdgz=();
    @pz=();
    @pdz=();
    @pwz=();

    # em-iteration
    iteration($id2feature, $lnkinfo, $lmda, $K,
      \@ppwgz, \%ppdgz, \@ppz,
      \@pwgz, \%pdgz, \@pz,
      \@pwz, \@pdz);

    # record to the prev iteration
    record(\@pwgz, \%pdgz, \@pz, 
        \@pwz, \@pdz, 
	\@ppwgz, \%ppdgz, \@ppz, $K);
    # print log-likelihood
    my $loglike = likelihood($id2feature, $lnkinfo, $lmda, $K,
        \@ppwgz, \%ppdgz, \@ppz);
    $nstep+=1;
    last if(defined $olikeli and abs($olikeli-$loglike)/abs($olikeli) < $eps);
    die "error: $olikeli > $loglike\n" if defined $olikeli and $olikeli > $loglike;

    $olikeli=$loglike;
    # print STDERR "pwgz:" . Dumper(\@ppwgz);
    # print STDERR "pdgz:" . Dumper(\%ppdgz);
    print STDERR "em-iter:$nstep,log-likelihood:$loglike\n";
    # print 'pz' . Dumper(\@ppz);
    last if $nstep >= $maxit;
  }
  return (\@ppwgz, \%ppdgz, \@ppz);
}

sub iteration {
    my ($id2feature, $lnkinfo, $lmda, $K,
      $ppwgz, $ppdgz, $ppz,
      $pwgz, $pdgz, $pz,
      $pwz, $pdz) = @_;
    # em-iteration
    my @pzgdw=();
    my @pzgdd=();
    foreach my $d (keys %{$id2feature}) {
      my @vec=@{$id2feature->{$d}};
      for(my $w=0; $w<@vec; $w+=2) {
	# e-step posterior
	if(defined $ppwgz and defined $ppdgz and defined $ppz) {
          my $sum=0.0;
    	  for(my $z=0; $z<$K; $z++) {
  	    $pzgdw[$z]=$ppwgz->[$vec[$w]][$z]*$ppdgz->{$d}[$z]*$ppz->[$z];
  	    $sum+=$pzgdw[$z];
	  }
	  # normalise
          for(my $z=0; $z<$K; $z++) {
  	    $pzgdw[$z]/=$sum;
	  }
	}else{
          rand_init(\@pzgdw, $K);
	}
	# m-step
        for(my $z=0; $z<$K; $z++) {
    	  my $delta=$pzgdw[$z]*$vec[$w+1];
          $pwgz->[$vec[$w]][$z] += $delta;
          $pwz->[$z] += $delta;

    	  $pdgz->{$d}[$z] += $lmda*$delta;
          $pdz->[$z] += $lmda*$delta;

    	  $pz->[$z] += $lmda*$delta;
        }
      }
      next if $lmda==1.0;
      next if !defined $lnkinfo;
      next if !defined $lnkinfo->{$d};
      my %map=%{$lnkinfo->{$d}};
      foreach my $d1 (keys %map) {
        if(defined $ppdgz and defined $ppz) {
          my $sum=0.0;
	  # e-step posterior
    	  for(my $z=0; $z<$K; $z++) {
	    # my $other=0;
	    my $other=$ppdgz->{$d1}[$z];# if exists $ppdgz->{$d1};
  	    $pzgdd[$z]=$other*$ppdgz->{$d}[$z]*$ppz->[$z];
  	    $sum+=$pzgdd[$z];
	  }
	  # normalise
          for(my $z=0; $z<$K; $z++) {
  	    $pzgdd[$z]/=$sum;
	  }
        }else{
          rand_init(\@pzgdd,$K);
	}
        # m-step
        for(my $z=0; $z<$K; $z++) {
    	  my $other=0.0;
    	  $other=$lnkinfo->{$d1}{$d};# if defined $lnkinfo->{$d1}{$d};
	  # $other=$map{$d} if $d1 == $d;
    	  my $delta=(1-$lmda)*$pzgdd[$z]*($other+$map{$d1});
    	  $pdgz->{$d}[$z] += $delta;
          $pdz->[$z] += $delta;
    	  my $delta1=(1-$lmda)*$pzgdd[$z]*$map{$d1};
	  $pz->[$z] += $delta1;
        }
      }
    }
}

sub record {
    my ($pwgz, $pdgz, $pz, 
        $pwz, $pdz, 
	$ppwgz, $ppdgz, $ppz, $K) = @_;
    # print Dumper($pwgz);
    for(my $w=0; $w<scalar @{$pwgz}; $w++) {
      next if !defined $pwgz->[$w];
      my @vec=@{$pwgz->[$w]};
      for(my $z=0; $z<$K; $z++) {
	$ppwgz->[$w][$z]=$vec[$z]/$pwz->[$z];
      }
    }
    foreach my $d (keys %{$pdgz}) {
      my @vec=@{$pdgz->{$d}};
      for(my $z=0; $z<$K; $z++) {
	$ppdgz->{$d}[$z]=$pdgz->{$d}[$z]/$pdz->[$z];
      }
    }
    my $nz=0;
    for(my $z=0; $z<$K; $z++) {
      $nz+=$pz->[$z];
    }
    for(my $z=0; $z<$K; $z++) {
      $ppz->[$z]=$pz->[$z]/$nz;
    }
}

sub likelihood {
    my ($id2feature, $lnkinfo, $lmda, $K,
        $ppwgz, $ppdgz, $ppz) = @_;
    # record to the prev iteration
    my $loglike=0.0;
    foreach my $d (keys %{$id2feature}) {
      my @vec=@{$id2feature->{$d}};
      for(my $w=0; $w<@vec; $w+=2) {
        my $pdw=0.0;
        for(my $z=0; $z<$K; $z++) {
 	  $pdw+=$ppdgz->{$d}[$z]*$ppwgz->[$vec[$w]][$z]*$ppz->[$z];
        }
        $loglike+=$lmda*$vec[$w+1]*log($pdw);
      }
      next if !defined $lnkinfo->{$d};
      next if $lmda==1.0;
      my %map=%{$lnkinfo->{$d}};
      foreach my $d1 (keys %map) {
        my $pdd=0.0;
	for(my $z=0; $z<$K; $z++) {
          $pdd+=$ppdgz->{$d1}[$z]*$ppdgz->{$d}[$z]*$ppz->[$z];
	}
	$loglike+=(1-$lmda)*$map{$d1}*log($pdd);
      }
    }
    return $loglike; 
}

sub link_plsa {

  my ($id2feature,$K,$maxit,$eps,$lnkinfo,$lmda)=@_;

  my @pwgz=();
  my %pzgd=();
  my %pcgz=();

  my @pwz=();
  my %pdz=();
  my @pcz=();

  my @ppwgz=();
  my %ppzgd=();
  my %ppcgz=();

  # init pzgdw with random value
  print STDERR "initializing...\n";
  iteration_lnk($id2feature, $lnkinfo, $lmda, $K, 
        undef, undef, undef, 
	\@pwgz, \%pzgd, \%pcgz,
	\@pwz, \%pdz, \@pcz);
 
  # record to the prev iteration
  record_lnk( \@pwgz, \%pzgd, \%pcgz, 
       \@pwz, \%pdz, \@pcz,
       \@ppwgz, \%ppzgd, \%ppcgz,$K );
   
  print STDERR "em-iteration...\n";
  my ($sum,$nstep, $olikeli)=(0.0,0,undef);
  while(1) {
    @pwgz=();
    %pzgd=();
    %pcgz=();

    @pcz=();
    %pdz=();
    @pwz=();
    # em-iteration
    iteration_lnk($id2feature, $lnkinfo, $lmda, $K, 
        \@ppwgz, \%ppzgd, \%ppcgz,
	\@pwgz, \%pzgd, \%pcgz, \@pwz, \%pdz, \@pcz);
    # record to the prev iteration
    record_lnk( \@pwgz, \%pzgd, \%pcgz, 
       \@pwz, \%pdz, \@pcz,
       \@ppwgz, \%ppzgd, \%ppcgz,$K );
    # print log-likelihood
    my $loglike = likelihood_lnk($id2feature, $lnkinfo, $lmda, $K, 
          \@ppwgz, \%ppzgd, \%ppcgz);
    $nstep+=1;
    last if(defined $olikeli and abs($olikeli-$loglike)/abs($olikeli) < $eps);
    die "error: $olikeli > $loglike\n" if defined $olikeli and $olikeli > $loglike;
    $olikeli=$loglike;
    # print STDERR "pwgz:" . Dumper(\@ppwgz);
    # print STDERR "pdgz:" . Dumper(\%ppdgz);
    print STDERR "em-iter:$nstep,log-likelihood:$loglike\n";
    # print 'pz' . Dumper(\@ppz);
    last if $nstep >= $maxit;
  }
  return (\@ppwgz, \%ppzgd, \%ppcgz);
}

sub iteration_lnk {
   
    my ($id2feature, $lnkinfo, $lmda, $K, 
        $ppwgz, $ppzgd, $ppcgz,
	$pwgz, $pzgd, $pcgz,
	$pwz, $pdz, $pcz) = @_; 

    my @pzgdw=();
    my @pzgdc=();
    foreach my $d (keys %{$id2feature}) {
      my @vec=@{$id2feature->{$d}};
      my $wsum=0;
      for(my $w=0; $w<@vec; $w+=2) {
	$wsum+=$vec[$w+1];
      }
      for(my $w=0; $w<@vec; $w+=2) {
	# e-step posterior
	if(defined $ppwgz and defined $ppzgd) {
          my $sum=0.0;
    	  for(my $z=0; $z<$K; $z++) {
  	    $pzgdw[$z]=$ppwgz->[$vec[$w]][$z]*$ppzgd->{$d}[$z];
  	    $sum+=$pzgdw[$z];
	  }
	  # normalise
          for(my $z=0; $z<$K; $z++) {
  	    $pzgdw[$z]/=$sum;
	  }
	} else {
          rand_init(\@pzgdw,$K);
	}
	# m-step
        for(my $z=0; $z<$K; $z++) {
    	  my $delta=$pzgdw[$z]*$vec[$w+1]/$wsum;
          $pwgz->[$vec[$w]][$z] += $delta;
	  $pwz->[$z] += $delta;

          $pzgd->{$d}[$z] += $lmda*$delta;
	  $pdz->{$d} += $lmda*$delta;
        }
      }
      next if $lmda==1.0;
      next if !defined $lnkinfo;
      next if !defined $lnkinfo->{$d};
      my %map=%{$lnkinfo->{$d}};

      my $csum=0;
      foreach my $d1 (keys %map) {
	$csum+=$map{$d1};
      }
      foreach my $d1 (keys %map) {
	# e-step posterior
	if(defined $ppzgd and defined $ppcgz) {
	  # next if !defined $ppzgd->{$d} or !defined $ppcgz->{$d1};
          my $sum=0.0;
    	  for(my $z=0; $z<$K; $z++) {
  	    $pzgdc[$z]=$ppzgd->{$d}[$z]*$ppcgz->{$d1}[$z];
  	    $sum+=$pzgdc[$z];
	  }
	  # normalise
          for(my $z=0; $z<$K; $z++) {
  	    $pzgdc[$z]/=$sum;
	  }
        }else{
          rand_init(\@pzgdc,$K);
	}
        for(my $z=0; $z<$K; $z++) {
    	  my $delta=$pzgdc[$z]*$map{$d1}/$csum;
    	  $pcgz->{$d1}[$z] += $delta;
	  $pcz->[$z] += $delta;
    	  my $delta1=(1-$lmda)*$delta;
    	  $pzgd->{$d}[$z] += $delta1;
	  $pdz->{$d} += $delta1;
        }
      }
    }
}

sub record_lnk {

    my ( $pwgz, $pzgd, $pcgz, 
       $pwz, $pdz, $pcz,
       $ppwgz, $ppzgd, $ppcgz ,$K) = @_;
    # record to the prev iteration
    for(my $p=0; $p< scalar @{$pwgz}; $p++) {
      next if !defined $pwgz->[$p];
      my @vec=@{$pwgz->[$p]};
      for(my $z=0; $z<$K; $z++) {
        $ppwgz->[$p][$z] = $vec[$z]/$pwz->[$z];
      }
    }
    foreach my $p (keys %{$pzgd}) {
      my @vec=@{$pzgd->{$p}};
      for(my $z=0; $z<$K; $z++) {
        $ppzgd->{$p}[$z] = $vec[$z]/$pdz->{$p};
      }
    }
    foreach my $p (keys %{$pcgz}) {
      my @vec=@{$pcgz->{$p}};
      for(my $z=0; $z<$K; $z++) {
        $ppcgz->{$p}[$z] = $vec[$z]/$pcz->[$z];
      }
    }
}

sub likelihood_lnk {
    my ($id2feature, $lnkinfo, $lmda, $K, 
      $ppwgz, $ppzgd, $ppcgz) = @_;
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
 	  $pdw+=$ppzgd->{$d}[$z]*$ppwgz->[$vec[$w]][$z];
        }
        $loglike+=$lmda*$vec[$w+1]*log($pdw)/$sum;
      }
      next if !defined $lnkinfo->{$d};
      next if $lmda==1.0;
      # d-c
      $sum=0;
      foreach my $c (keys %{$lnkinfo->{$d}}) {
        $sum+=$lnkinfo->{$d}{$c};
      }
      foreach my $c (keys %{$lnkinfo->{$d}}) {
	my $pdc=0.0;
	# next if !defined $ppzgd->{$d} or !defined $ppcgz->{$c};
        for(my $z=0; $z<$K; $z++) {
 	  $pdc+=$ppzgd->{$d}[$z]*$ppcgz->{$c}[$z];
        }
	$loglike+=(1-$lmda)*$lnkinfo->{$d}{$c}*log($pdc)/$sum;
      }  
    }
    return $loglike; 
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
