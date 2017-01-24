//
//  TwitterWebService.swift
//  JBTwitterStreaming
//
//  Created by Jeff Breunig on 1/23/17.
//  Copyright © 2017 Jeff Breunig. All rights reserved.
//

import Foundation
import Swifter

protocol TwitterWebServiceDelegate {
    func didLoadTweets(metrics: DisplayMetrics?)
    func failedToLoadTweets(errorMessage: String?)
}

class TwitterWebService {
    var delegate: TwitterWebServiceDelegate?
    var metrics = Metrics()
    private var startDate: Date?
    private var timer: Timer?
    init(delegate: TwitterWebServiceDelegate?) {
        self.delegate = delegate
    }
    
    func getTweets() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { (timer: Timer) in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).sync {
                var numberOfSeconds: UInt = 0
                if let startDate = self.startDate {
                    numberOfSeconds = UInt(Date().timeIntervalSince(startDate))
                }
                let displayMetrics = self.metrics.getDisplayMetrics(numberOfSeconds: numberOfSeconds)
                DispatchQueue.main.async {
                    self.delegate?.didLoadTweets(metrics: displayMetrics)
                }
            }
            
        }
        startDate = Date()
        let consumerKey = "aVThC4Adafl2fMQdnMVTdPGnS"
        let consumerSecret = "tpsDI7XfHryBRSwYEFugHWhKwfEKtixPy8bwVvvwpBDE6vtchc"
        let accessToken = "242103298-ewSaidq24kC7Muu5jshDNu57Rsmts4jk3qjF4GuY"
        let accessTokenSecret = "9xtE7ChuJhQMTBZgoRSjPHVMbRXJgbvD3iSKFgvkBmcRQ"
        let swifter: Swifter = Swifter(consumerKey: consumerKey,
                                       consumerSecret: consumerSecret,
                                       oauthToken: accessToken,
                                       oauthTokenSecret: accessTokenSecret)
        swifter.streamRandomSampleTweets(delimited: true, stallWarnings: true, progress: { (json: JSON) in
            if let tweet = Tweet.tweetWithJson(json) {
                DispatchQueue.global().async {
                    self.metrics.update(tweet: tweet)
                }
            }
            }, stallWarningHandler: { (a: String?, b: String?, c: Int?) in
                print("")
        }) { (error: Error) in
            self.delegate?.failedToLoadTweets(errorMessage: error.localizedDescription)
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}

