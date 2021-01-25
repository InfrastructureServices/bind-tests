# Fedora BIND tests

Initial part of these test were provided by Red Hat.
They provide Continuous Integration on [Fedora](https://fedoraproject.org) BIND builds and merge requests.
It would be used from [standard-test-roles](https://docs.fedoraproject.org/en-US/ci/standard-test-roles/) interface.

Basic metadata are in [fmf](https://fmf.readthedocs.io/en/latest/overview.html),
tests are written in [beakerlib](https://github.com/beakerlib/beakerlib).

Use `fmf show` tool to filter current tests.
Fedora tests moved to [test namespace](https://src.fedoraproject.org/tests/bind) in Fedora Package Sources.

## Test run

Container check not yet works, but localhost default is unsafe!
In future, it should be possible to run this testsuite using these commands:

    dnf install -y tmt podman
    tmt run

It is possible to test on local machine. 
Testing on temporary machines is suggested, it might change existing configuration!

To test in on local machine, run:

    tmt run --all provision --how local
