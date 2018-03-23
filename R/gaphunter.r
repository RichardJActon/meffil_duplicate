#' @title gaphunter
#' @name gaphunter
#' @param object a matrix or object of class: "GenomicRatioSet", "GenomicMethylSet", "MethylSet", or"RatioSet"
#' @param threshold (default = 0.05)
#' @param keepOutliers (default = FALSE)
#' @param outCutoff (default = 0.01)
#' @param verbose (default = TRUE)
#' gaphunter() function from:
#' https://epigeneticsandchromatin.biomedcentral.com/articles/10.1186/s13072-016-0107-z
#' copied with minor modification from https://raw.githubusercontent.com/kasperdanielhansen/minfi/master/R/gaphunter.R (2018-03-23)
#' @export
gaphunter <- function(object, threshold = 0.05, keepOutliers = FALSE,
					  outCutoff = 0.01, verbose = TRUE) {
	if ((threshold <= 0) || (threshold >= 1))
		stop("[gaphunter] 'threshold' must be between 0 and 1.") 
	if ((outCutoff <= 0) || (outCutoff >= 0.5))
		stop("[gaphunter] 'outCutoff' must be between 0 and 0.5.") 
	if (is(object, "GenomicRatioSet") || is(object, "GenomicMethylSet") ||
		is(object, "MethylSet") || is(object,"RatioSet")) {
		if(verbose)
			message("[gaphunter] Calculating beta matrix.")
		Beta <- getBeta(object)
	} else {
		if(is(object,"matrix")) {
			test <- matrixStats::rowRanges(object)
			if(sum(test[,1] < 0,na.rm = TRUE) == 0 && sum(test[,2] > 1,na.rm = TRUE) == 0) {
				Beta <- object } else { stop("[gaphunter] Matrix must be of Beta values with range from 0 to 1") }
		} else {
			stop("[gaphunter] Object must be one of (Genomic)RatioSet, (Genomic)MethylSet, or matrix")
		}
	}
	nacheck <- rowSums(is.na(Beta))
	if (sum(nacheck > 0) > 0) {
		if(verbose)
			message("[gaphunter] Removing probes containing missing beta values.")
		Beta <- Beta[which(nacheck == 0),]
	}
	
	if (verbose) {
		message("[gaphunter] Using ",prettyNum(nrow(Beta),big.mark = ",",scientific = FALSE),
				" probes and ",prettyNum(ncol(Beta),big.mark = ",",scientific = FALSE)," samples.")
		message("[gaphunter] Searching for gap signals.")
	}
	
	sorting <- t(apply(Beta, 1, sort.int, method = "quick", index.return = TRUE))
	sortedindices <- lapply(sorting, function(n) { return(n$ix) })
	sortedbeta <- do.call("rbind", lapply(sorting, function(n) {return(n$x)} ))
	rownames(sortedbeta) <- rownames(Beta) 
	diffs <- matrixStats::rowDiffs(sortedbeta) 
	gapind <- rowSums(diffs > threshold)
	sortedindices <- lapply(which(gapind > 0), function(h) { return(sortedindices[[h]]) })
	sortedbeta <- sortedbeta[which(gapind > 0),]
	diffs <- diffs[which(gapind > 0),]
	gapind <- gapind[which(gapind > 0)]
	
	breakpoints <- apply(diffs,1,function(x) { return(which(x > threshold)) })
	
	returngroups <- function(x,y) {
		template <- rep(1, ncol(sortedbeta))
		count <- 2
		for (j in x) {
			template[y[(j+1):length(y)]] <- count
			count <- count+1
		}
		return(template)
	}
	
	groupanno <- t(mapply(returngroups, breakpoints, sortedindices))
	maxGroups <- max(groupanno)
	gapanno <- matrix(0, nrow = nrow(groupanno), ncol = maxGroups + 1)
	gapanno[,1] <- matrixStats::rowMaxs(groupanno)
	for(ii in 1:maxGroups) {
		gapanno[, ii + 1] <- matrixStats::rowCounts(groupanno, value = ii)
	}
	## gapanno <- apply(groupanno, 1, function(k) {
	##	 tempgap <- rep(0, max(gapind) + 2)
	##	 kl <- length(unique(k))
	##	 tempgap[1] <- kl 
	##	 tempgap[1 + 1:kl] <- table(k)
	##	 return(tempgap)
	## })
	## gapanno <- t(gapanno)
	rownames(gapanno) <- rownames(sortedbeta)
	rownames(groupanno) <- rownames(sortedbeta)
	
	if(verbose)
		message("[gaphunter] Found ",
				prettyNum(nrow(gapanno),big.mark = ",",scientific = FALSE), " gap signals.")
	
	if (keepOutliers == FALSE) {
		if (verbose)
			message("[gaphunter] Filtering out gap signals driven by outliers.")
		markme <- unlist(lapply(1:nrow(gapanno), function(blah) {
			analyze <- gapanno[blah, -1]
			maxgroup <- which(analyze == max(analyze,na.rm=TRUE))
			if (length(maxgroup) == 1) {
				if(sum(analyze[-maxgroup],na.rm=TRUE) < outCutoff*ncol(Beta)) {
					return(blah)
				}
			}
		}))
		if (length(markme) > 0) {
			gapanno <- gapanno[-markme,]
			groupanno <- groupanno[-markme,]
		}
		if (verbose)
			message("[gaphunter] Removed ",prettyNum(length(markme),big.mark = ",",scientific = FALSE),
					" gap signals driven by outliers from results.")
	}
	gapanno <- data.frame(gapanno)
	
	colnames(gapanno) <- c("Groups", paste0("Group",1:(ncol(gapanno)-1)))
	
	algorithm <- list("threshold" = threshold, "outCutoff" = outCutoff, "keepOutliers" = keepOutliers)
	
	return(list("proberesults" = gapanno, "sampleresults" = groupanno, "algorithm" = algorithm))
}
