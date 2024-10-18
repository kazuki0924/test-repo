defaults = {
  error_message = "The value is not as expected."
  common = {
    # 消し損じがあっても明らかに削除対象だと分かる名前にする
    suffix = "-delete-me"
  }
}

prod = {
  common = {
    # 消し損じがあっても明らかに削除対象だと分かる名前にする
    suffix = "-delete-me"
    env    = "prod"
    aws = {
      default_tags = {
        env = "prod"
      }
    }
  }
}
