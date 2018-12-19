workflow "New workflow" {
  on = "push"
  resolves = ["swiftlint"]
}

action "swiftlint" {
  uses = "docker://norionomura/swiftlint:swift-4.2"
}
