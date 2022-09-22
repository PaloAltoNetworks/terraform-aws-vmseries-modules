# Testing Terraform modules

In order to executed test prepared in folder ``tests/boostrap``, execute below command to run all tests:

```
go test -v -timeout 30m -count=1
```

If there is a need to execute tests from one file, use command:

```
go test -v -timeout 30m -count=1 output_test.go
```
