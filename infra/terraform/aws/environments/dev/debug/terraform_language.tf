output "if_main_return_misc_else_main_with_main" {
  value = one(setsubtract(["main", "misc"], ["main"]))
}

output "if_main_return_misc_else_main_with_misc" {
  value = one(setsubtract(["main", "misc"], ["misc"]))
}
