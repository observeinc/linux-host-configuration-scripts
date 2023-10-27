# Using

create a file in this directory called observe.auto.tfvars

```
PUBLIC_KEY_PATH  = "/Users/YOU/.ssh/id_rsa.pub"
PRIVATE_KEY_PATH = "/Users/YOU/.ssh/id_rsa"
name_format      = "YOU-MAKE-UNIQUE-%s"
OBSERVE_ENDPOINT = "https://xxxxxxxxx.collect.observe-staging.com"
OBSERVE_TOKEN    = "xxxxxxxxxxxxxxxxxxxxxx"
```

Run ```terraform init and then apply``` in this directory