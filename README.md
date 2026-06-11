# OpenBSD Network Monitoring Scripts

Two Perl scripts for monitoring network connections and listening ports on OpenBSD systems, with better output than standard `fstat` and `netstat` commands.

## Scripts

### portmon.pl (Recommended)
Feature-rich network connection monitor with filtering options.

### netmon.pl
Simpler version with basic filtering capabilities.

## Installation

1. Copy the scripts to a directory in your PATH (e.g., `/usr/local/sbin/`):
   ```sh
   cp portmon.pl /usr/local/sbin/
   cp netmon.pl /usr/local/sbin/
   ```

2. Make them executable:
   ```sh
   chmod +x /usr/local/sbin/portmon.pl
   chmod +x /usr/local/sbin/netmon.pl
   ```

## Usage

### portmon.pl

**Basic syntax:**
```sh
portmon.pl [options] [filter]
```

**Options:**
- `-l` - Show only listening ports
- `-e` - Show only established connections
- `-a` - Show all connections (default)

**Filter:** Username, program name, or PID to filter results

**Examples:**

Show all network connections:
```sh
portmon.pl
```

Show only listening ports:
```sh
portmon.pl -l
```

Show all connections for a specific program:
```sh
portmon.pl smtp-gated
```

Show listening ports for a specific user:
```sh
portmon.pl -l _smtp-gated
```

Show established connections matching "unbound":
```sh
portmon.pl -e unbound
```

Find what's listening on a specific program:
```sh
portmon.pl -l httpd
```

Show all connections for a specific PID:
```sh
portmon.pl 12345
```

### netmon.pl

**Basic syntax:**
```sh
netmon.pl [filter]
```

**Filter:** Username, program name, or PID to filter results

**Examples:**

Show all network connections:
```sh
netmon.pl
```

Filter by program name:
```sh
netmon.pl sshd
```

Filter by username:
```sh
netmon.pl _ntp
```

Filter by PID:
```sh
netmon.pl 83018
```

## Output Format

Both scripts display results in a tabular format:

```
USER         PID     PROGRAM         LOCAL ADDRESS                FOREIGN ADDRESS              STATE
========================================================================================================================
_unbound     12345   unbound         127.0.0.1:53                 *:*                          LISTEN
_unbound     12345   unbound         ::1:53                       *:*                          LISTEN
root         67890   sshd            *:22                         *:*                          LISTEN
_www         11111   httpd           *:80                         *:*                          LISTEN
_www         11111   httpd           *:443                        *:*                          LISTEN
root         22222   sshd            192.168.1.10:22              192.168.1.100:54321          ESTABLISHED
```

**Columns:**
- **USER** - Username running the process
- **PID** - Process ID
- **PROGRAM** - Program name
- **LOCAL ADDRESS** - Local IP:port (what the process is bound to)
- **FOREIGN ADDRESS** - Remote IP:port (what it's connected to, or `*:*` for listeners)
- **STATE** - Connection state (LISTEN, ESTABLISHED, etc.)

## Common Use Cases

### Find what's using a specific port
```sh
portmon.pl -l | grep :443
```

### Check all connections for a daemon
```sh
portmon.pl smtpd
```

### Monitor SSH connections
```sh
portmon.pl -e sshd
```

### See what a specific user is running
```sh
portmon.pl _postgres
```

### Quick overview of all listening services
```sh
portmon.pl -l
```

### Debug a specific process by PID
```sh
portmon.pl 83018
```

## Advantages Over Standard Tools

### vs. `fstat | grep`
- **Readable output** - Organized columns instead of raw fstat format
- **Process correlation** - Shows program name and full command
- **State detection** - Clearly shows LISTEN vs ESTABLISHED
- **Filtering** - Built-in filtering by user, program, or PID

### vs. `netstat -na | grep LISTEN`
- **Process information** - Shows which process owns each port
- **User context** - Displays the username running the service
- **Combined view** - No need to cross-reference PIDs manually
- **Smart filtering** - Filter by any attribute in one command

## Requirements

- OpenBSD (tested on OpenBSD 7.x)
- Perl 5 (included in base system)
- Root access or appropriate permissions to run `fstat` and `ps`

## Installation

```ksh
git clone https://gitlab.com/tangentnetworks/portmon.git
chmod +x portmon/{portmon.pl,netmon.pl}
cp -p portmon/{portmon.pl,netmon.pl} /usr/local/bin/
```

## Troubleshooting

**"Permission denied" errors:**
- Run with `doas` or as root: `doas portmon.pl`

**No output:**
- Check if the filter is too restrictive
- Try running without filters first: `portmon.pl`
- Verify the process is actually running: `ps aux | grep <process>`

**Incomplete information:**
- Some system processes may require root privileges to view
- Use `doas` to see complete information

## Tips

1. **Pipe to less for long output:**
   ```sh
   portmon.pl | less
   ```

2. **Save output to a file:**
   ```sh
   portmon.pl > network-connections.txt
   ```

3. **Watch connections in real-time:**
   ```sh
   watch -n 2 'portmon.pl -e'
   ```

4. **Combine with grep for specific ports:**
   ```sh
   portmon.pl -l | grep ':80\|:443'
   ```

5. **Count listening services:**
   ```sh
   portmon.pl -l | grep -c LISTEN
   ```

---

## Author and Attribution

**Primary Author:** David Peter
**Organization:** Tangent Networks
**Web:** [https://tangentnet.top](https://tangentnet.top)
**Email:** [tangent.net@zohomail.in](mailto:tangent.net@zohomail.in)

---

## License

**BSD 3-Clause License (Simplified)**

Copyright (c) 2025–2026
David Peter, Tangent Networks
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

**END NETMON_PORTMON.md**
