# AWS CLI v2 + AWS SAM CLI (Serverless Application Model).
#
# - awscli2: shares the standard `~/.aws/{config,credentials}` files; configure
#   profiles with `aws configure` or `aws sso login`. SSO sessions are cached
#   under `~/.aws/sso/cache/`.
# - aws-sam-cli: drives `sam build --use-container` and `sam local invoke` via a
#   container runtime. This host runs podman (`custom.services.podman`); point
#   SAM at it on demand with `export DOCKER_HOST=unix:///run/user/$UID/podman/podman.sock`.
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    awscli2
    # Tests fail on the current nixpkgs click (27 option-formatting/ParameterSource
    # failures, all in CLI option introspection); the tool itself is unaffected.
    # Drop the override once nixpkgs' aws-sam-cli passes its own checks again.
    (aws-sam-cli.overridePythonAttrs { doCheck = false; })
  ];

  # AWS CLI v2 ships `aws_completer` (single binary that prints completions on
  # demand). zsh needs `bashcompinit` to understand bash-style `complete -C`.
  programs.zsh.initContent = lib.mkAfter ''
    autoload -U +X bashcompinit && bashcompinit
    complete -C '${pkgs.awscli2}/bin/aws_completer' aws
  '';
}
