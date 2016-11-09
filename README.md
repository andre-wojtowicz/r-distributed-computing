# R distributed computing

In this repository I show a practical solution to massive distributed computing in R. I have successfully tested this approach in my research with ~200 remote hosts and ~800 remote connections. Brief examples concern [caret](https://topepo.github.io/caret/) package for creating predictive models and [foreach](https://cran.r-project.org/web/packages/doParallel/index.html) loop for more general parallel computing. 

The solution is based on:
 * [Microsoft R Open](http://mran.microsoft.com/), 
 * [checkpoint](https://github.com/RevolutionAnalytics/checkpoint) R library,
 * Debian-based Linux distributions.

## Quick example

Suppose you have three Debian-based machines with at least 4 GB RAM:

1. server (`192.168.0.1`),
2. two dual-core hosts (`192.168.0.2` and `192.168.0.3`; [WMI rescue](http://rescue.wmi.amu.edu.pl) - small Linux image based on Debian).

On the server you install necessary packages and R with project libraries:

```bash
[~/r-distributed-computing]$ sudo bash remote-commands.sh install_env install_mro
[~/r-distributed-computing]$ Rscript init.R
```

Then you prepare remote hosts:

```bash
[~/r-distributed-computing]$ echo "192.168.0.2
192.168.0.3" | bash remote-commands.sh configure_hosts
```

Finally, you run your calculations:

```bash
[~/r-distributed-computing]$ Rscript test.R
```
```
Scanning for packages used in this project
  |====================================================================| 100%
- Discovered 14 packages
All detected packages already installed
checkpoint process complete
---
INFO [2016-11-08 13:30:46] Creating remote PSOCK cluster
INFO [2016-11-08 13:30:46] [1/4] Connecting to 192.168.0.2 ... 
INFO [2016-11-08 13:30:46] OK
INFO [2016-11-08 13:30:46] [2/4] Connecting to 192.168.0.2 ... 
INFO [2016-11-08 13:30:46] OK
INFO [2016-11-08 13:30:46] [3/4] Connecting to 192.168.0.3 ... 
INFO [2016-11-08 13:30:47] OK
INFO [2016-11-08 13:30:46] [4/4] Connecting to 192.168.0.3 ... 
INFO [2016-11-08 13:30:47] OK
INFO [2016-11-08 13:30:47] Working on 4 nodes
INFO [2016-11-08 13:30:47] Exporting checkpoint constants
INFO [2016-11-08 13:30:54] Setting cluster RNG kind
INFO [2016-11-08 13:30:54] Registering cluster
INFO [2016-11-08 13:30:54] *************************
INFO [2016-11-08 13:30:54] Test foreach
[1] 1 2 3 4
INFO [2016-11-08 13:30:55] Test caret
Support Vector Machines with Linear Kernel 

32 samples
10 predictors

No pre-processing
Resampling: Cross-Validated (10 fold, repeated 10 times) 
Summary of sample sizes: 28, 29, 29, 29, 28, 29, ... 
Resampling results:

  RMSE      Rsquared 
  3.276949  0.8328294

Tuning parameter 'C' was held constant at a value of 1

INFO [2016-11-08 13:31:54] Workers shut down
```

## Customization

### Bash control script

The bash script `remote-commands.sh` is responsible for the server and hosts preparation for calculations. The script reads list of remote hosts from either stdin or file set in `CONNECTION_LIST_FILE` script variable (default: `remote-connection-list.txt`). 

Then the script executes internal procedures; the names and execution order of such functions are passed as script arguments, e.g. `bash remote-commands.sh configure_hosts`.

The `configure_hosts` is a short name for basic execution order:

 1. `generate_ssh_keys` - generates ssh keys to communicate with hosts (see `SSH_*` variables),
 1. `hosts_push_ssh_key` - pushes the keys to hosts and disables password authentication,
 1. `hosts_push_shell_script` - pushes the bash script to hosts,
 1. `dump_project_r_files` - gathers all R project files used in the project,
 1. `dump_r_libraries` - gathers all R libraries in `~/.checkpoint` directory,
 1. `hosts_push_project_r_files` - pushes gathered R project files to hosts,
 1. `hosts_install_env` - updates and installs packages defined in `DEBIAN_PACKAGES_TO_INSTALL`,
 1. `hosts_install_mro` - installs R defined in `MRO_*` variables,
 1. `hosts_push_r_libraries_dump` - pushes R project files to hosts,
 1. `make_remote_connection_list_nproc` - creates connection list file for R, defined in `HOSTS_FILE` (default: `remote-hosts.txt`).

You can also scan and limit hosts to those currently available through `hosts_scan_available` procedure and check if there are at least `MIN_HOSTS` available hosts.

Instead of pushing to hosts precompiled R libraries (`hosts_push_r_libraries_dump`) you can force compiling them on the hosts (`hosts_install_r_libraries`).

You may customize `MRO_INSTALL_URL` to your own mirror - from my experience the MRAN servers limit the download bandwidth in case.

If you want to make only one connection per node (regardless number of cores), you can execute `make_remote_connection_list_single` instead of `make_remote_connection_list_nproc`. You may also try to detect logical cores through setting `REMOTE_DETECT_LOGICAL_CPUS`.

Alternatively, instead of installing soft on [WMI rescue](http://rescue.wmi.amu.edu.pl), you can create and boot on hosts your own customized distro.

You can investigate hosts install logs through `hosts_check_install_log_*` functions. You can also check and clean remote worker logs through `hosts_check_worker_log` and `hosts_clean_worker_log` procedures, respectively.

The functions (excluding `hosts_scan_available`) stop the script if any part of the procedure fails.

### R project files

In the `config.R` file you may customize `checkpoint` library configuration and the logging system.

In the `config-parallel.R` you can:
 * switch between parallel computing methods (`PARALLEL.USED.METHOD` by default is `REMOTE` but for testing you can change it to `LOCAL`, so that all calculations will be done on the server); for `LOCAL` the method defined in `PARALLEL.LOCAL.METHOD` might be `PSOCK` (default) or `FORK`.
 * customize remote R session invoking parameters through `PARALLEL.REMOTE.*` variables,
 * worker logs file names are defined in `PARALLEL.*.SLAVE.OUT.FILE` and are unique among whole computing cluster.

### Working with more than 125 connections

Currently R has a hard-coded limit for number of connections, which is effectively 125. If you want to work with more connections (nodes), then on the server you have to recompile and install customized R. You may see how to set custom limit in my repository [Microsoft R Open compilation for customized cluster nodes connection limit](https://github.com/andre-wojtowicz/r-compile-customised-mro).

### Reproducibility

In caret you can control reproducibility by pre-setting seeds; see section [5.4 Notes on Reproducibility](https://topepo.github.io/caret/model-training-and-tuning.html#repro).

### Intel MKL

By default the Intel MKL support is installed with Microsoft R Open. In `config-parallel.R` you can choose in `PARALLEL.DISABLE.MKL.THREADS` variable either this library should be either disabled (default) or enabled. This can be useful in particular if you make cluster in the one-host-one-connection manner and calculations on remote nodes can benefit from [BLAS routines](https://github.com/andre-wojtowicz/blas-benchmarks).
