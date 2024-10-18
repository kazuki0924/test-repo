defaults = {
  error_message = "The value is not as expected."
  common = {
    # 消し損じがあっても明らかに削除対象だと分かる名前にする
    suffix = "-delete-me"
    github = {
      owner = "owner"
    }
  }
  github = {
    oidc = {
      repository_allow_list = ["repository*"]
    }
  }
}

prod = {
  common = {
    env = "prod"
    aws = {
      default_tags = {
        env = "prod"
      }
    }
    github = {
      org = "org"
    }
  }
  github = {
    oidc = {
      repository_allow_list = ["repository1", "repository2"]
    }
  }
}
