# Compilation

To compile the code we run we prefer the command

```
make all
```

# Get existing test cases

We can get all existing test cases running this command

```
./bin/extended-platform-tests run all --dry-run 
```

And we can use grep to filter by team or suite

for example, all test cases created by MCO team


```
./bin/extended-platform-tests run all --dry-run  |grep MCO
```


# Run a single test

To run a single test we  do it like

```
./bin/extended-platform-tests run-test "[sig-mco] MCO Author:rioliu-NonHyperShiftHOST-Critical-42347-[P1][OnCLayer] health check for machine-config-operator [Serial]"
```

We need to use the full name of the test case to run it

# Run several tests

## Piping the result of the grep 

Like this:

```
$ ./bin/extended-platform-tests run all --dry-run | grep "OLM" | ./bin/extended-platform-tests run -f -
```

## Running the tests inside a file

Like this:


```
./bin/extended-platform-tests run -f file-with-tests.txt
```

The file contains the output of the grepped dry command

### Timeout

When executing more than one test case there is a timeout. In MCO test cases this timeout has to be at least 120m

For MCO test cases the timeout has to

```
./bin/extended-platform-tests run -f file-with-tests.txt --timeout 120m
```

Only "run" can use the "--timeout" parameter, "run-test" cannot.


# Redirection

Do always redirect the output of the tests to a file when you execute them so that they can be reviewed after the execution