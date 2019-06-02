#!/usr/bin/perl -w
# share or not
die "usage: $0 id2id-map threshold\n" if @ARGV!=2;
my $id2id = shift @ARGV;
my $threshold = shift @ARGV;
my %id2id=();

# my $threshold=3;

open(II,$id2id) or die "Fail to read id2id map from $id2id.\n";
while(<II>) {
  chomp;
  my @tkns=split(/\s+/,$_);
  my $id=shift @tkns;
  for(my $i=0; $i<@tkns; $i++) {
    my ($k,$v)=split(/:/,$tkns[$i]);
    $id2id{-$id}{$k}=$v;
  }
}
close(II);

foreach my $id1 (keys %id2id) {
  my $pid1=sprintf("%d",-$id1);
  my $m1=$id2id{$id1};
  print $pid1;
  foreach my $id2 (keys %id2id) {
    my $pid2=sprintf("%d",-$id2);
    my $m2=$id2id{$id2};
    my $sharedn=shared($m1, $m2);
    if($sharedn >= $threshold) {
      print " $id2:1";
    }
  }
  print "\n";
}

sub shared {
  my ($m1,$m2)=@_;
  my $n=0;
  foreach my $k (keys %{$m1}) {
    if(exists $m2->{$k}) {
      $n+=1;
    }
  }
  return $n;
}
