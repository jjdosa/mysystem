{
  nix.settings = {
    substituters = [
      "http://10.10.100.7"
      "http://10.10.100.8"
      "http://10.10.100.3"
      # "http://10.10.100.4"
      # "http://10.10.100.5"
      # "http://10.10.100.7"
    ];
    trusted-public-keys = [
      "10.10.100.8:03dsPxeLnFnAdR7hhUqPH6rwNow0dHt49KWqzS3AjC8="
      "10.10.100.7:6FTRW2lRX1jjSXflQPvAnBzvkaCnchMO4y4wj7y8PFI="
      "10.10.100.3:ICrJJg0EV8V5n90xghprYM7hEZg+dJ5T06gyaHqZtKU="
      "10.10.100.4:g2y9eiBfz+zWX6PGbXSxiRcJcW6+7RFZh0TXwF8cmcc="
      "10.10.100.5:+3i3teuBVBQXR47k9M0zLVmdzirKSGm9+9awX2jp+u0="
    ];
  };
}
