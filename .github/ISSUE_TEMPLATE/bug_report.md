---
name: Bug Report
description: File a bug report
title: "[Bug]: "
labels: ["bug", "triage"]
assignees:
  - noktirnal42
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report!
  - type: input
    id: app-version
    attributes:
      label: App Version
      description: What version of Universal Manifestor are you running?
      placeholder: "e.g., 1.0.0"
    validations:
      required: true
  - type: dropdown
    id: platform
    attributes:
      label: Platform
      description: Which platform are you experiencing this issue on?
      options:
        - macOS
        - iOS
        - iPadOS
    validations:
      required: true
  - type: input
    id: os-version
    attributes:
      label: OS Version
      description: What version of the operating system are you using?
      placeholder: "e.g., macOS 14.2, iOS 17.2"
    validations:
      required: true
  - type: input
    id: device
    attributes:
      label: Device
      description: What device are you using?
      placeholder: "e.g., MacBook Pro M2, iPhone 15 Pro"
    validations:
      required: true
  - type: textarea
    id: description
    attributes:
      label: Description
      description: Describe the bug in detail
      placeholder: What happened? What did you expect to happen?
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      description: How can we reproduce this issue?
      placeholder: |
        1. Go to '...'
        2. Click on '...'
        3. Scroll down to '...'
        4. See error
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Logs & Screenshots
      description: Include any relevant logs, screenshots, or screen recordings
      placeholder: You can attach images by clicking this area to highlight it and then dragging files in.
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
