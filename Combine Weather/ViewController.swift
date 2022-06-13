//
//  ViewController.swift
//  Combine Weather
//
//  Created by Артур Дохно on 11.06.2022.
//

import UIKit
import Combine

enum WeatherError: Error {
    case invalidResponse
}

class ViewController: UIViewController {
    
    private let celsiusCharacters = "°C"
    private let openWeatherBaseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let openWeatherAPIKey = "6aae2b16f107d043e3de85ca9c6964ed"
    
    @IBOutlet var cityTextField: UITextField!
    @IBOutlet var temperatureLabel: UILabel!
    @IBOutlet var searchButton: UIButton!
    
    private var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func searchTaped(_ sender: Any) {
        guard let cityName = cityTextField.text else { return }
        
        getTemperature(for: cityName)
    }
    
    func getTemperature(for cityName: String) {
        guard let weatherURL = URL(
            string: "\(openWeatherBaseURL)?appid=\(openWeatherAPIKey)&q=\(cityName)&units=metric")
        else {
            return
        }
        
        searchButton.isEnabled = false
        
        cancellable = URLSession.shared.dataTaskPublisher(for: weatherURL)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200
                else {
                    throw WeatherError.invalidResponse
                }
                return data
            }
            .decode(type: Temperature.self, decoder: JSONDecoder())
            .catch { error in
                return Just(Temperature.placeholder)
            }
            .map { $0.main?.temp ?? 0.0 }
            .map { "\($0) \(self.celsiusCharacters)" }
            .subscribe(on: DispatchQueue(label: "Combine.Weather"))
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                    self.searchButton.isEnabled = true
            }, receiveValue: { temp in
                self.temperatureLabel.text = temp
            })
        
    }
    
}

