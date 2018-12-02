# 6. Federation


The Stellar federation protocol maps Stellar addresses to more information about a given user. It’s a way for Stellar client software to resolve email-like addresses such as name*yourdomain.com into account IDs like: GCCVPYFOHY7ZB7557JKENAX62LUAPLMGIWNZJAFV2MITK6T32V37KEJU. Stellar addresses provide an easy way for users to share payment details by using a syntax that interoperates across different domains and providers.

Stellar addresses are divided into two parts separated by *, the username and the domain.

For example: bob*stellar.org:

bob is the username, stellar.org is the domain. The domain can be any valid RFC 1035 domain name. The username is limited to printable UTF-8 with whitespace and the following characters excluded: * ,> 

Although of course the domain administrator can place additional restrictions on usernames of its domain.

Note that the @ symbol is allowed in the username. This allows for using email addresses in the username of an address. For example: maria@gmail.com*stellar.org.


Read here about federation [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md) 

The SDK provides tools that help you to resolve stellar addresses, account ids and transactions.

**Resolving a stellar address**


```swift
Federation.resolve(stellarAddress: "stellar*lumenshine.com") { (response) -> (Void) in
    switch response {
    case .success(let federationResponse):
        if let accountId = federationResponse.accountId {
            print(accountId)
        } else {
            print("account id not found")
        }
    case .failure(error: let error):
        switch error {
        case FederationError.invalidAddress:
            print("invalid address")
        case ...
        }
    }        
}
```

**Resolving an account Id**

```swift
Federation.forDomain(domain: "lumenshine.com") { (response) -> (Void) in
    switch response {
        case .success(let federation):
            federation.resolve(account_id: "GCM3C6QEQDEZLVDXJSCPOEWWU5LRBVOKQP4PIZLRAW444HKS67M2FFFR") { (response) -> (Void) in
                switch response {
                case .success(let federationResponse):
                    if let stellarAddress = federationResponse.stellarAddress {
                        print(stellarAddress)
                    } else {
                        print("stellar address not found")
                    }
                    case .failure(error: let error):
                    switch error {
                        case FederationError.invalidAddress:
                            print("invalid address")
                            case ...
                    }
                        
                }
            }
        case .failure(error: let error):
            switch error {
                case FederationError.invalidToml:
                print("invalid toml")
                case ...
            }
        }
    }
}
```
