snplist=$1
plink=$2
pipeline=$3
extract=$pipeline/scripts/extract.pl
input=$pipeline/input/SNVcollection
arraydir=$pipeline/input/GWAS_array
dir=$pipeline/input/GWASsnps
tmpdir=/scratch/${USER}_${JOB_ID}
echo $tmpdir

cd $tmpdir
rm -f discoverySNP.list
while read tag dirname array other
do
	echo -e "$tag\t${array}"
	if [ -e $arraydir/${array}.snptable ]
	then
		newname=$(grep -P "^$tag\t" $arraydir/${array}.snptable | cut -f2)
	else
		echo "$array" | sed 's/_/\n/g' > arraylist
		rm -f snptable
		while read arr
		do
			echo $arr
			cat $arraydir/${arr}.snptable >> snptable
		done < arraylist
		grep -P "^$tag\t" snptable | sort | uniq > tmp
		n=$(wc -l tmp | perl -ane 'print "$F[0]"')
		if [ $n -gt 1 ]
		then
			echo "Error: Multiple hits for $tag!"
			cat tmp
			continue
		fi
		newname=$(grep -P "^$tag\t" snptable | sort | uniq | cut -f2)
	fi
	if [ -z "$newname" ]
	then
		echo "Error: Can't find $tag in ${array}.snptable!"
		continue
	fi 
	echo -e "$newname\t$tag" >> discoverySNP.list
done < $dir/$snplist
sort discoverySNP.list | uniq > tmp
mv tmp discoverySNP.list
$extract discoverySNP.list $input/SNVcollection.lmiss 1 discoverySNP.out 0 1
perl -ane 'if (@F==2){print "Error: $F[$#F] is not in SNVcollection!\n"; next;} if ($F[3]>0.1){print "Error: $F[$#F] is missing in $F[1]/$F[2]=$F[3] samples!\n";}' discoverySNP.out
perl -ane 'print "$F[0]\t$F[$#F]\n" if (@F>2 && $F[3] <= 0.1)' discoverySNP.out > discoverySNP.list
cut -f1 discoverySNP.list > extract.list
$plink --bfile $input/SNVcollection --extract extract.list --freq  --out discoverySNP --noweb # get MAF 
$plink --bfile $input/SNVcollection --extract extract.list --hardy --out discoverySNP --noweb # HWE test 
perl -ane 'next if ($F[1] eq "SNP"); print "$F[1]\t$F[2]\t$F[4]\n"' discoverySNP.frq > freq # SNV name, minor allele, MAF
perl -ane 'if ($F[2] eq "ALL"){print "$F[1]\t$F[5]\t$F[8]\n"}' discoverySNP.hwe > hwe # SNV name, geno, HWE p-value
$extract discoverySNP.list hwe 0 out 0 1 
$extract out freq 0 out2 0 1
perl -F"\t" -ane 'chomp($F[$#F]); print "$F[5]\t$F[0]\t$F[1]\t$F[2]\t$F[3]\t$F[4]\n"' out2 > discoverySNP.info # rs#, SNV name, minor allele, MAF, geno, HWE p-value
$extract $dir/$snplist discoverySNP.info 0 $dir/$snplist.info 0 1
cut -f1,2 $dir/$snplist > tmp
cut -f1,7 $dir/$snplist.info >> tmp
sort tmp | uniq -c | perl -ane 'chomp; $_=~s/^\s+$F[0]\s//; print "Error: Cannot get info for \"$_\"\n" if ($F[0]==1)'
