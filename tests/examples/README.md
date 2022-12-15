# Testing Terraform examples

In order to executed test prepared in folder ``tests/examples``, at first upgrade or install ``Terratest``:

```
go get -u github.com/gruntwork-io/terratest
go get -u github.com/gruntwork-io/terratest/modules/opa
go get -u github.com/gruntwork-io/terratest/modules/terraform
```

To execute all tests for every type of Terraform version, execute script:

```
./run_tests_multiple_tf_version.sh
```