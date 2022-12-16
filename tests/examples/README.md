# Testing Terraform examples

In order to executed test prepared in folder ``tests/examples``, at first upgrade or install ``Terratest``:

```
go get -u github.com/gruntwork-io/terratest
go get -u github.com/gruntwork-io/terratest/modules/opa
go get -u github.com/gruntwork-io/terratest/modules/terraform
```

Script testing code with different Terraform version is using [tfenv](https://github.com/tfutils/tfenv), which needs to be installed before running tests.

In order to execute all tests for every type of Terraform version, type command:

```
./run_tests_multiple_tf_version.sh
```