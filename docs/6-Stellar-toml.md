# 6. Stellar.toml file


The stellar.toml file is used to provide a common place where the Internet can find information about a domain’s Stellar integration. Any website can publish Stellar network information. They can announce their validation key, their federation server, peers they are running, their quorum set, if they are an anchor, etc.

The stellar.toml file is a text file in the [TOML format](https://github.com/toml-lang/toml).

Given the domain “DOMAIN”, the stellar.toml will be searched for at the following location:

https://DOMAIN/.well-known/stellar.toml

Read here about stellar toml files [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) 

The SDK provides tools to load stellar toml files and read data from them.

**Getting a StellarToml object and read data**

From domain:

```swift
try? StellarToml.from(domain: "lumenshine.com") { (result) -> (Void) in
    switch result {
    case .success(response: let stellarToml):
    
        // ex. read federation server url
        if let federationServer = stellarToml.accountInformation.federationServer {
            print(federationServer)
        } else {
            print("Toml contains no federation server url")
        }
        
        // read other data
        // stellarToml.accountInformation...
        // stellarToml.issuerDocumentation ...
        // stellarToml.pointsOfContact...
        // stellarToml.currenciesDocumentation...
        // stellarToml.validatorInformation...

    case .failure(let error):
        switch error {
        case .invalidDomain:
            // do something
        case .invalidToml:
            // do something
        }
    }
}
```

From string:

```swift
let stellarToml = try? StellarToml(fromString: tomlSample)

if let federationServer = stellarToml.accountInformation.federationServer {
    print(federationServer)
} else {
    print("Toml contains no federation server url")
}

// read other data
// stellarToml.accountInformation...
// stellarToml.issuerDocumentation ...
// stellarToml.pointsOfContact...
// stellarToml.currenciesDocumentation...
// stellarToml.validatorInformation...
```
