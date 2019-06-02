#!/usr/bin/perl -w
# share or not
die "usage: $0 id2id-map\n" if @ARGV!=1;
my $id2id = shift @ARGV;
my %id2id=();
open(II,$id2id) or die "Fail to read id2id map from $id2id.\n";
while(<II>) {
  chomp;
  my @tkns=split(/\s+/,$_);
  my $id=shift @tkns;
  foreach(my $i=0; $i<@tkns; $i++) {
    my ($k,$v)=split(/:/, $tkns[$i]);
    $id2id{-$id}{$k}=$v;
  }
} 
close(II);
foreach my $id (keys %id2id) {
  my $map=$id2id{$id};
  my $buff="";
  my $one=0;
  foreach my $k (sort {$a<=>$b} keys %{$map}) {
    if(exists $id2id{$k}) {
      $buff=$buff . " $k:" . $map->{$k};
      $one=1;
    }
  }
  if($one==1) {
    print sprintf("%d",-$id), $buff,"\n";
  }
}
