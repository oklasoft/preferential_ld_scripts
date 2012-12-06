dirname=$1
array=$2
arraysnpcutoff=$3
plink=$4
pipeline=$5
output=$pipeline/output/${dirname}
extract=$pipeline/scripts/extract.pl

if [ ! -d "$output" ]
then
	echo "Error: $output doesn't exist!"
	exit
fi
cd $output
nsnp=$(wc -l $array.bim | perl -ane 'print "$F[0]"')
cat arraySNPHaploview.* > data
for file in targetSNV.1.ordered randomSNV.1.ordered
do 
	$extract $file data 1 out 1 1
	echo "#END" >> out
	name=$(echo $file | sed 's/1/2/')
	perl -ane 'if ((defined($name) && $name ne $F[0]) || (/^#END/)) {print "$name\t", $j/$i, "\t$j/$i\t$info\n"; $i=0; $j=0;} $name=$F[0]; $j+=$F[1]; $i+=$F[2]; foreach (1..3){shift(@F);} $info=join("\t", @F);' out | sort -t"	" -k2 -g > $name 
	if [ $file = "targetSNV.1.ordered" ] 
	then
		echo -e "$nsnp\t$arraysnpcutoff" > tmp
		cat $name >> tmp
		perl -ane '$i++; if ($i==1){$nsnp=$F[0]; $cutoff=$F[1]; next;} my @t=split("/",$F[2]); die "Error: $t[1] != the number of SNPs on chip ($nsnp)!\n" if ($t[1] != $nsnp); print "$_" if ($F[1]<=$cutoff)' tmp > targetSNV.2.ordered
		perl -ane '$i++; if ($i==1){$nsnp=$F[0]; $cutoff=$F[1]; next;} my @t=split("/",$F[2]); die "Error: $t[1] != the number of SNPs on chip ($nsnp)!\n" if ($t[1] != $nsnp); print "$_" if ($F[1]>$cutoff)' tmp > targetSNV.arraySNPRM 
	fi
done
# generate ped file for the SNVs
cut -f1 targetSNV.2.ordered > extract.list
$plink --file extractSNV.1 --extract extract.list --recode --out targetSNV.2 --output-missing-phenotype 0 --output-missing-genotype 0 --noweb
rm -f out tmp arraySNPHaploview.* extract.list data
