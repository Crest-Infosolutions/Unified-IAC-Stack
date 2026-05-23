path "secret/data/github" {
  capabilities = ["read"]
}

path "secret/metadata/github" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}