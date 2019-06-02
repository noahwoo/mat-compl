#!/usr/bin/perl -w
# share or not
die "usage: $0 id2fid-vec field\n" if @ARGV!=2;
my ($id2id,$fi) = @ARGV;
my %id2id=();
open(II,$id2id) or die "Fail to read id2id map from $id2id.\n";
while(<II>) {
  chomp;
  my @tkns=split(/\s+/,$_);
  my $id=shift @tkns;
	$id2id{$id}=1;
} 
close(II);

while(<STDIN>) {
  chomp;
	my @tkns=split(/\s+/,$_);
	my $id=$tkns[$fi];
	if(exists $id2id{$id}) {
		print $_,"\n";
	}
}
