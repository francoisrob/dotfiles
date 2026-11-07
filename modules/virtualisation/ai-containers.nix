{...}: {
  virtualisation.oci-containers = {
    backend = "docker";

    containers = {
      freellmapi = {
        image = "ghcr.io/tashfeenahmed/freellmapi:latest";
        environment = {
          NODE_ENV = "production";
          PORT = "3001";
          HOST_BIND = "127.0.0.1";
        };
        environmentFiles = ["/etc/freellmapi.env"];
        volumes = ["freellmapi_freellmapi-data:/app/server/data"];
        extraOptions = ["--network=host"];
      };

      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        environment = {
          HOST = "127.0.0.1";
          PORT = "3003";
          OPENAI_API_BASE_URL = "http://127.0.0.1:3001/v1";
        };
        environmentFiles = ["/etc/open-webui.env"];
        volumes = ["open-webui:/app/backend/data"];
        extraOptions = ["--network=host"];
        dependsOn = ["freellmapi"];
      };
    };
  };
}
