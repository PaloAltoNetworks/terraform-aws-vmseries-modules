# Quick start

## How to execute tests

Testing Terraform modules:
1. Install required binaries:
    * Terraform at the specific version that you'd like to test: https://developer.hashicorp.com/terraform
    * Go at the latest 1.* version: https://golang.org/
2. Configuration authentication settings e.g. use https://github.com/Nike-Inc/gimme-aws-creds or set ``AWS_REGION`` environment variable and also ``AWS_ACCESS_KEY_ID``, ``AWS_SECRET_ACCESS_KEY``, or similar.
3. Get ``terratest`` package by running command:
```bash
go get -u github.com/gruntwork-io/terratest
```
4. Execute test for module using commands e.g for ``bootstrap`` module:
```bash
cd tests/bootstrap
go test -v -timeout 30m -count=1
```

Run all test:

```bash
go test -timeout 130m ./... -json | go-test-report
```
Comments:
* Do not however run `go test -v .` or similar. Specifying a package (that extra dot) enables caching, which is incompatible with Terraform.
* We use go-test-report to create html reports for tests, check https://github.com/vakenbolt/go-test-report for more information
* Cloud resources are destroyed automatically after the test, no cleanup is normally required.
* VScode users should keep `Go: Test On Save` at the default false value, and not set to true. This option is spelled `go.testOnSave` in settings.json.

## Test skeleton overview

```mermaid
graph TB
    terraform_options(Init Terraform with provided options)
    terraform_apply(Deploy infrastructure)
    do_terraform_plan_after_deploy{Execute Terraform Plan?}
    terraform_plan_after_deploy(Verify if no changes are planned after deployment)
    do_modify_infrastructure{Modify infrastructure?}
    modify_infrastructure(Plan infrastructure with changed resources)
    verify_changes(Verify planned changes)
    verify_assert_expression(Verify assert expressions)
    test_fail((Tests failed))
    test_pass((Tests passed))

    terraform_options --> terraform_apply -- infrastructure is deployed --> verify_assert_expression
    do_terraform_plan_after_deploy -- yes --> terraform_plan_after_deploy
    terraform_plan_after_deploy -- code is idempotent --> do_modify_infrastructure
    verify_assert_expression -- all asserts passed --> do_terraform_plan_after_deploy
    do_modify_infrastructure -- yes --> modify_infrastructure --> verify_changes
    terraform_apply -. error in deployment .-> test_fail
    terraform_plan_after_deploy -. code is not idempotent .-> test_fail
    verify_assert_expression -. one of the asserts failed .-> test_fail
    verify_changes -. unexpected changes .-> test_fail
    do_terraform_plan_after_deploy -- no --> test_pass
    do_modify_infrastructure -- no --> test_pass
    verify_changes -- only expected changes --> test_pass

    classDef green fill:#33aa33,stroke:#333,stroke-width:2px;
    classDef red fill:#aa3333,stroke:#333,stroke-width:2px;
    class test_pass green
    class test_fail red
```