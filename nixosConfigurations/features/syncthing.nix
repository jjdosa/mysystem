{

  services.syncthing = {
    enable = true;
    dataDir = "/home/jj";
    configDir = "/home/jj/.config/syncthing";
    user = "jj";
    group = "users";
    openDefaultPorts = true;
    guiAddress = "127.0.0.1:8384";
    overrideDevices = true;
    overrideFolders = true;
    devices = {
      lapaz = { id = "AYSSCDO-7QIMWCI-ZX6NL23-PAZCL4A-Y5RUZZX-USGFL3T-JRIJPBY-W4CU3AZ"; };
      lima = { id = "VYO7L22-RHVZOJA-VXORQSO-66RUZ3I-UHXWKLZ-ZKVC3IY-MQ7L3SM-J4JL4AO"; };
      bogota = { id = "35ND6IE-TNGZ5KH-U5SIL7L-RKAXD6S-GAXIWBT-KAPYXMD-FELWNBZ-HYXCFAS"; };
      mbp15 = { id = "IP22ZVB-ODDIJK5-JQIXGES-QHP6GNC-HBTMDP3-KLDHUPM-SHNIFN5-QKB7PA5"; };
      urubamba = { id = "W33RJBP-6JXMOPP-USEFKYU-U2EJWN4-YTLGXBF-ICQUEIV-RQZURFW-RKZZFAY"; };
      antofagasta = { id = "25SGCDR-2WOKWNJ-JU7VJ3C-BYWO77P-ASVQTUV-2LI7NTY-JTSWFKK-DUJEBA4"; };
      atacama = { id = "XA5PJXG-RLXFCIC-BJF7FK5-FQTDVVP-YS6K2DX-27I4JYQ-55LRSUF-4YSR5QI"; };
      cusco = { id = "IM6A4WE-O47VYMM-DIOCSGA-EA3LZPR-CQOVZ5M-L52WJAU-6O52MB4-IGXSHQV"; };
      toledo = { id = "AGJAQ3E-56GCJHA-YHRZ26X-DH3OQAV-OBNX2XM-NCZX6GW-JYF4LWV-BVXXNAE"; };
    };
    folders = {

      Ocean = {
        path = "/home/jj/Ocean";
        devices = [
          "lapaz"
          "lima"
          "bogota"
          # "urubamba"
          "antofagasta"
          "atacama"
          "cusco"
          "toledo"
        ];
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";  # 1 hour in seconds
            maxAge = "15552000";     # 180 days in seconds
          };
        };
      };

    };
  };

}
