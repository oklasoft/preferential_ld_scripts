#!/usr/bin/perl

# To obtain the phastCons or phyloP score at specified positions 
# ./getConservationScore.pl <query> <data> <output>
# Note: 1. The format of <query> is "name\tchromosome\tpos". The position is 1-based.
#          All items in <query> must be on the same chromosome and should have been sorted in increasing order of the positions.
#       2. <data> is the phastCons score or phyloP score download from UCSC. Should be from the same chromosome as the items in <query>
#       3. Only print the items in <query> that have conservation scores.
#       4. The output format is "name\tscore\n" 
#
# Author: Qianqian 

my ($query, $data, $output) = @ARGV;
open (IN, "<$query") or die "Can't open $query for reading!\n";
my $chr;
my @q_name;
my @q_pos;
while (<IN>) {
	chomp;
	my @array = split (/\t/, $_);
	if (!defined($chr)) {
		$chr = $array[1];
	} elsif ($chr ne $array[1]) {
		die "Error $_: chromosome is not $chr!\n";
	}
	push (@q_name, $array[0]);
	push (@q_pos, $array[2]);
}
close IN;
#print "$q_pos[0]\t$q_pos[$#q_pos]\n";

open (IN, "<$data") or die "Can't open $data for reading!\n";
open (OUT, ">$output") or die "Can't open $output for writing!\n";
my $point = 0;
my ($start, $i) = (0)x2;
my %score;
while (<IN>) {
	chomp;
	if (/fixedStep chrom=chr(\w+) start=(\d+) step=(\d+)/){
		#print "#$start\t", $start+$i, "\n";
		if (@q_pos>0 && $start<=$q_pos[$#q_pos] && ($start+$i)>=$q_pos[0]) {
			matchscore(\@q_name, \@q_pos, \%score);
			last if (@q_pos == 0);
			#print "$q_pos[0]\t$q_pos[$#q_pos]\n";
		}
		%score = (); # empty hash 
		die "Error: the conservation score does not correspond to $chr!\n" if ($1 ne $chr); 
		$start = $2; 
		my $step = $3; 
		die "Error $_: step is not 1!\n" if ($step != 1);
		last if ($start > $q_pos[$#q_pos]); # empty hash and break the loop when the query block is behind the score block 
		$i = -1; 
	} elsif (/^-?\d+/) {
		$i++;
		$score{($start+$i)} = $_; 
	} else {
		die "Error $_: unknown format!\n";
	}
}
close IN;
if (@q_pos>0 && $start<=$q_pos[$#q_pos] && ($start+$i)>=$q_pos[0]) {
	matchscore(\@q_name, \@q_pos, \%score);
}
close OUT;

##### subroutines #####
sub matchscore {
	my ($q_name_ref, $q_pos_ref, $score_ref) = @_;
	my @scorepos = sort {$a <=> $b} keys (%$score_ref);
	#print "#$scorepos[0]\t$scorepos[$#scorepos]\n";
	my $j = 0;
	while (@$q_pos_ref>0) {
		last if ($$q_pos_ref[$j]>$scorepos[$#scorepos]);
		if (defined($$score_ref{$$q_pos_ref[$j]})){
			#print "$$q_pos_ref[$j]\n";
			print OUT "$$q_name_ref[$j]\t$$score_ref{$$q_pos_ref[$j]}\n" ;
		}
		shift(@$q_pos_ref);
		shift(@$q_name_ref);
	}
}
