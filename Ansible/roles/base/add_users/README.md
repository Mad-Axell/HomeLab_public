# base.add_users

## Overview

Role for adding users with sudo privileges and group management.

## Quick Start

```yaml
- hosts: servers
  roles:
    - role: base.add_users
      vars:
        users_to_add:
          - username: "john"
            password: "SecurePass123"
            groups: ["docker", "wheel"]
            is_sudoers: true
```

## Documentation

- [Complete English Documentation](README_eng.md)
- [Полная русская документация](README_rus.md)

## License

MIT

## Author

Mad-Axell [mad.axell@gmail.com]
