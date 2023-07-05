name: Bug Report
description: Create an issue to help us improvve
title: "[Bug Report] <Short title of the bug>"
assignees: aws-vmseries-modules-codeowners
body:
- type: input
  attributes:
    label: Terraform version
    description: What is the Terraform version in use?
    placeholder: ex. 1.2.6
  validations:
    required: true
- type: input
  attributes:
    label: Module Version
    description: What is the module version in use? Please include the commit hash if you're using an unreleased version
    placeholder: ex. A list of module version can be found here - https://github.com/PaloAltoNetworks/terraform-aws-vmseries-modules/releases
  validations:
    required: true
- type: textarea
  attributes:
    label: Describe the bug
    description: A clear and concise description of what is wrong.
    placeholder: ''
  validations:
    required: true
- type: textarea
  attributes:
    label: Expected behavior
    description: Tell us what should happen, or how it should work. 
    placeholder: ''
  validations:
    required: true
- type: textarea
  attributes:
    label: Current behavior
    description: Tell us what happens instead of the expected behavior. 
    placeholder: ''
  validations:
    required: true
- type: textarea
  attributes:
    label: Possible solution
    description: Not obligatory, but suggest a fix/reason for the bug, or ideas how to implement the addition or change.
    placeholder: ''
  validations:
    required: false
- type: textarea
  attributes:
    label: Steps to reproduce
    description: Provide a link to a live example, or an unambiguous set of steps to reproduce this bug. Include code to reproduce, if relevant. 
    placeholder: >
  1. Step one
  2. Step two
  3. Step three
  validations:
    required: false
- type: textarea
  attributes:
    label: Anything else to add?
    description: If you would like to add any more information, please add it below.
    placeholder: > 
  Include screenshots (paste from your clipboard or drag and drop here), other relevant details about the environment you experienced the bug in, terraform debug logs or relevant outputs
  How has this issue affected you? 
  What are you trying to accomplish?
  Providing context helps us come up with a solution that is useful in the real world 
  validations:
    required: false
