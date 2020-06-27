site = {
  protocol = "https"
  domain = {
    root = "nijohan.dev"
    sub = "blog"
  }
  bucket_force_destroy = true
}

waf = {
  enabled = true
  ipv4_allowlist = []
  ipv6_allowlist = []
}

