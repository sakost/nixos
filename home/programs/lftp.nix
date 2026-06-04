# lftp — scriptable file-transfer client (FTP/FTPS/SFTP/HTTP)
# Config lives in ~/.lftprc, which lftp reads on every startup.
{ pkgs, ... }:

{
  home.packages = [ pkgs.lftp ];

  home.file.".lftprc".text = ''
    # Useful aliases
    alias dir ls
    alias reconnect "close; cache flush; cd ."

    # Custom prompt: lftp <status> <user>@<host>:<dir>>
    set prompt "lftp \S\? \u\@\h:\w> "

    # Default to passive mode (works behind most NAT/firewalls)
    set ftp:passive-mode on

    # SSL/TLS: allow but don't force, encrypt the data channel, verify certs
    set ftp:ssl-allow on
    set ftp:ssl-force off
    set ftp:ssl-protect-data on
    set ssl:verify-certificate yes

    # Network resilience over flaky links
    set net:timeout 30
    set net:max-retries 5
    set net:reconnect-interval-base 10
    set net:reconnect-interval-max 60

    # Transfer behaviour
    set xfer:clobber on

    # Parallel transfers: 3 files at once, 5 segments per large file
    set mirror:parallel-transfer-count 3
    set mirror:use-pget-n 5
    set pget:default-n 5

    # Cache directory listings for an hour
    set cache:expire 1h
  '';
}
