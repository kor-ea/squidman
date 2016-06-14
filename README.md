# squidman
##Installation guide:
1. Install htpasswd, git and gcc: `apt-get install gcc git apache2-utils`
2. Install required modules for Perl: `cpan DBI`NetAddr::IP
3. Clone squidman to local server: `git clone https://github.com/kor-ea/squidman`
4. Edit squidman.pl to update db variables
5. Create ssh-key for the controlled servers: `ssh-keygen`
6. Copy the key to the controlled server `ssh-copy-id root@controlled-server-ip`
7. Run `./squidman.pl controlled-server-ip`

