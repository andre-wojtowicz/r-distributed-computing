# R distributed computing

In this repository I show a practical solution to massive distributed computing in R. I have tested this approach in my research with ~200 remote hosts and ~800 remote connections. Brief examples concern [caret](https://topepo.github.io/caret/) package for creating predictive models and [foreach](https://cran.r-project.org/web/packages/doParallel/index.html) loop for more general parallel computing. 

The solution is based on:
 * [Microsoft R Open](http://mran.microsoft.com/), 
 * [checkpoint](https://github.com/RevolutionAnalytics/checkpoint) R library,
 * Debian-based Linux distributions.

## Quick example

Suppose you have three Linux machines with at least 4 GB RAM:

1. server (`192.168.0.1`; some Debian-based distribution),
2. hosts (`192.168.0.2` and `192.168.0.3`; preferably [WMI rescure](http://rescue.wmi.amu.edu.pl) - small Linux image based on Debian distribution).

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
INFO [2016-11-08 13:30:46] [1/2] Connecting to 192.168.0.2 ... 
INFO [2016-11-08 13:30:46] OK
INFO [2016-11-08 13:30:46] [2/2] Connecting to 192.168.0.3 ... 
INFO [2016-11-08 13:30:47] OK
INFO [2016-11-08 13:30:47] Working on 2 nodes
INFO [2016-11-08 13:30:47] Exporting checkpoint constants
INFO [2016-11-08 13:30:54] Setting cluster RNG kind
INFO [2016-11-08 13:30:54] Registering cluster
INFO [2016-11-08 13:30:54] *************************
INFO [2016-11-08 13:30:54] Test foreach
[1] 1 2
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

### R project files

### Working with more than 125 connections

Currently R has a hard-coded limit for number of connections, which is effecively 125. If you want to work with more connections (nodes), then on the server you have to recompile and install customized R. You may see how to set custom limit in my repository [Microsoft R Open compilation for customised cluster nodes connection limit](https://github.com/andre-wojtowicz/r-compile-customised-mro).

### Reproducibility

In caret you can control reproducibility by pre-setting seeds; see section [5.4 Notes on Reproducibility](https://topepo.github.io/caret/model-training-and-tuning.html#repro).

### Intel MKL
