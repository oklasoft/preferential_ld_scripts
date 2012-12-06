sub=$1
dirname=$2
tag=$3
nrandom=$4
snvstart=$5
snvstop=$6
java=$7
Haploview=$8
R=$9
pipeline=${10}
Rscript=$pipeline/scripts
dir=$pipeline/output/${dirname}_${tag}
tmpdir=/scratch/${USER}_${JOB_ID}
echo $tmpdir

cd $tmpdir
cut -d" " -f1-6 $dir/$tag.ped > front.$sub
cut -d" " -f7-8 $dir/$tag.ped > snpped.$sub 
while [ $snvstart -le $snvstop ] 
do
	i=$((2*snvstart+6-1))
	j=$((i+1))
	echo -e "$i\t$j"
	snv=$(head -$snvstart $dir/targetSNV.2.map | tail -1| cut -f2)
	grep "^$snv	" $dir/targetSNV.2.ordered > data.$sub
	echo -e "$snv\t$tag" > t1.$sub
	cut -d" " -f$i-$j $dir/targetSNV.2.ped > t.$sub
	paste front.$sub t.$sub snpped.$sub | perl -F"\t" -ane 'chomp($F[$#F]); next if ($F[1] eq "0 0" || $F[2] eq "0 0"); print "$_"' > tmp.$sub
	cut -f2-3 tmp.$sub >> t1.$sub # generate ped file and remove missing genotype
	cut -f1 tmp.$sub > front.tmp	
	$R --no-save --slave --args sub=$sub nrandom=$nrandom < $Rscript/ped_random.R
	wc -l t2.$sub.2 | perl -ane '$n=$F[0]; for ($i=1; $i<=$n; $i+=500){$j=$i+499; $j=$n if ($j>$n); print "$i\t$j\t", $j-$i+1, "\n"}' > numbers
	while read start end n
	do
		cut -f$start-$end t2.$sub.1 > t.$sub
		paste front.tmp t.$sub > tmp.$sub.ped
		head -$end t2.$sub.2 | tail -n$n > tmp.$sub.info
		$java -jar $Haploview -nogui -pedfile tmp.$sub.ped -info tmp.$sub.info -out out.$sub -minMAF 0 -hwcutoff 0 -maxDistance 0 -missingCutoff 1 -minGeno 0 -dprime
		perl -ane '$i++; next if ($i==1); if($F[0]=~/(\S+)_(\d+)/){$name1=$1; $id1=$2;}else {die "Error $_: Incorrect format!\n";} if($F[1]=~/(\S+)_(\d+)/){$name2=$1; $id2=$2;}else {die "Error $_: Incorrect format!\n";} next if ($id1 ne $id2 || $name1 eq $name2); print "$name2\t$F[2]\t$F[4]\n" if ($name1=~/^rs/); print "$name1\t$F[2]\t$F[4]\n" if ($name2=~/^rs/);' out.$sub.LD >> data.$sub
	done < numbers
	perl -ane '$i++; if ($i==1){$r2=$F[4]; $j=0; next;} $j++ if ($F[2]>=$r2); print "$F[0]\t$j\t", $i-1, "\n"' data.$sub | tail -1 >> SNVrandomLD.$sub # count how many times the randomization has r2 >= the real value 
	snvstart=$((snvstart+1))
done 
mv SNVrandomLD.$sub $dir
 
# -minMAF <threshold>: Exclude all markers with minor allele frequency below <threshold>, which must be between 0 and 0.5. Default of 0. This option works in GUI mode.
# -hwcutoff <threshold>: Exclude markers wth a HW p-value smaller than <threshold>. <threshold> is a value between 0 and 1. Default is .001.
# -maxMendel <integer>: Markers with more than <integer> Mendel errors will be excluded. Default is 1.
# -check: Outputs marker checks to <fileroot>.CHECK
# -memory <memsize>: allocates <memsize> megabytes of memory (default 512)
# -maxDistance <distance>: Maximum intermarker distance for LD comparisons (in kilobases). Default is 500. Enter a value of zero to force all pairwise computations. 
# -missingCutoff <threshold>: Exclude individuals with more than <threshold> fraction missing data, where <threshold> is a value between 0 and 1 with a default of 0.5.
# -minGeno <threshold>: Exclude markers with less than <threshold> fraction of nonzero genotypes. <threshold> must be between 0 and 1 with a default of 0.5. This option works in GUI mode.

