# JupyterLab — data science notebook server (systemd user service)
{ config, pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: with ps; [
    jupyterlab
    ipykernel
  ]);
in
{
  # Systemd user service — starts JupyterLab on login
  systemd.user.services.jupyterlab = {
    Unit = {
      Description = "JupyterLab notebook server";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${python}/bin/jupyter-lab --no-browser --port=8888 --notebook-dir=%h --ip=localhost --IdentityProvider.token='' --ServerApp.password=''";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
