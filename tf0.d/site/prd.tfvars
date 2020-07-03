site = {
  protocol = "https"
  domain = {
    root = "nijohando.jp"
    sub = "blog"
  }
  bucket_force_destroy = false
}

waf = {
  enabled = false
  ipv4_allowlist = [""]
  ipv6_allowlist = [""]
}

