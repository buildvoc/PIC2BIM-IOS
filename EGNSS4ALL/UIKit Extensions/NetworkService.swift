import Foundation


class NetworkService
{
    lazy var config: URLSessionConfiguration = URLSessionConfiguration.default
    lazy var session: URLSession = URLSession(configuration: self.config)

    let url: URL

    init(url: URL) {
        self.url = url
    }

    typealias ImageDataHandler = ((Data) -> Void)

    func downloadImage(_ completion: @escaping ImageDataHandler)
    {
        let request = URLRequest(url: self.url)
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in

            if error == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    switch (httpResponse.statusCode) {
                    case 200:
                        if let data = data {
                            completion(data)
                        }
                    default:
                        print(httpResponse.statusCode)
                    }
                }
            } else {
                if let errorDescription = error?.localizedDescription {
                    print("Error: \(errorDescription)")
                } else {
                    print("Error: Unknown error occurred")
                }
              //  print("Error: \(error?.localizedDescription)")
            }
        })
        dataTask.resume()
    }
}

extension NetworkService
{
    static func parseJSONFromData(_ jsonData: Data?) -> [String : AnyObject]?
    {
        if let data = jsonData {
            do {
                let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : AnyObject]
                return jsonDictionary
            } catch let error as NSError {
                print("Error processing json data: \(error.localizedDescription)")
            }
        }

        return nil
    }
}

