github = {
  site = {
    location       = "https://github.com/nijohando/blog.git"
    source_version = "develop"
  }
  builder = {
    location       = "https://github.com/nijohando/blog-builder.git"
    source_version = "develop"
  }
}

secret = {
  parameter_github_personal_access_token = "/blog/dev/github/personal_access_token"
}

log = {
  retention_in_days = 7
}
