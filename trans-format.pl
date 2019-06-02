#!/usr/bin/perl -w
# cluster the news for different person:
use FindBin qw/$Bin/;
use lib "$Bin";
use strict;
use warnings;

main();

sub main {
  # print Dumper(\%id2feature);
  # my ($key2, $clust) = sng_pass("test", \%id2feature, 0.8);
  # print Dumper($clust);
  
  my ($key,$okey,$url,$title,$content);
  my %e2news=();
  my ($nid,$n,$state)=(0,0,0);
  my $th=0.3;
  my $window=2;
  my $ind=0;
  my $omit=0;
  while(<STDIN>) { # read news from the search result
    chomp;
	if(/(\d+) news matched for "(.*)"/) {
      $key=$2; 
	  $omit=0;
	  $omit=1 if $1==0; # no-matched
	  if(defined $okey and (scalar keys %e2news > 0)) {
		$ind+=1;
		# print STDERR "Clustering $ind...\n";
		# my ($ckey, $clust, $id2feature)=clust_it($okey, \%e2news, $th, $window,\%dict);
		print_data($okey,\%e2news);
		%e2news=();
		# print "===============\n";
	  }
      $okey=$key;      
	  $state=0;
	}elsif(/^=========/) {
	  if(defined $title) {
        $e2news{$nid}{'t'}=$title;
	    $e2news{$nid}{'c'}=$content;
	    $e2news{$nid}{'u'}=$url;
	    $nid+=1;
	    $state=0;
        ($title,$content,$url)=(undef,undef,undef);
	  }
	}else{
	  next if $omit==1;
	  if($state==0) {
		$title=$_;
	  }elsif($state==1) {
		$content=$_;
	  }elsif($state==2) {
		if(/^http:\/\//) {
		  $url=$_;
	    }else{
		  die "error format at line $n: $_.\n";
		}
	  }else{
		$state=0;
	  }
	  $state+=1;
	}
	$n+=1;
  }
  # the last item
  # print STDERR "Clustering(last)...\n";
  # my ($ckey, $clust, $id2feature)=clust_it($okey, \%e2news, $th, $window,\%dict);
  # print Dumper($res);
  print_data($okey, \%e2news);
  # print "===============\n";
} 

sub print_data {
  my ($key, $e2news)=@_;
  print "$key";
  print STDERR "print data for \"$key\".\n";
  foreach my $id (keys %{$e2news}) {
    print "\t$id";
	print "\t" . $e2news->{$id}{'t'};
    print "\t" . $e2news->{$id}{'c'};
    print "\t" . $e2news->{$id}{'u'};
  }
  print "\n";
}
