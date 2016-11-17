# ---- config-parallel ----

PARALLEL.USED.METHOD               = "REMOTE" # LOCAL or REMOTE
PARALLEL.DISABLE.MKL.THREADS       = TRUE

PARALLEL.RENICE                    = 19 # [-20; 19] or NA

# local
PARALLEL.LOCAL.METHOD              = "PSOCK"

PARALLEL.LOCAL.NODES               = parallel::detectCores(logical = FALSE)
PARALLEL.LOCAL.CONNECTION.TIMEOUT  = 5
PARALLEL.LOCAL.SLAVE.OUT.FILE      =
    lazy(file.path(LOGGER.OUTPUT.DIR,
                   paste0("worker-local-", worker.name, "-", worker.id, ".log")))

# remote
PARALLEL.REMOTE.METHOD                    = "PSOCK"

PARALLEL.REMOTE.MASTER.IP                 = "192.168.0.1" # ip accessible from slaves
PARALLEL.REMOTE.MASTER.PORT               = 11000
PARALLEL.REMOTE.MASTER.CONNECTION.TIMEOUT = 10
PARALLEL.REMOTE.MASTER.SSH.PROGRAM        = "ssh" # ssh, ssh.exe, etc.
PARALLEL.REMOTE.MASTER.SSH.PRIV.KEY       = file.path("ssh", "rsa-priv.key")
PARALLEL.REMOTE.MASTER.SSH.NULL.DEV       = "/dev/null"
PARALLEL.REMOTE.MASTER.SSH.STRICT.HOST.KEY.CHECKING = "no"
PARALLEL.REMOTE.MASTER.SSH.SERVER.ALIVE.INTERVAL    = 30
PARALLEL.REMOTE.MASTER.SHELL.CMD          =
paste0(
  PARALLEL.REMOTE.MASTER.SSH.PROGRAM,
  " -q",
  " -o ConnectTimeout=",        PARALLEL.REMOTE.MASTER.CONNECTION.TIMEOUT,
  " -o UserKnownHostsFile=",    PARALLEL.REMOTE.MASTER.SSH.NULL.DEV,
  " -o StrictHostKeyChecking=", PARALLEL.REMOTE.MASTER.SSH.STRICT.HOST.KEY.CHECKING,
  " -o ServerAliveInterval=",   PARALLEL.REMOTE.MASTER.SSH.SERVER.ALIVE.INTERVAL,
  " -i ",                       PARALLEL.REMOTE.MASTER.SSH.PRIV.KEY)

PARALLEL.REMOTE.MASTER.SLAVES.FILE.PATH = "remote-connection-list.txt"

PARALLEL.REMOTE.SLAVE.OUT.FILE     = lazy(paste0("worker-remote-", worker.name,
                                                 "-", worker.id, ".log"))
PARALLEL.REMOTE.SLAVE.SSH.USER     = "root"
PARALLEL.REMOTE.SLAVE.RSCRIPT.PATH = "/usr/bin/Rscript"
PARALLEL.REMOTE.SLAVE.HOMOGENEOUS  = TRUE
PARALLEL.REMOTE.SLAVE.METHODS      = TRUE
PARALLEL.REMOTE.SLAVE.USEXDR       = TRUE

# perform additional custom config

if (file.exists("config-parallel.R.user"))
    source("config-parallel.R.user")
