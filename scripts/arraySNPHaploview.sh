sub=$1
snvstart=$2
snvstop=$3
array=$4
dirname=$5
plink=$6
java=$7
Haploview=$8
pipeline=$9
extract=$pipeline/scripts/extract.pl
output=$pipeline/output/$dirname
tmpdir=/scratch/${USER}_${JOB_ID}
echo $tmpdir

cd $tmpdir
# generate ped file for SNPs in GWAS array
startsnv=$(head -$snvstart $output/$array.bim | tail -1 | cut -f2)
stopsnv=$(head -$snvstop $output/$array.bim | tail -1 | cut -f2)
$plink --bfile $output/$array --from $startsnv --to $stopsnv --recode --out sub$sub --output-missing-phenotype 0 --output-missing-genotype 0 --noweb # generate ped file for array SNPs
m=$(wc -l sub$sub.map | perl -ane 'print "$F[0]"')
wc -l $output/extractSNV.1.map | perl -ane '$n=$F[0]; for ($i=1; $i<=$n; $i+=400){$j=$i+399; $j=$n if ($j>$n); print "$i\t$j\t", $j-$i+1, "\n"}' > numbers
while read start end n
do
	i=$((2*start+6-1))
	j=$((2*end+6))
	cut -d" " -f$i-$j $output/extractSNV.1.ped > tmp.$sub
	paste sub$sub.ped tmp.$sub > ped.$sub
	perl -ane '$i++; print "$F[1]\t$i\n"' sub$sub.map > info.$sub
	head -$end $output/extractSNV.1.map | tail -n$n | sed "s/^/$m\t/" | perl -ane '$i++; print "g$F[2]\t", $i+$F[0], "\n"' >> info.$sub
	$java -jar $Haploview -nogui -pedfile ped.$sub -info info.$sub -out out.$sub -minMAF 0 -hwcutoff 0 -maxDistance 0 -missingCutoff 1 -minGeno 0 -dprime
	perl -ane '$i++; next if ($i==1); if ($F[0]=~/^g/ && $F[1]!~/^g/) {$F[0]=~s/^g//; print "$F[0]\t$F[4]\n"; next;} if ($F[0]!~/^g/ && $F[1]=~/^g/) {$F[1]=~s/^g//; print "$F[1]\t$F[4]\n";}' out.$sub.LD >> sub.$sub.LD
done < numbers
cat $output/targetSNV.1.ordered $output/randomSNV.1.ordered | sort | uniq > extractSNV
$extract extractSNV sub.$sub.LD 1 out.$sub 1 1
echo "#END" >> out.$sub
perl -ane '$d++; if ($d==1){$i=0;$j=0;} if ((defined($name) && $name ne $F[0]) || (/^#END/)) {print "$name\t$j\t$i\n"; $i=0; $j=0;} $name=$F[0]; $i++; $j++ if ($F[1]>=$F[3]);' out.$sub > $output/arraySNPHaploview.$sub 
 
# -minMAF <threshold>: Exclude all markers with minor allele frequency below <threshold>, which must be between 0 and 0.5. Default of 0. This option works in GUI mode.
# -hwcutoff <threshold>: Exclude markers wth a HW p-value smaller than <threshold>. <threshold> is a value between 0 and 1. Default is .001.
# -maxMendel <integer>: Markers with more than <integer> Mendel errors will be excluded. Default is 1.
# -check: Outputs marker checks to <fileroot>.CHECK
# -memory <memsize>: allocates <memsize> megabytes of memory (default 512)
# -maxDistance <distance>: Maximum intermarker distance for LD comparisons (in kilobases). Default is 500.
# -missingCutoff <threshold>: Exclude individuals with more than <threshold> fraction missing data, where <threshold> is a value between 0 and 1 with a default of 0.5.
# -minGeno <threshold>: Exclude markers with less than <threshold> fraction of nonzero genotypes. <threshold> must be between 0 and 1 with a default of 0.5. This option works in GUI mode.
 
