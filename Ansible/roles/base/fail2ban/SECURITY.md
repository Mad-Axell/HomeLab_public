# Fail2Ban Security Guidelines

This document provides security best practices and recommendations for using the Fail2Ban role in production environments.

## Security Best Practices

### 1. Configuration Security

#### Jail Settings
- **maxretry**: Set to 3-5 attempts for SSH, 5-10 for web services
- **findtime**: Use 300-600 seconds (5-10 minutes) for most services
- **bantime**: Use 3600-86400 seconds (1-24 hours) depending on threat level
- **ignoreip**: Always include your management networks and trusted IPs

#### Recommended Settings by Environment

**Development:**
```yaml
maxretry: 5
findtime: 900
bantime: 1800
```

**Staging:**
```yaml
maxretry: 3
findtime: 600
bantime: 3600
```

**Production:**
```yaml
maxretry: 2
findtime: 300
bantime: 7200
```

### 2. Network Security

#### Firewall Integration
- Always use UFW or iptables integration
- Ensure proper chain management
- Test firewall rules before deployment

#### IP Whitelisting
```yaml
fail2ban_ignoreip:
  - "127.0.0.1/8"
  - "::1"
  - "192.168.1.0/24"  # Management network
  - "10.0.0.0/8"      # Internal network
  - "172.16.0.0/12"   # Docker/container network
```

### 3. Logging and Monitoring

#### Log Configuration
- Enable verbose logging for debugging
- Rotate logs regularly
- Monitor log file sizes
- Set up log aggregation

#### Monitoring Commands
```bash
# Check active jails
fail2ban-client status

# Monitor banned IPs
fail2ban-client get sshd banned

# View recent logs
tail -f /var/log/fail2ban.log

# Check jail statistics
fail2ban-client get sshd failregex
```

### 4. Service Protection

#### SSH Hardening
- Use key-based authentication
- Disable root login
- Change default port (optional)
- Use strong ciphers

#### Web Service Protection
- Enable HTTPS only
- Use strong authentication
- Implement rate limiting
- Monitor access patterns

### 5. False Positive Prevention

#### Common False Positives
- Legitimate bulk operations
- Load balancers
- Monitoring systems
- Backup services

#### Mitigation Strategies
- Adjust `maxretry` and `findtime` values
- Use `ignoreip` for trusted sources
- Implement custom filters
- Monitor and whitelist as needed

### 6. Incident Response

#### Detection
- Monitor Fail2Ban logs
- Set up alerts for unusual activity
- Track ban/unban patterns
- Analyze attack sources

#### Response Procedures
1. **Immediate**: Check if legitimate traffic is affected
2. **Investigation**: Analyze logs and attack patterns
3. **Mitigation**: Adjust rules if necessary
4. **Documentation**: Record incident details
5. **Prevention**: Update security measures

### 7. Maintenance

#### Regular Tasks
- Review banned IPs weekly
- Update ignore lists monthly
- Test configuration quarterly
- Backup configuration before changes

#### Health Checks
```bash
# Service status
systemctl status fail2ban

# Configuration test
fail2ban-client reload

# Jail status
fail2ban-client status sshd

# Database integrity
fail2ban-client get sshd failregex
```

### 8. Advanced Security Features

#### Custom Filters
Create custom filters for specific applications:
```ini
[Definition]
failregex = ^<HOST> .*authentication failure.*$
ignoreregex = 
```

#### Custom Actions
Implement custom actions for notifications:
```ini
[Definition]
actionstart = 
actionstop = 
actioncheck = 
actionban = curl -X POST -d "ip=<ip>" http://api.example.com/ban
actionunban = curl -X POST -d "ip=<ip>" http://api.example.com/unban
```

### 9. Compliance Considerations

#### GDPR
- Log IP addresses only when necessary
- Implement data retention policies
- Provide data export capabilities
- Document processing purposes

#### SOX/PCI
- Maintain audit trails
- Implement access controls
- Regular security assessments
- Incident response procedures

### 10. Troubleshooting

#### Common Issues
1. **Service not starting**: Check configuration syntax
2. **False positives**: Adjust jail parameters
3. **Performance issues**: Optimize log paths
4. **Integration problems**: Verify firewall configuration

#### Debug Commands
```bash
# Verbose logging
fail2ban-client -v status

# Configuration test
fail2ban-client reload

# Jail debugging
fail2ban-client get sshd failregex

# Log analysis
grep "fail2ban" /var/log/syslog
```

## Security Checklist

- [ ] Configure appropriate jail settings
- [ ] Set up IP whitelisting
- [ ] Enable firewall integration
- [ ] Configure logging
- [ ] Test configuration
- [ ] Set up monitoring
- [ ] Document procedures
- [ ] Train administrators
- [ ] Regular maintenance schedule
- [ ] Incident response plan

## Resources

- [Fail2Ban Official Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Fail2Ban Configuration Examples](https://www.fail2ban.org/wiki/index.php/Configuration_examples)
- [Ansible Security Best Practices](https://docs.ansible.com/ansible/latest/security_best_practices.html)
- [Linux Security Hardening](https://wiki.archlinux.org/index.php/Security)
