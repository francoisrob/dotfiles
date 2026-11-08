{...}: {
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      freellmapi = {
        image = "ghcr.io/tashfeenahmed/freellmapi:latest";
        environment = {
          NODE_ENV = "production";
          PORT = "3001";
          # HOST_BIND only applies to published Docker ports; with host networking HOST sets the listener.
          HOST = "127.0.0.1";
          ALLOWED_HOSTS = "freellmapi.francoisrob.me";
        };
        environmentFiles = ["/etc/freellmapi.env"];
        volumes = ["freellmapi_freellmapi-data:/app/server/data"];
        extraOptions = ["--network=host"];
      };
    };
  };
}
