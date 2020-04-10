# Improve Vault Token Helper

First let me say that I love the vault token helper concept.  Far to many products lock you in to crappy auth mechanisms, providing an okay default and an extensible framework is amazing.

It can be improved however.

# Background
## Deployments and Namespaces
It's not uncommon for enterprise customers to have multiple clusters either for dev/test/prod qa functionality, different regions, or security clearance boundaries.

Additionally vault has introduced the concept of [namespaces](https://www.vaultproject.io/docs/enterprise/namespaces) which allows a single vault cluster to present multiple, isolated "mini-vaults".
## Argument Precedence
The [Vault CLI](https://www.vaultproject.io/docs/commands) can accept arguments in two main ways, CLI arguments and Environment variables, with CLI arguments taking precedence  over ENV vars.
* Vault Server Address can be specified as either  `-address` or `VAULT_ADDR`
* Vault Namespace can be specified as either  `-namespace` or `VAULT_NAMESPACE`

## Token Helper
From [token-helper docs](https://www.vaultproject.io/docs/commands/token-helper): 

```
The interface to a token helper is extremely simple: the script is passed with one argument that could be get, store or erase. If the argument is get, the script should do whatever work it needs to do to retrieve the stored token and then print the token to STDOUT. If the argument is store, Vault is asking you to store the token. Finally, if the argument is erase, your program should erase the stored token.

If your program succeeds, it should exit with status code 0. If it encounters an issue that prevents it from working, it should exit with some other status code. You should write a user-friendly error message to STDERR. You should never write anything other than the token to STDOUT, as Vault assumes whatever it gets on STDOUT is the token.
```


# The issue
The issue is that the vault token helper interface is extremely simplistic and entirely designed around storing and retrieving a single token without context.  The "protocol" makes no attempt to provide information to the helper beyond "this is a token" or "give me a token". The context (vault address, namespace, etc) is not provided.

Hashicorp's own example ruby script is congizant of this fact and tries to work around it by **inferring** information about what vault is being accessed via the `VAULT_ADDR` environment variable. However if the vault command line being run is utilizing the `-address` cli flag the vault helper is *blind* and can not divine any information.  The example script chooses to exit with a failure.

# Examples
## Setup and Setdown
### setup.sh
* `setup.sh` utilizes `docker-compose` to create two vault nodes running vault-premium version 1.4.0 ( deb not included ). 
* It creates two namespaces per vault node, `_NS1` and `_NS2`
* It uploads a "sudo" policy to each namespace and provisions one token per namespace
* Munges the config files for them to be usable.
### setdown.sh
Tears it all down.

### Note: Example setup
The below three examples will utilize an environment with these values.  If you run these scripts your values will be different.
```
http://localhost:8200 vault1_NS1 Token s.bSerxNYBDN7k1IGKa4d1Eb4X.cR23H
http://localhost:8200 vault1_NS2 Token s.jg8LC0CQw0ljtO8vt12cUcxy.b7MBy
http://localhost:2800 vault2_NS1 Token s.uQarBs9bca6YDCvUBYXreePz.Oiydu
http://localhost:2800 vault2_NS2 Token s.Sl90TFdir5znKYJ8wLyggFPh.CanGc
Root Token: vaultymcvaultface
```

# Example 1
This example shows the described limitations of the default helper and really the contextless nature of the token-helper protocol. Only being able to store a single token means that whenever you switch hosts or namespaces your told token is overwritten.

```
> VAULT_ADDR=http://127.0.0.1:8200 ./default_vault_helper.sh login vaultymcvaultface
... Ommited ...

Token File Contents: /Users/rolsen/.vault-token
vaultymcvaultface                                                                       

>VAULT_ADDR=http://127.0.0.1:8200 VAULT_NAMESPCE=vault1_NS1 ./default_vault_helper.sh login s.bSerxNYBDN7k1IGKa4d1Eb4X.cR23H
... Ommited ...

Token File Contents: /Users/rolsen/.vault-token
s.bSerxNYBDN7k1IGKa4d1Eb4X.cR23H                                               

>VAULT_ADDR=http://127.0.0.1:2800 VAULT_NAMESPCE=vault2_NS1 ./default_vault_helper.sh login s.uQarBs9bca6
YDCvUBYXreePz.Oiydu
... Ommited ...

Token File Contents: /Users/rolsen/.vault-token
s.uQarBs9bca6YDCvUBYXreePz.Oiydu%                                               

> VAULT_ADDR=http://127.0.0.1:2800 VAULT_NAMESPCE=vault2_NS1 ./default_vault_helper.sh token lookupKey                 Value
---                 -----
accessor            4Hp8MNkQ7MtNmC7nH0g7BB3V.Oiydu
creation_time       1586480594
creation_ttl        24h
display_name        token-SUDO-vault2-NS1
entity_id           n/a
expire_time         2020-04-11T01:03:14.007366Z
explicit_max_ttl    0s
id                  s.uQarBs9bca6YDCvUBYXreePz.Oiydu
issue_time          2020-04-10T01:03:14.0073896Z
meta                <nil>
namespace_path      vault2_NS1/
num_uses            0
orphan              true
path                auth/token/create
policies            [default sudo]
renewable           true
ttl                 23h52m36s
type                service

Token File Contents: /Users/rolsen/.vault-token
s.uQarBs9bca6YDCvUBYXreePz.Oiydu%                                                   

>VAULT_ADDR=http://127.0.0.1:8200 VAULT_NAMESPCE=vault1_NS1 ./default_vault_helper.sh token lookupError looking up token: Error making API request.

URL: GET http://127.0.0.1:8200/v1/auth/token/lookup-self
Code: 403. Errors:

* permission denied

Token File Contents: /Users/rolsen/.vault-token
s.uQarBs9bca6YDCvUBYXreePz.Oiydu
```

## Example 2
This example utilizes the Hashicorp's ruby example.  While it preforms "better" it still fails under several scenarios.  First because it does not divine the namespace information from `VAULT_NAMESPACE` it falls into the same pitfall as the default script in *Example 1*.  Secondly because it is reliant on the divination of environment variables, it __does the wrong thing__ when passed values on the commandline.

### Namespace Naivete
```
> VAULT_ADDR=http://127.0.0.1:8200 ./ruby_vault_helper.sh login vaultymcvaultface
... Ommited ...

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "vaultymcvaultface"
}

> VAULT_ADDR=http://127.0.0.1:2800 ./ruby_vault_helper.sh login vaultymcvaultface
... Ommited ...

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "vaultymcvaultface",
  "http://127.0.0.1:2800": "vaultymcvaultface"
}

> VAULT_ADDR=http://127.0.0.1:8200 ./ruby_vault_helper.sh login -namespace=vault1_NS2 s.jg8LC0CQw0ljtO8vt12cUcxy.b7MBy
... Ommited ...

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "s.jg8LC0CQw0ljtO8vt12cUcxy.b7MBy",
  "http://127.0.0.1:2800": "vaultymcvaultface"
}
```

### CLI Args What Are Those?
Here we see that the crystal ball lies to the token helper, thought `VAULT_ADDR` is set to one thing, the CLI arguments override it, and the connection is actually to the second vault cluster.

```
> VAULT_ADDR=http://127.0.0.1:8200 ./ruby_vault_helper.sh login -namespace=vault1_NS2 s.jg8LC0CQw0ljtO8vt1
2cUcxy.b7MBy    
... Ommited ...

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "s.jg8LC0CQw0ljtO8vt12cUcxy.b7MBy"
}

> VAULT_ADDR=http://127.0.0.1:8200 ./ruby_vault_helper.sh login -address=http://127.0.0.1:2800 -namespace=vault2_NS2 s.Sl90TFdir5znKYJ8wLyggFPh.CanGc
... Ommited ...

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "s.Sl90TFdir5znKYJ8wLyggFPh.CanGc"
}

> VAULT_ADDR=http://127.0.0.1:8200 ./ruby_vault_helper.sh token lookup -address=http://127.0.0.1:2800 -namespace=vault2_NS2                                 
Key                 Value
---                 -----
accessor            wi2MA8BkubSc7ey6uFr2LT8N.CanGc
creation_time       1586480593
creation_ttl        24h
display_name        token-SUDO-vault2-NS2
entity_id           n/a
expire_time         2020-04-11T01:03:13.1259312Z
explicit_max_ttl    0s
id                  s.Sl90TFdir5znKYJ8wLyggFPh.CanGc
issue_time          2020-04-10T01:03:13.125955Z
meta                <nil>
namespace_path      vault2_NS2/
num_uses            0
orphan              true
path                auth/token/create
policies            [default sudo]
renewable           true
ttl                 23h29m32s
type                service

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "s.Sl90TFdir5znKYJ8wLyggFPh.CanGc"
}

> VAULT_ADDR=http://127.0.0.1:8200 ./ruby_vault_helper.sh token lookup -namespace=vault1_NS2   
Error looking up token: Error making API request.

URL: GET http://127.0.0.1:8200/v1/auth/token/lookup-self
Code: 403. Errors:

* permission denied

Token File Contents: /Users/rolsen/.vault_tokens
{
  "http://127.0.0.1:8200": "s.Sl90TFdir5znKYJ8wLyggFPh.CanGc"
}

```

## Example 3

Really I'm not going to go into example 3 because I the horse is pretty dead at this point.  Example 3 would utilize `enh_ruby_vault_helper.sh` to show off extending the example ruby script to read in `VAULT_ADDR` and `VAULT_NAMESPACE` to allow the helper to divine more information about the connection.

However it still falls prey to the contextless nature of the protocol as command line arguments `-address` and `-namespace` are still lost to the ether and the script does the wrong thing.

# Solutions

Really there are two solutions in this humble nerds opinion.

# Extend the protocol
Extend the protocol to provide context about the token that vault wants the token helper to create/destroy/retrieve.  This could be done in any number of ways.  Adding more positional arguments.  Converting to a JSON blob.  Some combination of both? Really this is something to leave up to Hashicorp to design.

The problem i see that unless done carefully it'd break backwards compatibility. 

# Set Environment Variables When Invoking the Token-Helper

When vault executes the token helper, it could **always** ensure that the `VAULT_ADDR` and `VAULT_NAMESPACE` environment variables are set.  If the `-address` or `-namespace` command line arguments are passed on the commandline it could overwrite those variables when invoking the token-helper.

My GO-lang is complete garbage but it would be as simple as adding some `os.Setenv("FOO", "1")` in here [here](https://github.com/hashicorp/vault/blob/75266af3d3e95ec8517fb25af2d1f9e5720c890a/command/print_token.go)

This probably the simplest and least breaking solution.