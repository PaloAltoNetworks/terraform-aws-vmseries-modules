<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.25 |

### Providers

No providers.

### Modules

No modules.

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_abbreviations"></a> [abbreviations](#input\_abbreviations) | Map of abbreviations used for resources (placed in place of "\_\_default\_\_"). | `map(string)` | <pre>{<br>  "application_loadbalancer": "alb",<br>  "application_loadbalancer_target_group": "atg",<br>  "gateway_loadbalancer": "gwlb",<br>  "gateway_loadbalancer_endpoint": "gwep",<br>  "gateway_loadbalancer_target_group": "gwtg",<br>  "iam_instance_profile": "profile",<br>  "iam_role": "role",<br>  "internet_gateway": "igw",<br>  "nat_gateway": "ngw",<br>  "network_loadbalancer": "nlb",<br>  "network_loadbalancer_target_group": "ntg",<br>  "route_table": "rt",<br>  "security_group": "sg",<br>  "subnet": "snet",<br>  "transit_gateway": "tgw",<br>  "transit_gateway_attachment": "att",<br>  "transit_gateway_route_table": "trt",<br>  "vm": "vm",<br>  "vmseries": "vm",<br>  "vmseries_network_interface": "nic",<br>  "vpc": "vpc",<br>  "vpn_gateway": "vgw"<br>}</pre> | no |
| <a name="input_az_map_literal_to_numeric"></a> [az\_map\_literal\_to\_numeric](#input\_az\_map\_literal\_to\_numeric) | Map of number used instead of letters for AZs (placed in place of "\_\_az\_numeric\_\_"). | `map(string)` | <pre>{<br>  "a": 1,<br>  "b": 2,<br>  "c": 3,<br>  "d": 4,<br>  "e": 5,<br>  "f": 6,<br>  "g": 7,<br>  "h": 8,<br>  "i": 9<br>}</pre> | no |
| <a name="input_name_delimiter"></a> [name\_delimiter](#input\_name\_delimiter) | It specifies the delimiter used between all components of the new name. | `string` | `"-"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources | `string` | n/a | yes |
| <a name="input_name_template"></a> [name\_template](#input\_name\_template) | Map of templates used to generate names. Each template is defined by list of objects. Each object contains 1 element defined by key and string value.<br><br>Important:<br>1. Elements with key `prefix` (value is not important) will be replaced with value of the `name_prefix` variable (e.g. `{ prefix = null }`)<br>2. `%s` will be eventually replaced by resource name<br>3. `__default__` is a marker that we will be replaced with a default resource abbreviation, anything else will be used literally.<br>4. `__az_numeric__` is a marker that will be used to replace the availability zone letter indicator with a number (e.g. a->1, b->2, ...)<br>5. `__az_literal__` is a marker that will be used to replace the full availability zone name with a letter (e.g. `eu-central-1a` will become `a`)<br>6. Order matters<br><br>Example:<br><br>name\_template = {<br>  name\_at\_the\_end = [<br>    { prefix = null },<br>    { abbreviation = "\_\_default\_\_" },<br>    { bu = "cloud" },<br>    { env = "tst" },<br>    { suffix = "ec1" },<br>    { name = "%s" },<br>  ]<br>  name\_with\_az = [<br>    { prefix = null },<br>    { abbreviation = "\_\_default\_\_" },<br>    { name = "%s" },<br>    { bu = "cloud" },<br>    { env = "tst" },<br>    { suffix = "ec1" },<br>    { az = "\_\_az\_numeric\_\_" },<br>  ]<br>} | `map(list(map(string)))` | `{}` | no |
| <a name="input_names"></a> [names](#input\_names) | Map of objects defining template and names used for resources.<br><br>Example:<br><br>names = {<br>  vpc = {<br>    template = lookup(var.name\_templates.assign\_template, "vpc", lookup(var.name\_templates.assign\_template, "default", "default")),<br>    values   = { for k, v in var.vpcs : k => v.name }<br>  }<br>  gateway\_loadbalancer = {<br>    template = lookup(var.name\_templates.assign\_template, "gateway\_loadbalancer", lookup(var.name\_templates.assign\_template, "default", "default")),<br>    values   = { for k, v in var.gwlbs : k => v.name }<br>  }<br>}<br><br>Please take a look combined\_design example, which contains full map for names. | <pre>map(object({<br>    template : string<br>    values : map(string)<br>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_generated"></a> [generated](#output\_generated) | Map of generated names for each kind of resources.<br><br>Example:<br><br>generated = {<br>    application\_loadbalancer              = {<br>        app1 = "example-alb-app1-cloud-tst-ec1"<br>        app2 = "example-alb-app2-cloud-tst-ec1"<br>    }<br>    application\_loadbalancer\_target\_group = {<br>        app1-http = "example-atg-app1-80-cloud-tst"<br>        app2-http = "example-atg-app2-80-cloud-tst"<br>    }<br>    gateway\_loadbalancer                  = {<br>        security\_gwlb = "scz-gwlb-security-cloud-tst"<br>    }<br>    gateway\_loadbalancer\_endpoint         = {<br>        app1\_inbound           = "example-gwep-app1-cloud-tst-ec1"<br>        app2\_inbound           = "example-gwep-app2-cloud-tst-ec1"<br>        security\_gwlb\_eastwest = "example-gwep-eastwest-cloud-tst-ec1"<br>        security\_gwlb\_outbound = "example-gwep-outbound-cloud-tst-ec1"<br>    }<br>} |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
