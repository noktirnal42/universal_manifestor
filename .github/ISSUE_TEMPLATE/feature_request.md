---
name: Feature Request
description: Suggest a new feature or enhancement
title: "[Feature]: "
labels: ["enhancement", "triage"]
assignees:
  - noktirnal42
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to suggest a feature!
  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem are you trying to solve?
      placeholder: Describe the problem or need you're experiencing
    validations:
      required: true
  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: Describe your suggested solution or feature
      placeholder: How would this feature work? What would it do?
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternative Solutions
      description: Have you considered any alternative approaches?
      placeholder: Are there other ways to solve this problem?
    validations:
      required: false
  - type: dropdown
    id: mode
    attributes:
      label: Related Mode
      description: Which mode(s) would this feature apply to?
      multiple: true
      options:
        - Focus
        - Align
        - Manifest
        - Universe
        - General/All Modes
    validations:
      required: false
  - type: textarea
    id: context
    attributes:
      label: Additional Context
      description: Add any other context, mockups, or examples
      placeholder: Anything else that would be helpful to know
    validations:
      required: false
  - type: checkboxes
    id: terms
    attributes:
      label: Code of Conduct
      description: By submitting this issue, you agree to follow our Code of Conduct
      options:
        - label: I agree to follow this project's Code of Conduct
          required: true
