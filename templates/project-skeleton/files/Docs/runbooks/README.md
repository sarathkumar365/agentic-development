# Runbooks

How-to-operate docs: deploy steps, on-call playbooks, environment procedures. Things you read while *doing* an operation, not while designing one.

## What goes here

- Deploy and release procedures
- On-call response steps for known alerts
- Environment setup or rotation guides
- Manual scripts and how to run them safely

## Conventions

- Folder name: kebab-case, describes the operation.
- Each runbook should be runnable cold — assume the reader is the on-call engineer at 2am.
- Update the runbook in the same PR that changes the procedure.
