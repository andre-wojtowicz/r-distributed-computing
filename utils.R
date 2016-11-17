
# additional functions

setup.logger = function(output.file, overwrite.existing.files)
{
    if (overwrite.existing.files & file.exists(output.file))
    {
        file.remove(output.file)
    }

    invisible(flog.appender(appender.tee(output.file)))
}


stop.script = function(error)
{
    if (is.character(error))
    {
        flog.error(error)
    } else if ("message" %in% attributes(x)$names) {
        flog.error(error$message)
    } else {
        try(flog.error(getMessage(error)), silent = TRUE)
    }

    throw(error)
}
