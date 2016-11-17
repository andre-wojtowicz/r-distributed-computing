make.psock.cluster = function(names, connection.timeout, ...)
{
    if (is.numeric(names))
    {
        names = as.integer(names[1])
        if (is.na(names) || names < 1)
        {
            stop.script("Numeric 'names' must be >= 1")
        }
        names = rep("localhost", names)
    }

    parallel:::.check_ncores(length(names))
    options = parallel:::addClusterOptions(parallel:::defaultClusterOptions,
                                            list(...))
    cl = vector("list", length(names))

    for (i in seq_along(cl))
    {

        flog.info(paste0("[", i, "/", length(cl), "] Connecting to ",
                         names[[i]], " ... "))

        options.copy     = parallel:::addClusterOptions(options, NULL)
        options.out.file = parallel:::getClusterOption("outfile", options)
        if (class(options.out.file) == "lazy")
        {
            options.copy = parallel:::addClusterOptions(options,
                list("outfile" = lazy_eval(options.out.file,
                                           list(worker.id   = i,
                                                worker.name = names[i]))))
        }

        tryCatch({
            cl.node =
                evalWithTimeout(new.psock.node(names[[i]],
                                               options = options.copy,
                                               rank = i),
                                timeout = connection.timeout,
                                onTimeout = "error")
            cl[[i]] = cl.node
            flog.info("OK")},
            error = function(e) {
                if ("TimeoutException" %in% class(e))
                {
                    flog.warn("Timeout")
                } else {
                    stop.script(e)
                }
            }
        )
    }

    cl.filtered = list()
    i = 1
    for (j in seq_along(cl))
    {
        if (!is.null(cl[[j]]))
        {
            cl.filtered[[i]] = cl[[j]]
            i = i + 1
        }
    }

    if (length(cl) != length(cl.filtered))
    {
        flog.warn(paste("Unable to connect to", length(cl) - length(cl.filtered),
                        "nodes"))
    }

    if (length(cl.filtered) == 0)
    {
        stop.script("No remote workers")
    } else {
        flog.info(paste("Working on", length(cl.filtered), "nodes"))
    }

    class(cl.filtered) = c("SOCKcluster", "cluster")
    cl.filtered
}

new.psock.node = function(machine = "localhost", ...,
                          options = parallel:::defaultClusterOptions, rank)
{
    options <- parallel:::addClusterOptions(options, list(...))
    if (is.list(machine)) {
        options <- parallel:::addClusterOptions(options, machine)
        machine <- machine$host
    }
    outfile <- parallel:::getClusterOption("outfile", options)
    master <- if (machine == "localhost")
        "localhost"
    else parallel:::getClusterOption("master", options)
    port <- parallel:::getClusterOption("port", options)
    manual <- parallel:::getClusterOption("manual", options)
    timeout <- parallel:::getClusterOption("timeout", options)
    methods <- parallel:::getClusterOption("methods", options)
    useXDR <- parallel:::getClusterOption("useXDR", options)
    env <- paste0("MASTER=", master, " PORT=", port, " OUT=",
                  outfile, " TIMEOUT=", timeout, " XDR=", useXDR)
    arg <- "parallel:::.slaveRSOCK()"
    rscript <- if (parallel:::getClusterOption("homogeneous", options)) {
        shQuote(parallel:::getClusterOption("rscript", options))
    }
    else "Rscript"
    rscript_args <- parallel:::getClusterOption("rscript_args", options)
    if (methods)
        rscript_args <- c("--default-packages=datasets,utils,grDevices,graphics,stats,methods",
                          rscript_args)
    cmd <- if (length(rscript_args))
        paste(rscript, paste(rscript_args, collapse = " "), "-e",
              shQuote(arg), env)
    else paste(rscript, "-e", shQuote(arg), env)
    renice <- parallel:::getClusterOption("renice", options)
    if (!is.na(renice) && renice)
        cmd <- sprintf("nice -%d %s", as.integer(renice), cmd)
    if (manual) {
        cat("Manually start worker on", machine, "with\n    ",
            cmd, "\n")
        utils::flush.console()
    }
    else {
        if (machine != "localhost") {
            rshcmd <- parallel:::getClusterOption("rshcmd", options)
            user <- parallel:::getClusterOption("user", options)
            cmd <- shQuote(cmd)
            cmd <- paste(rshcmd, "-l", user, machine, cmd)
        }
        if (.Platform$OS.type == "windows") {
            system(cmd, wait = FALSE, input = "")
        }
        else system(cmd, wait = FALSE)
    }
    con <- socketConnection("localhost", port = port, server = TRUE,
                            blocking = TRUE, open = "a+b", timeout = timeout)
    structure(list(con = con, host = machine, rank = rank), class = if (useXDR)
        "SOCKnode"
        else "SOCK0node")
}

stop.cluster = function(cl.to.stop = cl)
{
    flog.info("Workers shut down")

    foreach::registerDoSEQ()
    parallel::stopCluster(cl.to.stop)
}
