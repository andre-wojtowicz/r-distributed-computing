# ---- config ----

# randomization and output files

SEED                   = 1337
OVERWRITE.OUTPUT.FILES = TRUE # overwrite created datasets and classifiers

# extra user configuration and init

USER.CONFIG.FILE      = "config.R.user"
USER.INIT.FILE        = "init.R.user"

# checkpoint library

CHECKPOINT.QUICK.LOAD    = FALSE # if TRUE then skip testing https and checking url
CHECKPOINT.MRAN.URL      = "http://mran.microsoft.com/"
CHECKPOINT.SNAPSHOT.DATE = "2016-07-01"

# logging system

LOGGER.OUTPUT.DIR               = "logs"
LOGGER.OUTPUT.TEST.FILE         = "output-test.log"
LOGGER.LEVEL                    = 6 # futile.logger::INFO
LOGGER.OVERWRITE.EXISTING.FILES = TRUE

# load custom config

if (file.exists(USER.CONFIG.FILE))
{
    source(USER.CONFIG.FILE)
}
