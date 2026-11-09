{...}: {
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      freellmapi = {
        image = "ghcr.io/tashfeenahmed/freellmapi@sha256:103e7b96b0c0239531d0d74cc5342969f1ba1cf7508e0b05f830169539ebacb4";
        user = "1000:1000";
        environment = {
          NODE_ENV = "production";
          PORT = "3001";
          HOST = "0.0.0.0";
          ALLOWED_HOSTS = "freellmapi.francoisrob.me";
        };
        environmentFiles = ["/etc/freellmapi.env"];
        volumes = ["freellmapi_freellmapi-data:/app/server/data"];
        ports = ["127.0.0.1:3001:3001"];
        extraOptions = [
          "--cap-drop=ALL"
          "--security-opt=no-new-privileges"
        ];
      };
    };
  };
}
