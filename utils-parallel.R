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
                evalWithTimeout(parallel:::newPSOCKnode(names[[i]],
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

stop.cluster = function(cl.to.stop = cl)
{
    flog.info("Workers shut down")

    foreach::registerDoSEQ()
    parallel::stopCluster(cl.to.stop)
}
