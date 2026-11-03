{ ... }: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    # Unlike extraUpFlags, these also apply to already-enrolled machines
    # without an authKeyFile. The office routes come from the OpenWrt One.
    extraSetFlags = [ "--accept-routes" ];
  };
}
