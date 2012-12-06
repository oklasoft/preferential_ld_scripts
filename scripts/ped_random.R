cmd_args = commandArgs()
args = c("^sub=", "^nrandom=")
args.value = c()
for (a in args) {
	ind = grep(a, cmd_args)
	if (is.na(ind)) {
		cat(paste("Missing", a), sep="\n")
		q()
	}
	args.value = c(args.value, as.numeric(sub(a, "", cmd_args[ind])))
}
sub = args.value[1]
nrandom = args.value[2]
dat = read.table(paste("t1", sub, sep="."), header=F, colClasses="character", sep="\t")
names = as.character(dat[1,])
dat = dat[-1,]
ran1 = mapply(function(x){sample(dat$V1)}, 1:nrandom)
ran2 = mapply(function(x){sample(dat$V2)}, 1:nrandom)
data = matrix(NA, nrow=nrow(ran1), ncol=2*nrandom)
data[,seq(1,2*nrandom,2)] = ran1
data[,seq(1,2*nrandom,2)+1] = ran2
write.table(data, file=paste("t2", sub, "1", sep="."), append=F, sep="\t", col.names=F, row.names=F, quote=F)
names = apply(cbind(rep(names, nrandom), rep(1:nrandom, each=2)),1,function(x){paste(x, collapse="_")})
write.table(cbind(names, 1:length(names)), file=paste("t2", sub, "2", sep="."), append=F, sep="\t", col.names=F, row.names=F, quote=F)
