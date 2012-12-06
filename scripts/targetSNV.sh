tag=$1
dirname=$2
array=$3
name=$4
distcutoff=$5
maf=$6
mafcutoff=$7
rarethangwas=$8
hwecutoff=$9
r2cutoff=${10}
gwasmafcutoff=${11}
gwashwecutoff=${12}
plink=${13}
java=${14}
Haploview=${15}
R=${16}
pipeline=${17}
extract=$pipeline/scripts/extract.pl
Rscript=$pipeline/scripts
arraydir=$pipeline/input/GWAS_array
input=$pipeline/input/SNVcollection
output=$pipeline/output
tmpdir=/scratch/${USER}_${JOB_ID}
echo $tmpdir

cd $tmpdir
if [ "$rarethangwas" = "Y" ]
then
	mafcutoff=$(echo -e "$maf\t$mafcutoff" | perl -ane 'if ($F[0]<$F[1]){print "$F[0]";}else {print "$F[1]"}')
fi
echo $mafcutoff
# get the SNVs that are $distcutoff around the GWAS SNP with MAF less than the GWAS SNP and no greater than $mafcutoff 
chr=$(echo $name | sed s/\:.*//)
pos=$(echo $name | perl -ane 'if ($F[0]=~/\w+:(\d+)\w\w/){print "$1\n"}')
start=$((pos-distcutoff))
end=$((pos+distcutoff))
$plink --bfile $input/SNVcollection --chr $chr --from-bp $start --to-bp $end --hwe $hwecutoff --hardy --make-bed --out step1 --noweb
$plink --bfile step1 --freq --out step1 --noweb # get MAF
$R --no-save --slave --args bim=step1.bim nrandom=2000 < $Rscript/randomSNV.R # randomly draw 2000 SNVs
sed "s/^/$mafcutoff/" step1.frq | perl -ane 'next if ($F[2] eq "SNP"); if ($F[5]<=$F[0]) {print "$F[2]\n"}' > targetSNV # SNVs with MAF <= the GWAS SNP and no greater than 15%

# get the SNPs on GWAS array on the same chromosome
echo $array | sed 's/_/\n/g' > arraylist
rm -f extract.list
while read arr
do
	echo $arr
	cut -f2 $arraydir/$arr.snptable >> extract.list
done < arraylist 
$plink --bfile $input/SNVcollection --chr $chr --extract extract.list --maf $gwasmafcutoff --hwe $gwashwecutoff --make-bed --out $array --noweb # Note: PLINK only extract unique SNPs if there are redundant SNPs in extract.list 
$plink --bfile $array --snp "$name" --recode --out $tag --output-missing-phenotype 0 --output-missing-genotype 0 --noweb # generate ped file for the discovery SNP
# exclude target SNVs that are present in the GWAS array
perl -ane 'print "$F[1]\t1\n"' $array.bim > tmp
$extract targetSNV tmp 1 out 0 0
perl -ane 'print "$_" if (@F==1)' out > targetSNV

# get MAF, HWE info
perl -ane 'print "$F[1]\t$F[2]\t$F[4]\n"' step1.frq > frq # name, MA, MAF
perl -ane 'next if ($F[2] ne "ALL"); print "$F[1]\t$F[5]\t$F[8]\n"' step1.hwe > hwe # name, geno, HWE p-value 
for file in randomSNV targetSNV
do
	$extract $file frq 1 out 0 0
	mv out $file 
	$extract hwe $file 0 out 0 1 
	mv out $file # in $file: name, minor allele, maf, geno, hwe_p  
done

# calculate the LD between SNVs and the dicovery SNP
cut -f1 targetSNV randomSNV | sort |uniq > extractSNV
$plink --bfile step1 --extract extractSNV --recode --out step1_1 --output-missing-phenotype 0 --output-missing-genotype 0 --noweb # generate ped file for the SNVs
wc -l step1_1.map | perl -ane '$n=$F[0]; for ($i=1; $i<=$n; $i+=500){$j=$i+499; $j=$n if ($j>$n); print "$i\t$j\t", $j-$i+1, "\n"}' > numbers
rm -f data
while read start end n
do
	echo -e "$tag\t1" > target.info
	head -$end step1_1.map | tail -n$n | perl -ane '$i++; print "$F[1]\t", $F[3]+1, "\n"' >> target.info
	i=$((2*start+6-1))
	j=$((2*end+6))
	echo -e "$i\t$j"
	cut -d" " -f$i-$j step1_1.ped > tmp
	paste $tag.ped tmp > target.ped
	$java -jar $Haploview -nogui -pedfile target.ped -info target.info -out target -minMAF 0 -hwcutoff 0 -maxDistance 0 -missingCutoff 1 -minGeno 0 -dprime 
	perl -ane 'next if (/^#/); print "$F[0]\t$F[2]\t$F[4]\n" if ($F[1]=~/^rs/); print "$F[1]\t$F[2]\t$F[4]\n" if ($F[0]=~/^rs/)' target.LD >> data # name, D', r2
done < numbers
$extract extractSNV data 1 out 0 0
perl -ane 'print "$_" if (@F!=3)' out > extractSNV.noLD
n=$(wc -l extractSNV.noLD | perl -ane 'print "$F[0]"')
if [ $n -gt 0 ]
then
	echo "Warning: LD is not available for some SNPs! see extractSNV.noLD"
	mv extractSNV.noLD $output/${dirname}_${tag}
fi
$extract targetSNV data 0 out 0 1 
sed "s/^/$r2cutoff\t/" out > tmp
perl -ane 'if ($F[3]>$F[0]){shift(@F); print join("\t", @F), "\n"}' tmp | sort -t"	" -k3 -g -r > targetSNV.1.ordered
perl -ane 'if ($F[3]<=$F[0]){shift(@F); print join("\t", @F), "\n"}' tmp | sort -t"	" -k3 -g -r > targetSNV.lowr2
$extract randomSNV data 0 out 0 1
sort -t"	" -k3 -g -r out > randomSNV.1.ordered

# generate ped file for the SNVs 
cut -f1 targetSNV.1.ordered randomSNV.1.ordered | sort | uniq > extractSNV
$plink --file step1_1 --extract extractSNV --recode --out extractSNV.1 --output-missing-phenotype 0 --output-missing-genotype 0 --noweb
mv targetSNV.1.ordered targetSNV.lowr2 randomSNV.1.ordered extractSNV.1.ped extractSNV.1.map $tag.ped $tag.map $array.bed $array.bim $array.fam $output/${dirname}_${tag}

# 
# Haploview:
# when calculating pairwise LD, Haploview only uses the genotypes that are not missing for both markers.
# -skipcheck: Skip all the genotype data quality checks and uses all markers for all analyses.
# Note: I notice LD of some SNPs are still missing when using -skipcheck when compare with the results using -minMAF 0 -hwcutoff 0 -maxDistance 0 -missingCutoff 1 -minGeno 0
# -minMAF <threshold>: Exclude all markers with minor allele frequency below <threshold>, which must be between 0 and 0.5. Default of 0. This option works in GUI mode. 
# -hwcutoff <threshold>: Exclude markers wth a HW p-value smaller than <threshold>. <threshold> is a value between 0 and 1. Default is .001.
# -maxMendel <integer>: Markers with more than <integer> Mendel errors will be excluded. Default is 1.
# -check: Outputs marker checks to <fileroot>.CHECK
# -memory <memsize>: allocates <memsize> megabytes of memory (default 512)
# -maxDistance <distance>: Maximum intermarker distance for LD comparisons (in kilobases). Default is 500.
# -missingCutoff <threshold>: Exclude individuals with more than <threshold> fraction missing data, where <threshold> is a value between 0 and 1 with a default of 0.5. 
# -minGeno <threshold>: Exclude markers with less than <threshold> fraction of nonzero genotypes. <threshold> must be between 0 and 1 with a default of 0.5. This option works in GUI mode. 

