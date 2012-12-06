#! /usr/bin/perl

# To extract target information 
# ./extract.pl <target> <information> <all targets?> <output file> <turn off warnning message?>  <print info from <target>?>
# Note: The format of <target> is "target_ID\t......."
#	The format of <information> is "target_ID\t....."
#	$all_target=1: print all targets no matter whether their information is available or not.
#	$all_target=0: print only the targets that present in <information> 
#	$warnoff = 1: Don't print warning message in screen.
#	$warnoff = 0: Pint warning message in screen.
#	$addprint = 1: print additional information in <target> file
#	       = 0: do not print
# Initial make: Qianqian 7/3/06
# Last update: Qianqian 11/18/2010

my ($target, $info, $all_target, $output, $warnoff, $addprint) = @ARGV; 
open (IN, "<$info") or die "Can't open $info for reading!\n";
my %all;
while (<IN>) {
	next if (/^#/);
	chomp;
	my @array = split (/\t/, $_);
	push(@{$all{$array[0]}}, $_);
}
close IN;
#foreach (keys(%all)) {
#	print "$_\n";
#}
open (IN, "<$target") or die "Can't open $target for reading!\n";
open (OUT, ">$output") or die "Can't open $output for writing!\n";
my @warning;
while (<IN>) {
	next if (/^#/);
	chomp;
	my @array = split (/\t/, $_);
	my @content = @array;
	shift(@content);
	if (defined($all{$array[0]})) {
		if (@{$all{$array[0]}} > 1) {
			my $message = "$array[0] has multiple hits!";	
			push (@warning, $message);
		}
		foreach my $hit (@{$all{$array[0]}}) {
			print OUT "$hit";
			print OUT "\t", join("\t", @content) if ($addprint);
			print OUT "\n";
		}
	}
	else {
		#print OUT "$_\n" if ($all_target);
		if ($all_target) {
			print OUT "$array[0]";
			print OUT "\t", join("\t", @content) if ($addprint);
			print OUT "\n";
		}
	}
}
close IN;
close OUT;
if (@warning > 0) {
	my $file = $output . ".warn";
	warn "See $file for warning message!\n" if (!$warnoff);
	open (OUT, ">$file") or die "Can't open $file for writing!\n";
	foreach (@warning) {
		print OUT "$_\n";
	}
	close OUT;
}
