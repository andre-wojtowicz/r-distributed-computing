# ---- init ----

source("init.R")

setup.logger(file.path(LOGGER.OUTPUT.DIR, LOGGER.OUTPUT.TEST.FILE),
             LOGGER.OVERWRITE.EXISTING.FILES)

source("init-parallel.R")

# ---- foreach-test ----

flog.info("Test foreach")

fdata = foreach::foreach(i = 1:foreach::getDoParWorkers(),
                 .combine = c) %dopar%
{
    Sys.sleep(1)
    return(i)
}

print(fdata)

# ---- caret-test ----

flog.info("Test caret")

tr.control = caret::trainControl(method        = "repeatedcv",
                                 number        = 10,
                                 repeats       = 10,
                                 allowParallel = TRUE)

model = caret::train(form      = mpg ~ .,
                     data      = mtcars,
                     method    = "svmLinear",
                     trControl = tr.control)

print(model)

# ---- shutdown ----

stop.cluster()
