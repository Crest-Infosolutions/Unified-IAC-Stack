path "secret/data/tfe/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/tfe/*" {
  capabilities = ["read", "list"]
}