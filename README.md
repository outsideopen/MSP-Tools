# Useful Scripts and Notes for IT Managed Services Providers / MSPs

This repository contains a curated collection of scripts and notes designed to support the daily operations of the Outside Open (OO) team.

## Contents

- **Automation Scripts**: Scripts to automate repetitive tasks, improve workflows, and manage system configurations efficiently.
- **Security Practices**: Best practices and scripts to reinforce security postures, including logging, monitoring, and hardening tips.
- **Troubleshooting Tools**: Utilities and scripts to aid in diagnosing and resolving system issues.

## Usage Guidelines

- **Execution Policy**: Set the execution policy appropriately to allow script execution, where applicable. 
  - PowerShell scripts: Run `Set-ExecutionPolicy RemoteSigned` executed in an administrative PowerShell session. (Only needed once per computer.)
  - Linux / Mac: `chmod 755 script_name.sh`
- **Administrative Privileges**: Some scripts may require administrative privileges to run. Ensure you have the necessary permissions before execution.
- **Review and Test**: Always review and test scripts in a controlled environment before deploying them in a production setting to ensure they meet requirements.
- **Scrub Sensitive Information**: While these scripts are intended for OO team use, they may be distributed as needed. However, OO employees must ensure to remove any client-specific or other proprietary information before sharing.
- **No Credentials Stored**: To maintain security best practices, this repository does not contain any passwords or usernames. Always use secure methods for authentication and credentials management when modifying or executing scripts.

