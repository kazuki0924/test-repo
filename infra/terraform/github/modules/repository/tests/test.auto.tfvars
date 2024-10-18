defaults = {
  error_message = "The value is not as expected."
  common = {
    # 消し損じがあっても明らかに削除対象だと分かる名前にする
    suffix = "-delete-me"
  }
  github_actions = {
    variables = {
      repository = {
        AWS_ACCOUNT_ID_DEV = "123456789012"
      }
    }
  }
}
