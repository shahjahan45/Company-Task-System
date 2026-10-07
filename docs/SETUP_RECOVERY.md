# Setup recovery

Version 1.1 fixes first-run recovery when an earlier database already contains employee codes such as `EMP-0001`.

- The first Super Administrator no longer uses a hardcoded employee code.
- The next available employee code is generated automatically.
- Existing matching administrator user/employee records can be reused during setup.
- Demo users do not mark installation complete; an active Super Administrator is required.
- If a prior setup failed after creating the schema, replace the project files with this version and reload `/setup.php`. Database deletion is not required.
