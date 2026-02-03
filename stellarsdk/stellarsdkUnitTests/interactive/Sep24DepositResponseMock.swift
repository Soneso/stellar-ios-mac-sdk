import Foundation

class Sep24DepositResponseMock: ResponsesMock {
    var address: String
    
    init(address:String) {
        self.address = address
        
        super.init()
    }
    
    override func requestMock() -> RequestMock {
        let handler: MockHandler = { [weak self] mock, request in
            if let data = request.httpBodyStream?.readfully() {
                let body = String(decoding: data, as: UTF8.self)
                print(body)
            }
            return self?.depositSuccess
        }
        
        return RequestMock(host: address,
                           path: "/transactions/deposit/interactive",
                           httpMethod: "POST",
                           mockHandler: handler)
    }
    
    let depositSuccess = """
    {  
        "type": "completed",
        "url": "https://api.example.com/kycflow?account=GACW7NONV43MZIFHCOKCQJAKSJSISSICFVUJ2C6EZIW5773OU3HD64VI",
        "id": "82fhs729f63dh0v4"
    }
    """
    
}
