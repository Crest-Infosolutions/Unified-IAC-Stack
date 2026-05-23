path "secret/data/tfe-agent/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/tfe-agent/*" {
  capabilities = ["read", "list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}