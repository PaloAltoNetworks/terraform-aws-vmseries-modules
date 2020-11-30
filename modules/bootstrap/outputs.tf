############################################################################################
# Copyright 2020 Palo Alto Networks.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
############################################################################################


output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "ID of created bucket."
}

output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of created bucket."
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.this.name
  description = "Name of created IAM instance profile."
}

output "bucket" {
  value       = aws_s3_bucket.this
}
