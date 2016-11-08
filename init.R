# ---- init ----

# stop cluster if it is already registered

if ("cl" %in% ls() && !is.null(foreach::getDoParName()))
{
    if (foreach::getDoParName() != "doSEQ")
    {
        flog.info("Stopping already registered cluster")
        stop.cluster()
    }
}

# clear envirionment

rm(list = ls())

# load setup variables

source("config.R")

# load library management system

suppressPackageStartupMessages(
    library(checkpoint)
)

if (CHECKPOINT.QUICK.LOAD) # approx. x10 faster checkpoint library loading
{
    # assume https
    options(checkpoint.mranUrl = CHECKPOINT.MRAN.URL)
    # disable url checking
    assignInNamespace("is.404", function(mran, warn = TRUE) { FALSE },
                      "checkpoint")
}

checkpoint(CHECKPOINT.SNAPSHOT.DATE, verbose = TRUE, scanForPackages = TRUE)

# load logging system

suppressPackageStartupMessages(
    library(futile.logger)
)

invisible(flog.threshold(LOGGER.LEVEL))

if (!dir.exists(LOGGER.OUTPUT.DIR))
{
    dir.create(LOGGER.OUTPUT.DIR, recursive = TRUE)
}

# load libraries

suppressPackageStartupMessages({
    library(plyr)
    library(dplyr)
    library(ttutils)
    library(lazyeval)
    library(R.utils)
    library(RCurl)
    # caret - core
    library(caret)
    library(e1071)
    # caret - classifiers
    library(kernlab) # SVM
    # parallel computation
    library(doParallel)
})

# load helper functions

source("utils.R")

# perform additional custom init

if (file.exists(USER.INIT.FILE))
{
    source(USER.INIT.FILE)
}
