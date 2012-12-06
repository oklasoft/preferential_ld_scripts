cmd_args = commandArgs()
args = c("^bim=", "^nrandom=")
args.value = c()
for (a in args) {
        ind = grep(a, cmd_args)
        if (is.na(ind)) {
                cat(paste("Missing", a), sep="\n")
                q()
        }
        args.value = c(args.value, sub(a, "", cmd_args[ind]))
}
bim = args.value[1]
nrandom = as.numeric(args.value[2])
dat = read.table(bim, header=F, as.is=T)
if (nrow(dat) < nrandom) {
	cat(paste("Warn:", nrow(dat), "<", nrandom, sep=" "), sep="\n")
	nrandom = nrow(dat)
}
write.table(sample(dat[,2], nrandom), file="randomSNV", row.names=F, col.names=F, quote=F, sep="\t", append=F)
