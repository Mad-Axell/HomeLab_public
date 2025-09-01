# PAM Security Recommendations

## Critical Security Considerations

### 1. Account Lockout Protection
- **Recommended**: 3-5 failed attempts before lockout
- **Lockout Duration**: 15-30 minutes for production, 5-15 minutes for development
- **Audit Logging**: Always enable for security monitoring
- **Warning**: Test lockout mechanisms before production deployment

### 2. Password Policy
- **Minimum Length**: 12+ characters for production, 10+ for development
- **Complexity**: Require at least 3 character classes (uppercase, lowercase, digits, symbols)
- **History**: Remember last 5 passwords to prevent reuse
- **Username Check**: Reject passwords containing username

### 3. Session Management
- **Concurrent Logins**: Limit to 3-5 per user for production
- **System Logins**: Limit to 20-50 total concurrent sessions
- **Session Timeout**: Implement automatic session termination
- **Secure TTY**: Restrict root access to console only

### 4. Privilege Escalation
- **Wheel Group**: Use dedicated group for sudo access
- **Sudo Configuration**: Implement least privilege principle
- **Audit Trail**: Log all sudo usage
- **Time Restrictions**: Consider time-based access controls

## Security Levels

### High Security (Production)
```yaml
pam_faillock_deny: 3
pam_unlock_time: 1800
pam_pwquality_minlen: 16
pam_pwquality_minclass: 4
pam_limits_maxlogins: 3
pam_root_console_only: true
```

### Medium Security (Development)
```yaml
pam_faillock_deny: 5
pam_unlock_time: 900
pam_pwquality_minlen: 12
pam_pwquality_minclass: 3
pam_limits_maxlogins: 10
pam_root_console_only: false
```

### Low Security (Testing)
```yaml
pam_faillock_deny: 10
pam_unlock_time: 300
pam_pwquality_minlen: 8
pam_pwquality_minclass: 2
pam_limits_maxlogins: 20
pam_root_console_only: false
```

## Monitoring and Maintenance

### Regular Tasks
1. **Review Failed Logins**: Monitor `/var/log/auth.log` or `/var/log/secure`
2. **Check Locked Accounts**: Use `pam_tally2 --user username` or `faillock --user username`
3. **Audit Sudo Usage**: Review `/var/log/auth.log` for sudo commands
4. **Password Policy Compliance**: Regular password audits

### Emergency Procedures
1. **Account Unlock**: Use `pam_tally2 --reset --user username`
2. **Configuration Rollback**: Restore from backup files
3. **Emergency Access**: Console access for locked-out administrators
4. **Service Restart**: Restart SSH service if needed

## Compliance Considerations

### CIS Controls
- Control 4: Controlled Use of Administrative Privileges
- Control 5: Secure Configuration for Hardware and Software
- Control 6: Maintenance, Monitoring, and Analysis of Audit Logs

### NIST Guidelines
- SP 800-53: Access Control (AC)
- SP 800-53: Audit and Accountability (AU)
- SP 800-53: Identification and Authentication (IA)

### PCI DSS
- Requirement 7: Restrict Access to Cardholder Data
- Requirement 8: Identify and Authenticate Access to System Components
- Requirement 10: Track and Monitor All Access to Network Resources

## Risk Mitigation

### Common Risks
1. **Brute Force Attacks**: Mitigated by account lockout
2. **Weak Passwords**: Mitigated by password complexity requirements
3. **Privilege Escalation**: Mitigated by wheel group restrictions
4. **Session Hijacking**: Mitigated by session limits and timeouts

### Mitigation Strategies
1. **Defense in Depth**: Multiple layers of authentication
2. **Least Privilege**: Minimal required access permissions
3. **Monitoring**: Continuous security monitoring
4. **Incident Response**: Prepared response procedures

## Testing Recommendations

### Pre-Deployment Testing
1. **Test Account Lockout**: Verify lockout mechanisms work correctly
2. **Test Password Policy**: Verify password requirements are enforced
3. **Test Session Limits**: Verify concurrent login restrictions
4. **Test Privilege Escalation**: Verify sudo/wheel group restrictions

### Post-Deployment Testing
1. **Regular Security Audits**: Monthly security reviews
2. **Penetration Testing**: Quarterly security assessments
3. **Compliance Audits**: Annual compliance reviews
4. **User Training**: Regular security awareness training

## Troubleshooting Guide

### Common Issues
1. **Locked Out**: Use console access or recovery mode
2. **Password Rejected**: Check password policy requirements
3. **Sudo Access Denied**: Verify wheel group membership
4. **SSH Connection Issues**: Check SSH configuration and PAM settings

### Debug Commands
```bash
# Check PAM configuration
pam_tally2 --user username
faillock --user username

# Verify password policy
cat /etc/pam.d/common-password

# Check account lockout
cat /etc/pam.d/common-auth

# Test sudo access
sudo -l

# Check system logs
tail -f /var/log/auth.log
journalctl -u ssh
```

## Best Practices

1. **Always Backup**: Create backups before applying changes
2. **Test Thoroughly**: Test in safe environment before production
3. **Monitor Logs**: Regularly review authentication logs
4. **Document Changes**: Maintain configuration documentation
5. **Regular Updates**: Keep PAM modules and system updated
6. **User Education**: Train users on security policies
7. **Incident Response**: Have procedures for security incidents
