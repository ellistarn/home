---
description: Build mode with no approval prompts
mode: primary
permission:
  doom_loop: deny
  external_directory: deny
  question: deny
---

<!-- Identical to built-in build agent except the three permissions above.
     All other permissions (bash, edit, read, etc.) are inherited from defaults.
     Use regular Build (Tab) for sysadmin work that needs external directory access. -->
