# squidman
##Installation guide:
1. Install htpasswd, git and gcc: `apt-get install gcc git apache2-utils`
2. Install DBI module for Perl: `cpan DBI`
3. Clone squidman to local server: `git clone https://github.com/kor-ea/squidman`
4. Edit squidman.pl to update db variables
5. Create and copy ssh-key to controlled servers: 
```
  ssh-keygen
  ssh-copy-id root@controlled-server-ip
``` 
6. Run `./squidman.pl controlled-server-ip`

