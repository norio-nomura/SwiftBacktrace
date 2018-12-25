workflow "New workflow" {
  on = "push"
  resolves = ["swiftlint"]
}

action "swiftlint" {
  uses = "norio-nomura/action-swiftlint@master"
}
